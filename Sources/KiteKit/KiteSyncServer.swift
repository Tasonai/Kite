import Foundation
import Network

public final class KiteSyncServer: @unchecked Sendable {
    public static let shared = KiteSyncServer()

    public private(set) var isRunning: Bool = false
    public private(set) var boundPort: UInt16 = 24242

    public var exportIdeasProvider: (@Sendable () async -> Data?)?
    public var importIdeasHandler: (@Sendable (Data) async -> Int)?
    public var exportCanvasProvider: (@Sendable () async -> Data?)?
    public var importCanvasHandler: (@Sendable (Data) async -> Bool)?

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.kite.syncserver", qos: .userInitiated)
    private var sseConnections: [NWConnection] = []
    private let sseLock = NSLock()

    private init() {}

    public func start(port: UInt16 = 24242) {
        guard !isRunning else { return }
        self.boundPort = port

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        do {
            guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
            let listener = try NWListener(using: params, on: nwPort)
            self.listener = listener

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    KiteLANBeacon.shared.start(appPort: Int(port))
                    KiteLog.sync.info("KiteSyncServer listening on port \(port)")
                case .failed(let err):
                    KiteLog.sync.error("KiteSyncServer failed: \(err.localizedDescription)")
                    self?.stop()
                case .cancelled:
                    self?.isRunning = false
                    KiteLANBeacon.shared.stop()
                    KiteLog.sync.info("KiteSyncServer stopped")
                default:
                    break
                }
            }

            listener.start(queue: queue)
        } catch {
            KiteLog.sync.error("KiteSyncServer failed to bind port \(port): \(error.localizedDescription)")
        }
    }

    public func stop() {
        sseLock.lock()
        for conn in sseConnections {
            conn.cancel()
        }
        sseConnections.removeAll()
        sseLock.unlock()

        listener?.cancel()
        listener = nil
        isRunning = false
        KiteLANBeacon.shared.stop()
    }

    public func broadcast(event: String, payload: [String: Any] = [:]) {
        let jsonPayload: String
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let str = String(data: data, encoding: .utf8) {
            jsonPayload = str
        } else {
            jsonPayload = "{}"
        }
        let sseString = "event: message\ndata: {\"type\":\"\(event)\",\"payload\":\(jsonPayload)}\n\n"
        let data = Data(sseString.utf8)

        sseLock.lock()
        let connections = sseConnections
        sseLock.unlock()

        for conn in connections {
            conn.send(content: data, completion: .contentProcessed { [weak self] error in
                if error != nil {
                    self?.removeSseConnection(conn)
                }
            })
        }
    }

    private func addSseConnection(_ connection: NWConnection) {
        sseLock.lock()
        sseConnections.append(connection)
        sseLock.unlock()

        let header = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream; charset=utf-8\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
        connection.send(content: Data(header.utf8), completion: .contentProcessed { _ in })

        let welcome = "data: {\"type\":\"connected\",\"app\":\"Kite macOS\",\"port\":\(boundPort)}\n\n"
        connection.send(content: Data(welcome.utf8), completion: .contentProcessed { _ in })
    }

    private func removeSseConnection(_ connection: NWConnection) {
        sseLock.lock()
        sseConnections.removeAll(where: { $0 === connection })
        sseLock.unlock()
        connection.cancel()
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(connection)
    }

    private func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] data, _, _, _ in
            guard let self = self, let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            Task {
                await self.processHTTP(data: data, connection: connection)
            }
        }
    }

    private func processHTTP(data: Data, connection: NWConnection) async {
        guard let rawString = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, status: "400 Bad Request")
            return
        }

        // Split headers and body
        let parts = rawString.components(separatedBy: "\r\n\r\n")
        let headerPart = parts[0]
        let lines = headerPart.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(connection: connection, status: "400 Bad Request")
            return
        }

        let tokens = requestLine.components(separatedBy: " ")
        guard tokens.count >= 2 else {
            sendResponse(connection: connection, status: "400 Bad Request")
            return
        }

        let method = tokens[0].uppercased()
        let path = tokens[1]
        KiteLog.sync.debug("Incoming \(method) \(path)")

        // CORS Preflight
        if method == "OPTIONS" {
            sendResponse(connection: connection, status: "204 No Content")
            return
        }

        // Body extraction
        var bodyData = Data()
        if parts.count > 1 {
            let bodyString = parts[1...].joined(separator: "\r\n\r\n")
            bodyData = Data(bodyString.utf8)
        }

        switch (method, path) {
        case ("GET", "/"), ("GET", "/index.html"):
            let html = WebStudio.html(port: Int(boundPort), appName: "Kite macOS")
            sendResponse(connection: connection, contentType: "text/html; charset=utf-8", body: Data(html.utf8))

        case ("GET", "/api/events"):
            addSseConnection(connection)
            return

        case ("GET", "/api/status"):
            let json = """
            {"status":"online","app":"Kite macOS","version":"1.3.0","port":\(boundPort)}
            """
            sendResponse(connection: connection, body: Data(json.utf8))

        case ("GET", "/api/peers"):
            let peers = KiteLANBeacon.shared.activePeers
            if let data = try? JSONEncoder().encode(peers) {
                sendResponse(connection: connection, contentType: "application/json", body: data)
            } else {
                sendResponse(connection: connection, contentType: "application/json", body: Data("[]".utf8))
            }

        case ("GET", "/api/ideas"):
            let responseData = await exportIdeasProvider?() ?? Data("{\"ideas\":[]}".utf8)
            sendResponse(connection: connection, body: responseData)

        case ("POST", "/api/ideas"):
            let count = await importIdeasHandler?(bodyData) ?? 0
            broadcast(event: "ideas_updated", payload: ["imported": count])
            let res = "{\"status\":\"ok\",\"imported\":\(count)}"
            sendResponse(connection: connection, body: Data(res.utf8))

        case ("GET", "/api/canvas"):
            let responseData = await exportCanvasProvider?() ?? Data("{}".utf8)
            sendResponse(connection: connection, body: responseData)

        case ("POST", "/api/canvas"):
            let ok = await importCanvasHandler?(bodyData) ?? false
            if ok {
                broadcast(event: "canvas_updated", payload: ["status": "ok"])
            }
            let res = "{\"status\":\(ok ? "\"ok\"" : "\"error\"")}"
            sendResponse(connection: connection, body: Data(res.utf8))

        default:
            sendResponse(connection: connection, status: "404 Not Found")
        }
    }

    private func sendResponse(
        connection: NWConnection,
        status: String = "200 OK",
        contentType: String = "application/json; charset=utf-8",
        body: Data = Data()
    ) {
        let headers = [
            "HTTP/1.1 \(status)",
            "Content-Type: \(contentType)",
            "Content-Length: \(body.count)",
            "Access-Control-Allow-Origin: *",
            "Access-Control-Allow-Methods: GET, POST, OPTIONS",
            "Access-Control-Allow-Headers: Content-Type, Accept",
            "Connection: close",
            "",
            ""
        ].joined(separator: "\r\n")

        var payload = Data(headers.utf8)
        payload.append(body)

        connection.send(content: payload, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
