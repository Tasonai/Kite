//
// MerkleAuditEngine.swift
// KiteKit
//
// Enterprise Identity & Access Management (IAM) and Cryptographic Merkle Audit Trail.
// Provides append-only hash chains, binary Merkle tree root calculation,
// verifiable inclusion proofs, and RFC architectural sign-off workflows.
//

import Foundation
import CryptoKit

public enum AuditActionType: String, Codable, Sendable, Equatable {
    case nodeCreated
    case nodeUpdated
    case nodeDeleted
    case connectorLinked
    case connectorUnlinked
    case rfcApproved
    case rfcRejected
    case policyEnforced
}

public enum EnterpriseRole: String, Codable, Sendable, Equatable {
    case architectureOwner
    case contributor
    case reviewer
    case auditor
}

public enum IdentityProvider: String, Codable, Sendable, Equatable {
    case githubEnterprise
    case okta
    case googleWorkspace
    case keycloak
    case local
}

public struct AuditActor: Codable, Sendable, Equatable {
    public let userId: String
    public let email: String
    public let role: EnterpriseRole
    public let tenantId: String
    public let provider: IdentityProvider

    public init(
        userId: String,
        email: String,
        role: EnterpriseRole,
        tenantId: String = "enterprise-default",
        provider: IdentityProvider = .githubEnterprise
    ) {
        self.userId = userId
        self.email = email
        self.role = role
        self.tenantId = tenantId
        self.provider = provider
    }
}

public struct MerkleAuditLeaf: Codable, Sendable, Identifiable, Equatable {
    public var id: String { leafHash }
    public let index: Int
    public let timestampIso: String
    public let action: AuditActionType
    public let actor: AuditActor
    public let entityId: String
    public let entityType: String
    public let previousHash: String
    public let payloadHash: String
    public let leafHash: String

