import Foundation
import Darwin

public struct KitePeer: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: String
    public let app: String
    public let platform: String
    public let hostname: String
    public let ip: String
    public let port: Int
    public var lastSeen: Date

    public init(
        id: String,
        app: String,
        platform: String,
        hostname: String,
        ip: String,
        port: Int,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.app = app
        self.platform = platform
        self.hostname = hostname
        self.ip = ip
        self.port = port
        self.lastSeen = lastSeen
    }

    enum CodingKeys: String, CodingKey {
        case id, app, platform, hostname, ip, port, lastSeen
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.app = try container.decode(String.self, forKey: .app)
        self.platform = try container.decode(String.self, forKey: .platform)
        self.hostname = try container.decode(String.self, forKey: .hostname)
        self.ip = try container.decode(String.self, forKey: .ip)
        self.port = try container.decode(Int.self, forKey: .port)
        if let timestamp = try? container.decode(Double.self, forKey: .lastSeen) {
            self.lastSeen = Date(timeIntervalSince1970: timestamp)
        } else {
            self.lastSeen = Date()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(app, forKey: .app)
        try container.encode(platform, forKey: .platform)
        try container.encode(hostname, forKey: .hostname)
        try container.encode(ip, forKey: .ip)
        try container.encode(port, forKey: .port)
        try container.encode(lastSeen.timeIntervalSince1970, forKey: .lastSeen)
    }
}

public final class KiteLANBeacon: @unchecked Sendable {
    public static let shared = KiteLANBeacon()
    public static let beaconPort: UInt16 = 49494

    public private(set) var instanceId: String = UUID().uuidString
    public private(set) var activePeers: [KitePeer] = []
    public var onPeersChanged: (@Sendable ([KitePeer]) -> Void)?

    private var broadcastTimer: DispatchSourceTimer?
    private var listenSocket: Int32 = -1
    private var isRunning: Bool = false
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.kite.lanbeacon", qos: .utility)

    private init() {}

    public func start(appPort: Int, appName: String = "Kite macOS", platform: String = "macOS") {
        lock.lock()
        guard !isRunning else {
            lock.unlock()
            return
        }
        isRunning = true
        lock.unlock()

        setupListener()
        startBroadcaster(appPort: appPort, appName: appName, platform: platform)
    }

    public func stop() {
        lock.lock()
        isRunning = false
        broadcastTimer?.cancel()
        broadcastTimer = nil

        if listenSocket >= 0 {
            close(listenSocket)
            listenSocket = -1
        }
        activePeers.removeAll()
        lock.unlock()
    }

    private func setupListener() {
        queue.async { [weak self] in
            guard let self = self else { return }

            let sock = socket(AF_INET, SOCK_DGRAM, 0)
            guard sock >= 0 else {
                KiteLog.sync.error("KiteLANBeacon failed to create socket")
                return
            }

            var reuse: Int32 = 1
            setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
            setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, &reuse, socklen_t(MemoryLayout<Int32>.size))

            var addr = sockaddr_in()
            addr.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = Self.beaconPort.bigEndian
            addr.sin_addr.s_addr = INADDR_ANY.bigEndian

            let bindRes = withUnsafePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    bind(sock, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }

            guard bindRes >= 0 else {
                KiteLog.sync.error("KiteLANBeacon bind failed on port \(Self.beaconPort)")
                close(sock)
                return
            }

            self.lock.lock()
            self.listenSocket = sock
            self.lock.unlock()

            var buffer = [UInt8](repeating: 0, count: 2048)
            while true {
                self.lock.lock()
                let currentSock = self.listenSocket
                let running = self.isRunning
                self.lock.unlock()

                guard running && currentSock >= 0 else { break }

                var senderAddr = sockaddr_in()
                var senderLen = socklen_t(MemoryLayout<sockaddr_in>.size)

                let bytesRead = withUnsafeMutablePointer(to: &senderAddr) { sinPtr in
                    sinPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                        recvfrom(currentSock, &buffer, buffer.count, 0, sa, &senderLen)
                    }
                }

                guard bytesRead > 0 else { continue }

                let data = Data(buffer[0..<bytesRead])
                var ipStr = "127.0.0.1"
                var ipBuf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                if inet_ntop(AF_INET, &senderAddr.sin_addr, &ipBuf, socklen_t(INET_ADDRSTRLEN)) != nil {
                    if let nullIdx = ipBuf.firstIndex(of: 0) {
                        ipStr = String(decoding: ipBuf[0..<nullIdx].map { UInt8(bitPattern: $0) }, as: UTF8.self)
                    }
                }

                self.processIncomingBeacon(data: data, senderIp: ipStr)
            }
        }
    }

    private func processIncomingBeacon(data: Data, senderIp: String) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let isKite = json["kite_beacon"] as? Bool, isKite,
              let peerId = json["id"] as? String,
              let app = json["app"] as? String,
              let platform = json["platform"] as? String,
              let hostname = json["hostname"] as? String,
              let port = json["port"] as? Int else {
            return
        }

        // Ignore self beacon
        guard peerId != instanceId else { return }

        lock.lock()
        let now = Date()
        let resolvedIp = (senderIp == "0.0.0.0" || senderIp == "127.0.0.1") ? "127.0.0.1" : senderIp
        let peer = KitePeer(
            id: peerId,
            app: app,
            platform: platform,
            hostname: hostname,
            ip: resolvedIp,
            port: port,
            lastSeen: now
        )

        if let idx = activePeers.firstIndex(where: { $0.id == peerId }) {
            activePeers[idx] = peer
        } else {
            activePeers.append(peer)
        }

        // Prune peers inactive for 9 seconds
        let cutoff = now.addingTimeInterval(-9.0)
        activePeers.removeAll(where: { $0.lastSeen < cutoff })
        let currentPeers = activePeers
        lock.unlock()

        onPeersChanged?(currentPeers)
    }

    private func startBroadcaster(appPort: Int, appName: String, platform: String) {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(3))

        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.sendBroadcast(appPort: appPort, appName: appName, platform: platform)
            self.pruneStalePeers()
        }

        self.broadcastTimer = timer
        timer.resume()
    }

    private func sendBroadcast(appPort: Int, appName: String, platform: String) {
        let hostname = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        let payload: [String: Any] = [
            "kite_beacon": true,
            "id": instanceId,
            "app": appName,
            "platform": platform,
            "hostname": hostname,
            "port": appPort,
            "timestamp": Date().timeIntervalSince1970
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }

        let sock = socket(AF_INET, SOCK_DGRAM, 0)
        guard sock >= 0 else { return }
        defer { close(sock) }

        var broadcastEnable: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = Self.beaconPort.bigEndian
        inet_pton(AF_INET, "255.255.255.255", &addr.sin_addr)

        _ = data.withUnsafeBytes { ptr in
            withUnsafePointer(to: &addr) { sinPtr in
                sinPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    sendto(sock, ptr.baseAddress, data.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
    }

    private func pruneStalePeers() {
        lock.lock()
        let cutoff = Date().addingTimeInterval(-9.0)
        let beforeCount = activePeers.count
        activePeers.removeAll(where: { $0.lastSeen < cutoff })
        let changed = (activePeers.count != beforeCount)
        let current = activePeers
        lock.unlock()

        if changed {
            onPeersChanged?(current)
        }
    }
}
