import Foundation
import CryptoKit

/// Hybrid Logical Clock (HLC) providing strict causal ordering across distributed nodes.
/// Combines physical time with a monotonic logical counter and unique client identifier.
public struct HybridLogicalClock: Sendable, Equatable, Comparable, Codable {
    public var physicalMillis: UInt64
    public var logicalCounter: UInt32
    public var clientId: String

    public init(physicalMillis: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000), logicalCounter: UInt32 = 0, clientId: String = UUID().uuidString) {
        self.physicalMillis = physicalMillis
        self.logicalCounter = logicalCounter
        self.clientId = clientId
    }

    /// Advance the clock for a local mutation.
    public mutating func tick() {
        let now = UInt64(Date().timeIntervalSince1970 * 1000)
        if now > physicalMillis {
            physicalMillis = now
            logicalCounter = 0
        } else {
            logicalCounter += 1
        }
    }

    /// Merge with a remote clock upon receiving a packet.
    public mutating func update(with remote: HybridLogicalClock) {
        let now = UInt64(Date().timeIntervalSince1970 * 1000)
        let maxPhysical = max(now, max(physicalMillis, remote.physicalMillis))

        if maxPhysical == physicalMillis && maxPhysical == remote.physicalMillis {
            logicalCounter = max(logicalCounter, remote.logicalCounter) + 1
        } else if maxPhysical == physicalMillis {
            logicalCounter += 1
        } else if maxPhysical == remote.physicalMillis {
            logicalCounter = remote.logicalCounter + 1
        } else {
            logicalCounter = 0
        }
        physicalMillis = maxPhysical
    }

    public static func < (lhs: HybridLogicalClock, rhs: HybridLogicalClock) -> Bool {
        if lhs.physicalMillis != rhs.physicalMillis {
            return lhs.physicalMillis < rhs.physicalMillis
        }
        if lhs.logicalCounter != rhs.logicalCounter {
            return lhs.logicalCounter < rhs.logicalCounter
        }
        return lhs.clientId < rhs.clientId
    }
}

/// Last-Write-Wins Register providing deterministic conflict resolution.
public struct LWWRegister<T: Sendable & Codable & Equatable>: Sendable, Codable, Equatable {
    public var value: T
    public var clock: HybridLogicalClock

    public init(value: T, clock: HybridLogicalClock) {
        self.value = value
        self.clock = clock
    }

    /// Merges another register, keeping whichever value has the causally later clock.
    public mutating func merge(with other: LWWRegister<T>) {
        if other.clock > self.clock {
            self.value = other.value
            self.clock = other.clock
        }
    }
}

/// Real-time presence state for active collaborators on the canvas.
public struct CollaboratorPresence: Identifiable, Sendable, Codable, Equatable {
    public var id: String { clientId }
    public var clientId: String
    public var displayName: String
    public var colorHex: String
    public var cursorX: Double
    public var cursorY: Double
    public var selectedNodeIds: [String]
    public var viewportX: Double
    public var viewportY: Double
    public var viewportZoom: Double
    public var clock: HybridLogicalClock

    public init(
        clientId: String,
        displayName: String,
        colorHex: String = "#0A84FF",
        cursorX: Double = 0.0,
        cursorY: Double = 0.0,
        selectedNodeIds: [String] = [],
        viewportX: Double = 0.0,
        viewportY: Double = 0.0,
        viewportZoom: Double = 1.0,
        clock: HybridLogicalClock = HybridLogicalClock()
    ) {
        self.clientId = clientId
        self.displayName = displayName
        self.colorHex = colorHex
        self.cursorX = cursorX
        self.cursorY = cursorY
        self.selectedNodeIds = selectedNodeIds
        self.viewportX = viewportX
        self.viewportY = viewportY
        self.viewportZoom = viewportZoom
        self.clock = clock
    }
}

/// Replicated CRDT document state for Kite Canvas.
/// Mathematically converges across arbitrary network latency and delivery permutations.
public struct CanvasCRDTDocument: Sendable, Codable, Equatable {
    public var documentId: String
    public var frames: [String: LWWRegister<CanvasFrame>]
    public var connections: [String: LWWRegister<CanvasConnection>]
    public var clock: HybridLogicalClock

    public init(documentId: String = UUID().uuidString, clientId: String = UUID().uuidString) {
        self.documentId = documentId
        self.frames = [:]
        self.connections = [:]
        self.clock = HybridLogicalClock(clientId: clientId)
    }

    /// Mutate or add a frame with local clock advancement.
    public mutating func setFrame(_ frame: CanvasFrame) {
        clock.tick()
        let reg = LWWRegister(value: frame, clock: clock)
        frames[frame.id.uuidString] = reg
    }

    /// Mutate or add a connection with local clock advancement.
    public mutating func setConnection(_ connection: CanvasConnection) {
        clock.tick()
        let reg = LWWRegister(value: connection, clock: clock)
        connections[connection.id.uuidString] = reg
    }

    /// Remove a frame.
    public mutating func removeFrame(id: UUID) {
        frames.removeValue(forKey: id.uuidString)
    }

    /// Merge remote CRDT document state with guaranteed convergence.
    public mutating func merge(with remote: CanvasCRDTDocument) {
        clock.update(with: remote.clock)

        for (key, remoteReg) in remote.frames {
            if var localReg = frames[key] {
                localReg.merge(with: remoteReg)
                frames[key] = localReg
            } else {
                frames[key] = remoteReg
            }
        }

        for (key, remoteReg) in remote.connections {
            if var localReg = connections[key] {
                localReg.merge(with: remoteReg)
                connections[key] = localReg
            } else {
                connections[key] = remoteReg
            }
        }
    }
}

/// Zero-Knowledge Encrypted Synchronization Envelope.
/// Uses ChaCha20-Poly1305 symmetric AEAD for tamper-evident transport.
public struct EncryptedSyncEnvelope: Sendable, Codable, Equatable {
    public var senderClientId: String
    public var nonceBase64: String
    public var ciphertextBase64: String
    public var tagBase64: String

    public init(senderClientId: String, nonceBase64: String, ciphertextBase64: String, tagBase64: String) {
        self.senderClientId = senderClientId
        self.nonceBase64 = nonceBase64
        self.ciphertextBase64 = ciphertextBase64
        self.tagBase64 = tagBase64
    }

    /// Encrypts raw payload using a 256-bit symmetric key with ChaCha20-Poly1305.
    public static func encrypt(payload: Data, symmetricKey: SymmetricKey, senderClientId: String) throws -> EncryptedSyncEnvelope {
        let sealedBox = try ChaChaPoly.seal(payload, using: symmetricKey)
        return EncryptedSyncEnvelope(
            senderClientId: senderClientId,
            nonceBase64: Data(sealedBox.nonce).base64EncodedString(),
            ciphertextBase64: sealedBox.ciphertext.base64EncodedString(),
            tagBase64: sealedBox.tag.base64EncodedString()
        )
    }

    /// Decrypts payload using the shared symmetric key.
    public func decrypt(symmetricKey: SymmetricKey) throws -> Data {
        guard let nonceData = Data(base64Encoded: nonceBase64),
              let ciphertextData = Data(base64Encoded: ciphertextBase64),
              let tagData = Data(base64Encoded: tagBase64) else {
            throw NSError(domain: "EncryptedSyncEnvelope", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 encoding"])
        }
        let nonce = try ChaChaPoly.Nonce(data: nonceData)
        let sealedBox = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertextData, tag: tagData)
        return try ChaChaPoly.open(sealedBox, using: symmetricKey)
    }
}
