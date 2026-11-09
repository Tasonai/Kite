import Foundation
import CryptoKit

/// Zero-Retention Cloud Signaling Relay Models & Hub
/// Facilitates peer discovery and WebRTC handshake without retaining plain-text architecture payloads.
/// Conforms to Google DeepMind Antigravity Craftsmanship Standard (Zero Emojis).

public enum SignalingMessageType: String, Sendable, Codable {
    case join = "join"
    case joined = "joined"
    case peerJoined = "peer_joined"
    case peerLeft = "peer_left"
    case offer = "offer"
    case answer = "answer"
    case iceCandidate = "ice_candidate"
    case encryptedEnvelope = "encrypted_envelope"
    case ping = "ping"
    case pong = "pong"
}

public struct SignalingPeer: Identifiable, Sendable, Codable, Equatable {
    public var id: String
    public var displayName: String
    public var platform: String
    public var joinedAt: Date

    public init(id: String = UUID().uuidString, displayName: String, platform: String, joinedAt: Date = Date()) {
        self.id = id
        self.displayName = displayName
        self.platform = platform
        self.joinedAt = joinedAt
    }
}

public struct SignalingMessage: Sendable, Codable, Equatable {
    public var type: SignalingMessageType
    public var roomId: String
    public var senderPeerId: String
    public var targetPeerId: String?
    public var payload: String
    public var timestamp: Date

    public init(
        type: SignalingMessageType,
        roomId: String,
        senderPeerId: String,
        targetPeerId: String? = nil,
        payload: String = "",
        timestamp: Date = Date()
    ) {
        self.type = type
        self.roomId = roomId
        self.senderPeerId = senderPeerId
        self.targetPeerId = targetPeerId
        self.payload = payload
        self.timestamp = timestamp
    }
}

public struct RelayRoomSession: Sendable, Codable, Equatable {
    public var roomId: String
    public var createdAt: Date
    public var peerCount: Int
    public var isEncrypted: Bool

    public init(roomId: String, createdAt: Date = Date(), peerCount: Int = 1, isEncrypted: Bool = true) {
        self.roomId = roomId
        self.createdAt = createdAt
        self.peerCount = peerCount
        self.isEncrypted = isEncrypted
    }
}

/// Cryptographic Key Derivation for Zero-Knowledge Collaborative Rooms
public enum RoomSecurityKeyDeriver {
    /// Derives a 256-bit symmetric encryption key from a shared room secret token using SHA-256
    public static func deriveKey(from secret: String) -> SymmetricKey {
        let inputData = Data(secret.utf8)
        let digest = SHA256.hash(data: inputData)
        return SymmetricKey(data: digest)
    }

    /// Generates a high-entropy cryptographically secure room pass-token (e.g. "kite-alpha-9f4a2b")
    public static func generateRoomToken(prefix: String = "kite") -> String {
        var randomBytes = [UInt8](repeating: 0, count: 6)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let hex = randomBytes.map { String(format: "%02x", $0) }.joined()
        return "\(prefix)-\(hex)"
    }
}

/// In-Memory Thread-Safe Signaling Relay Hub for Local & Clustered Rendezvous
public final class RelayStationHub: @unchecked Sendable {
    public static let shared = RelayStationHub()

    private let lock = NSLock()
    private var rooms: [String: [String: SignalingPeer]] = [:]
    private var messageQueues: [String: [SignalingMessage]] = [:]

    public init() {}

    public func joinRoom(roomId: String, peer: SignalingPeer) -> [SignalingPeer] {
        lock.lock()
        defer { lock.unlock() }

        var roomPeers = rooms[roomId] ?? [:]
        let existingPeers = Array(roomPeers.values)
        roomPeers[peer.id] = peer
        rooms[roomId] = roomPeers

        if messageQueues[peer.id] == nil {
            messageQueues[peer.id] = []
        }

        return existingPeers
    }

    public func leaveRoom(roomId: String, peerId: String) {
        lock.lock()
        defer { lock.unlock() }

        rooms[roomId]?.removeValue(forKey: peerId)
        if rooms[roomId]?.isEmpty == true {
            rooms.removeValue(forKey: roomId)
        }
        messageQueues.removeValue(forKey: peerId)
    }

    public func routeMessage(_ message: SignalingMessage) {
        lock.lock()
        defer { lock.unlock() }

        if let target = message.targetPeerId {
            messageQueues[target]?.append(message)
        } else if let roomPeers = rooms[message.roomId] {
            // Broadcast to all other peers in room
            for peerId in roomPeers.keys where peerId != message.senderPeerId {
                messageQueues[peerId]?.append(message)
            }
        }
    }

    public func popMessages(for peerId: String) -> [SignalingMessage] {
        lock.lock()
        defer { lock.unlock() }

        let msgs = messageQueues[peerId] ?? []
        messageQueues[peerId] = []
        return msgs
    }

    public func activePeers(in roomId: String) -> [SignalingPeer] {
        lock.lock()
        defer { lock.unlock() }
        return Array((rooms[roomId] ?? [:]).values)
    }

    public func activeRooms() -> [RelayRoomSession] {
        lock.lock()
        defer { lock.unlock() }
        return rooms.map { (roomId, peers) in
            RelayRoomSession(roomId: roomId, peerCount: peers.count, isEncrypted: true)
        }
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        rooms.removeAll()
        messageQueues.removeAll()
    }
}
