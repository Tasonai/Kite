import Foundation
import Network
import CoreImage
import AppKit

@MainActor
public final class InstantPreviewServer: ObservableObject {
    public static let shared = InstantPreviewServer()

    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var localPort: UInt16 = 49495
    @Published public private(set) var localURLString: String = ""
    @Published public private(set) var qrCodeImage: NSImage? = nil

    private var listener: NWListener?

    private init() {}

    public func start(html: String, preferredPort: UInt16 = 49495) {
        stop()
        self.localPort = preferredPort
        let bodyData = html.data(using: .utf8) ?? Data()

        do {
            let params = NWParameters.tcp
            guard let port = NWEndpoint.Port(rawValue: preferredPort) else { return }
            let newListener = try NWListener(using: params, on: port)

            newListener.newConnectionHandler = { connection in
                Self.serveConnection(connection, bodyData: bodyData)
            }

            newListener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    switch state {
                    case .ready:
                        self.isRunning = true
                        let ip = Self.getLocalIPAddress() ?? "127.0.0.1"
                        self.localURLString = "http://\(ip):\(preferredPort)/"
                        self.qrCodeImage = Self.generateQRCode(from: self.localURLString)
                    case .failed, .cancelled:
                        self.isRunning = false
                    default:
                        break
                    }
                }
            }

            newListener.start(queue: .global(qos: .userInitiated))
            self.listener = newListener
        } catch {
            self.isRunning = false
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        localURLString = ""
        qrCodeImage = nil
    }

    nonisolated private static func serveConnection(_ connection: NWConnection, bodyData: Data) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { _, _, _, _ in
            let headers = """
            HTTP/1.1 200 OK\r
            Content-Type: text/html; charset=utf-8\r
            Content-Length: \(bodyData.count)\r
            Connection: close\r
            \r\n
            """
            var responseData = headers.data(using: .utf8) ?? Data()
            responseData.append(bodyData)

            connection.send(content: responseData, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }

    nonisolated private static func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    if let nullIndex = hostname.firstIndex(of: 0) {
                        let bytes = hostname[..<nullIndex].map { UInt8(bitPattern: $0) }
                        address = String(decoding: bytes, as: UTF8.self)
                    }
                    break
                }
            }
        }
        return address
    }

    nonisolated private static func generateQRCode(from string: String) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = string.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let output = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 8, y: 8)
        let scaledImage = output.transformed(by: transform)

        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}