    public init(
        index: Int,
        timestampIso: String = ISO8601DateFormatter().string(from: Date()),
        action: AuditActionType,
        actor: AuditActor,
        entityId: String,
        entityType: String,
        previousHash: String,
        payloadJson: String
    ) {
        self.index = index
        self.timestampIso = timestampIso
        self.action = action
        self.actor = actor
        self.entityId = entityId
        self.entityType = entityType
        self.previousHash = previousHash

        let pDigest = SHA256.hash(data: Data(payloadJson.utf8))
        self.payloadHash = pDigest.compactMap { String(format: "%02x", $0) }.joined()

        let combined = "\(index)|\(timestampIso)|\(action.rawValue)|\(actor.email)|\(entityId)|\(previousHash)|\(self.payloadHash)"
        let lDigest = SHA256.hash(data: Data(combined.utf8))
        self.leafHash = lDigest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

public struct MerkleTreeRoot: Codable, Sendable, Equatable {
    public let rootHash: String
    public let leafCount: Int
    public let height: Int
    public let generatedAtIso: String

    public init(rootHash: String, leafCount: Int, height: Int, generatedAtIso: String = ISO8601DateFormatter().string(from: Date())) {
        self.rootHash = rootHash
        self.leafCount = leafCount
        self.height = height
        self.generatedAtIso = generatedAtIso
    }
}

public struct MerkleInclusionProof: Codable, Sendable, Equatable {
    public let leafHash: String
    public let leafIndex: Int
    public let auditPath: [String]
    public let rootHash: String
    public let isVerified: Bool

    public init(leafHash: String, leafIndex: Int, auditPath: [String], rootHash: String, isVerified: Bool) {
        self.leafHash = leafHash
        self.leafIndex = leafIndex
        self.auditPath = auditPath
        self.rootHash = rootHash
        self.isVerified = isVerified
    }
}

public enum RFCStatus: String, Codable, Sendable, Equatable {
    case draft
    case inReview
    case approved
    case rejected
}

public struct RFCWorkflowItem: Codable, Sendable, Identifiable, Equatable {
    public var id: String { rfcId }
    public let rfcId: String
    public let title: String
    public let authorEmail: String
    public var status: RFCStatus
    public var signers: [AuditActor]
    public var merkleLeafHash: String?

    public init(
        rfcId: String = UUID().uuidString,
        title: String,
        authorEmail: String,
        status: RFCStatus = .inReview,
        signers: [AuditActor] = [],
        merkleLeafHash: String? = nil
    ) {
        self.rfcId = rfcId
        self.title = title
        self.authorEmail = authorEmail
        self.status = status
        self.signers = signers
        self.merkleLeafHash = merkleLeafHash
    }
}

public final class MerkleAuditEngine: @unchecked Sendable {
    public static let shared = MerkleAuditEngine()
    private let lock = NSLock()

    private var auditLeaves: [MerkleAuditLeaf] = []
    private var rfcItems: [String: RFCWorkflowItem] = [:]
    private var currentActor: AuditActor

    public init() {
        self.currentActor = AuditActor(
            userId: "usr-arch-lead-01",
            email: "chief-architect@enterprise.corp",
            role: .architectureOwner,
            tenantId: "corp-global",
            provider: .githubEnterprise
        )

        // Seed genesis audit block
        let genesis = MerkleAuditLeaf(
            index: 0,
            action: .policyEnforced,
            actor: self.currentActor,
            entityId: "system-genesis",
            entityType: "security-perimeter",
            previousHash: "0000000000000000000000000000000000000000000000000000000000000000",
            payloadJson: "{\"policy\": \"zero-trust-architecture\", \"version\": \"1.0\"}"
        )
        auditLeaves.append(genesis)

        // Seed sample architectural RFC
        let rfc1 = RFCWorkflowItem(
            rfcId: "RFC-2026-08",
            title: "Migrate Payment Gateway from Monolith to Event-Driven Stream",
            authorEmail: "lead-dev@enterprise.corp",
            status: .inReview,
            signers: []
        )
        rfcItems[rfc1.rfcId] = rfc1
    }

    public func getCurrentActor() -> AuditActor {
        lock.lock()
        defer { lock.unlock() }
        return currentActor
    }

    public func setCurrentActor(_ actor: AuditActor) {
        lock.lock()
        defer { lock.unlock() }
        self.currentActor = actor
    }

    public func allLeaves() -> [MerkleAuditLeaf] {
        lock.lock()
        defer { lock.unlock() }
        return auditLeaves
    }

    /// Records an immutable audit action into the Merkle chain
    public func recordAction(
        action: AuditActionType,
        entityId: String,
        entityType: String,
        payloadJson: String,
        actor: AuditActor? = nil
    ) -> MerkleAuditLeaf {
        lock.lock()
        defer { lock.unlock() }

        let activeActor = actor ?? currentActor
        let prevHash = auditLeaves.last?.leafHash ?? "0000000000000000000000000000000000000000000000000000000000000000"
        let nextIndex = auditLeaves.count

        let leaf = MerkleAuditLeaf(
            index: nextIndex,
            action: action,
            actor: activeActor,
            entityId: entityId,
            entityType: entityType,
            previousHash: prevHash,
            payloadJson: payloadJson
        )
        auditLeaves.append(leaf)
        return leaf
    }

    /// Computes the cryptographic Merkle root from current audit leaves
    public func computeMerkleRoot() -> MerkleTreeRoot {
        lock.lock()
        defer { lock.unlock() }

        guard !auditLeaves.isEmpty else {
            return MerkleTreeRoot(rootHash: "0000000000000000000000000000000000000000000000000000000000000000", leafCount: 0, height: 0)
        }

        var currentLayer = auditLeaves.map { $0.leafHash }
        var height = 0

        while currentLayer.count > 1 {
            var nextLayer: [String] = []
            for i in stride(from: 0, to: currentLayer.count, by: 2) {
                let left = currentLayer[i]
                let right = (i + 1 < currentLayer.count) ? currentLayer[i + 1] : left
                let combined = left + right
                let digest = SHA256.hash(data: Data(combined.utf8))
                let parent = digest.compactMap { String(format: "%02x", $0) }.joined()
                nextLayer.append(parent)
            }
            currentLayer = nextLayer
            height += 1
        }

        return MerkleTreeRoot(
            rootHash: currentLayer.first ?? "",
            leafCount: auditLeaves.count,
            height: height
        )
    }

    /// Generates and cryptographically verifies an inclusion proof for a leaf
    public func generateInclusionProof(forLeafIndex index: Int) -> MerkleInclusionProof? {
        lock.lock()
        defer { lock.unlock() }

        guard index >= 0 && index < auditLeaves.count else { return nil }

        let targetLeafHash = auditLeaves[index].leafHash
        var currentLayer = auditLeaves.map { $0.leafHash }
        var auditPath: [String] = []
        var currentIndex = index

        while currentLayer.count > 1 {
            let siblingIndex = (currentIndex % 2 == 0) ? (currentIndex + 1) : (currentIndex - 1)
            let siblingHash = (siblingIndex < currentLayer.count) ? currentLayer[siblingIndex] : currentLayer[currentIndex]
            auditPath.append(siblingHash)

            var nextLayer: [String] = []
            for i in stride(from: 0, to: currentLayer.count, by: 2) {
                let left = currentLayer[i]
                let right = (i + 1 < currentLayer.count) ? currentLayer[i + 1] : left
                let combined = left + right
                let digest = SHA256.hash(data: Data(combined.utf8))
                nextLayer.append(digest.compactMap { String(format: "%02x", $0) }.joined())
            }
            currentLayer = nextLayer
            currentIndex /= 2
        }

        let calculatedRoot = currentLayer.first ?? ""

        // Validate proof
        var proofHash = targetLeafHash
        var verifyIndex = index
        for sibling in auditPath {
            let combined = (verifyIndex % 2 == 0) ? (proofHash + sibling) : (sibling + proofHash)
            let digest = SHA256.hash(data: Data(combined.utf8))
            proofHash = digest.compactMap { String(format: "%02x", $0) }.joined()
            verifyIndex /= 2
        }

        let isValid = (proofHash == calculatedRoot)

        return MerkleInclusionProof(
            leafHash: targetLeafHash,
            leafIndex: index,
            auditPath: auditPath,
            rootHash: calculatedRoot,
            isVerified: isValid
        )
    }

    /// Enterprise RFC sign-off workflow with RBAC gate
    public func signOffRFC(rfcId: String, approve: Bool, actor: AuditActor? = nil) -> (success: Bool, error: String?, item: RFCWorkflowItem?) {
        lock.lock()
        defer { lock.unlock() }

        let activeActor = actor ?? currentActor
        guard activeActor.role == .architectureOwner || activeActor.role == .reviewer else {
            return (false, "Forbidden: Actor role '\(activeActor.role.rawValue)' is not authorized to sign off architectural RFCs", nil)
        }

        guard var item = rfcItems[rfcId] else {
            return (false, "Not Found: RFC '\(rfcId)' does not exist", nil)
        }

        item.status = approve ? .approved : .rejected
        if !item.signers.contains(where: { $0.userId == activeActor.userId }) {
            item.signers.append(activeActor)
        }

        // Record action in Merkle chain
        let prevHash = auditLeaves.last?.leafHash ?? "0000000000000000000000000000000000000000000000000000000000000000"
        let leaf = MerkleAuditLeaf(
            index: auditLeaves.count,
            action: approve ? .rfcApproved : .rfcRejected,
            actor: activeActor,
            entityId: rfcId,
            entityType: "architectural-rfc",
            previousHash: prevHash,
            payloadJson: "{\"rfcId\": \"\(rfcId)\", \"title\": \"\(item.title)\", \"approved\": \(approve)}"
        )
        auditLeaves.append(leaf)
        item.merkleLeafHash = leaf.leafHash
        rfcItems[rfcId] = item

        return (true, nil, item)
    }

    public func allRFCs() -> [RFCWorkflowItem] {
        lock.lock()
        defer { lock.unlock() }
        return Array(rfcItems.values)
    }
}
