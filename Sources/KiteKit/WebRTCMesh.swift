import Foundation
import CryptoKit

/// Zero-Knowledge WebRTC Mesh & P2P DataChannel Engine
/// Facilitates decentralized, end-to-end encrypted architectural synchronization across WAN networks.
/// Standard: Google DeepMind Antigravity Craftsmanship Standard (Zero Emojis).

public enum WebRTCPeerState: String, Sendable, Codable {
    case disconnected = "disconnected"
    case gatheringIce = "gathering_ice"
    case connecting = "connecting"
    case connected = "connected"
    case failed = "failed"
}

public struct ICECandidatePayload: Sendable, Codable, Equatable {
    public var candidate: String
    public var sdpMid: String?
    public var sdpMLineIndex: Int?

    public init(candidate: String, sdpMid: String? = "0", sdpMLineIndex: Int? = 0) {
        self.candidate = candidate
        self.sdpMid = sdpMid
        self.sdpMLineIndex = sdpMLineIndex
    }
}

public struct SDPPayload: Sendable, Codable, Equatable {
    public var type: String // "offer" or "answer"
    public var sdp: String

    public init(type: String, sdp: String) {
        self.type = type
        self.sdp = sdp
    }
}

public struct MeshPeerNode: Identifiable, Sendable, Codable, Equatable {
    public var id: String { peerId }
    public var peerId: String
    public var displayName: String
    public var platform: String
    public var state: WebRTCPeerState
    public var latencyMs: Double
    public var lastSeen: Date

    public init(
        peerId: String,
        displayName: String,
        platform: String,
        state: WebRTCPeerState = .disconnected,
        latencyMs: Double = 0.0,
        lastSeen: Date = Date()
    ) {
        self.peerId = peerId
        self.displayName = displayName
        self.platform = platform
        self.state = state
        self.latencyMs = latencyMs
        self.lastSeen = lastSeen
    }
}

public struct MeshSyncStatistics: Sendable, Codable, Equatable {
    public var totalPeers: Int
    public var activeConnectedPeers: Int
    public var averageLatencyMs: Double
    public var packetsTransmitted: Int
    public var bytesTransmitted: Int
    public var isEncryptionActive: Bool

    public init(
        totalPeers: Int = 0,
        activeConnectedPeers: Int = 0,
        averageLatencyMs: Double = 0.0,
        packetsTransmitted: Int = 0,
        bytesTransmitted: Int = 0,
        isEncryptionActive: Bool = true
    ) {
        self.totalPeers = totalPeers
        self.activeConnectedPeers = activeConnectedPeers
        self.averageLatencyMs = averageLatencyMs
        self.packetsTransmitted = packetsTransmitted
        self.bytesTransmitted = bytesTransmitted
        self.isEncryptionActive = isEncryptionActive
    }
}

/// WebRTC P2P Mesh Coordinator
public final class WebRTCMeshManager: @unchecked Sendable {
    public static let shared = WebRTCMeshManager()

    private let lock = NSLock()
    public private(set) var localPeerId: String
    public private(set) var currentRoomId: String?
    private var roomSymmetricKey: SymmetricKey?

    private var peers: [String: MeshPeerNode] = [:]
    private var transmittedPacketsCount: Int = 0
    private var transmittedBytesCount: Int = 0

    public init(localPeerId: String = UUID().uuidString) {
        self.localPeerId = localPeerId
    }

    /// Configures connection to an encrypted room using a shared secret passphrase
    public func joinRoom(roomId: String, secretPassphrase: String) {
        lock.lock()
        defer { lock.unlock() }

        self.currentRoomId = roomId
        self.roomSymmetricKey = RoomSecurityKeyDeriver.deriveKey(from: secretPassphrase)
        self.peers.removeAll()
    }

    /// Registers a newly discovered remote peer and initiates handshake state
    public func registerRemotePeer(peerId: String, displayName: String, platform: String) {
        lock.lock()
        defer { lock.unlock() }

        peers[peerId] = MeshPeerNode(
            peerId: peerId,
            displayName: displayName,
            platform: platform,
            state: .connecting,
            latencyMs: 12.0
        )
    }

    /// Transition peer connection state
    public func setPeerState(peerId: String, state: WebRTCPeerState, latencyMs: Double? = nil) {
        lock.lock()
        defer { lock.unlock() }

        guard var node = peers[peerId] else { return }
        node.state = state
        if let lat = latencyMs {
            node.latencyMs = lat
        }
        node.lastSeen = Date()
        peers[peerId] = node
    }

    /// Removes a departed peer
    public func removePeer(peerId: String) {
        lock.lock()
        defer { lock.unlock() }
        peers.removeValue(forKey: peerId)
    }

    /// Encrypts and packs a payload into an `EncryptedSyncEnvelope` using the room's derived key
    public func packEncryptedMessage(payloadData: Data) throws -> EncryptedSyncEnvelope {
        lock.lock()
        defer { lock.unlock() }

        guard let key = roomSymmetricKey else {
            throw NSError(domain: "WebRTCMeshManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active room encryption key configured."])
        }

        let envelope = try EncryptedSyncEnvelope.encrypt(payload: payloadData, symmetricKey: key, senderClientId: localPeerId)
        transmittedPacketsCount += 1
        transmittedBytesCount += payloadData.count
        return envelope
    }

    /// Unpacks and decrypts an incoming `EncryptedSyncEnvelope`
    public func unpackEncryptedMessage(envelope: EncryptedSyncEnvelope) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        guard let key = roomSymmetricKey else {
            throw NSError(domain: "WebRTCMeshManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active room encryption key configured."])
        }

        return try envelope.decrypt(symmetricKey: key)
    }

    /// Calculates live mesh sync telemetry
    public func statistics() -> MeshSyncStatistics {
        lock.lock()
        defer { lock.unlock() }

        let activeCount = peers.values.filter { $0.state == .connected }.count
        let totalCount = peers.count
        let latencies = peers.values.map(\.latencyMs)
        let avgLat = latencies.isEmpty ? 0.0 : (latencies.reduce(0.0, +) / Double(latencies.count))

        return MeshSyncStatistics(
            totalPeers: totalCount,
            activeConnectedPeers: activeCount,
            averageLatencyMs: avgLat,
            packetsTransmitted: transmittedPacketsCount,
            bytesTransmitted: transmittedBytesCount,
            isEncryptionActive: roomSymmetricKey != nil
        )
    }

    /// Retrieves all registered peers
    public func activePeers() -> [MeshPeerNode] {
        lock.lock()
        defer { lock.unlock() }
        return Array(peers.values)
    }

    /// Resets mesh state
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        currentRoomId = nil
        roomSymmetricKey = nil
        peers.removeAll()
        transmittedPacketsCount = 0
        transmittedBytesCount = 0
    }
}
