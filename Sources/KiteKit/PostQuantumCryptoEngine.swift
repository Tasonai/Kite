//
// PostQuantumCryptoEngine.swift
// KiteKit
//
// Post-Quantum Cryptography (NIST FIPS 203/204 ML-KEM & ML-DSA) Mesh Engine.
// Audits Cryptographic Bill of Materials (CBOM) for Shor-vulnerable RSA/ECDSA primitives,
// orchestrates hybrid X25519MLKEM768 + ML-DSA-65 epoch rotation, and synthesizes
// Envoy SDS PQ-TLS 1.3 transport socket manifests.
//

import Foundation

public struct CryptoPrimitiveEntry: Codable, Sendable, Identifiable, Equatable {
    public var id: String { componentId }
    public let componentId: String
    public let usage: String
    public var algorithm: String
    public var nistStandard: String
    public var quantumSafe: Bool
    public var keyEpoch: Int

    public init(
        componentId: String,
        usage: String,
        algorithm: String,
        nistStandard: String,
        quantumSafe: Bool,
        keyEpoch: Int = 1
    ) {
        self.componentId = componentId
        self.usage = usage
        self.algorithm = algorithm
        self.nistStandard = nistStandard
        self.quantumSafe = quantumSafe
        self.keyEpoch = keyEpoch
    }
}

public struct CbomAuditReport: Codable, Sendable, Equatable {
    public let bomFormat: String
    public let totalPrimitives: Int
    public let shorVulnerableCount: Int
    public let readinessScorePercent: Double
    public let entries: [CryptoPrimitiveEntry]

    public init(
        bomFormat: String = "CycloneDX-CBOM-1.6",
        totalPrimitives: Int,
        shorVulnerableCount: Int,
        readinessScorePercent: Double,
        entries: [CryptoPrimitiveEntry]
    ) {
        self.bomFormat = bomFormat
        self.totalPrimitives = totalPrimitives
        self.shorVulnerableCount = shorVulnerableCount
        self.readinessScorePercent = readinessScorePercent
        self.entries = entries
    }
}

public struct PqcRotationResult: Codable, Sendable, Equatable {
    public let newEpoch: Int
    public let upgradedCount: Int
    public let kemSuite: String
    public let signatureSuite: String
    public let allQuantumSafe: Bool

    public init(
        newEpoch: Int,
        upgradedCount: Int,
        kemSuite: String = "X25519MLKEM768",
        signatureSuite: String = "ML-DSA-65",
        allQuantumSafe: Bool
    ) {
        self.newEpoch = newEpoch
        self.upgradedCount = upgradedCount
        self.kemSuite = kemSuite
        self.signatureSuite = signatureSuite
        self.allQuantumSafe = allQuantumSafe
    }
}

public struct PqcTlsConfigBundle: Codable, Sendable, Equatable {
    public let clusterName: String
    public let hybridKemGroup: String
    public let signatureAlgorithm: String
    public let envoySdsYaml: String
    public let cbomJson: String

    public init(
        clusterName: String,
        hybridKemGroup: String = "X25519MLKEM768",
        signatureAlgorithm: String = "ML-DSA-65",
        envoySdsYaml: String,
        cbomJson: String
    ) {
        self.clusterName = clusterName
        self.hybridKemGroup = hybridKemGroup
        self.signatureAlgorithm = signatureAlgorithm
        self.envoySdsYaml = envoySdsYaml
        self.cbomJson = cbomJson
    }
}

public final class PostQuantumCryptoEngine: @unchecked Sendable {
    public static let shared = PostQuantumCryptoEngine()

    private let lock = NSLock()
    private var entries: [CryptoPrimitiveEntry]
    private var epoch: Int = 1

    public init() {
        entries = [
            CryptoPrimitiveEntry(
                componentId: "edge-ingress-gateway",
                usage: "mTLS Key Exchange",
                algorithm: "X25519MLKEM768",
                nistStandard: "FIPS-203",
                quantumSafe: true,
                keyEpoch: 1
            ),
            CryptoPrimitiveEntry(
                componentId: "auth-token-signer",
                usage: "JWT / SVID Digital Signature",
                algorithm: "ECDSA-P256",
                nistStandard: "Legacy-FIPS-186",
                quantumSafe: false,
                keyEpoch: 1
            ),
            CryptoPrimitiveEntry(
                componentId: "orders-ledger-AtRest",
                usage: "Envelope Encryption",
                algorithm: "AES-256-GCM",
                nistStandard: "Grover-128bit-PQ",
                quantumSafe: true,
                keyEpoch: 1
            ),
            CryptoPrimitiveEntry(
                componentId: "partner-webhook-bridge",
                usage: "TLS Handshake Auth",
                algorithm: "RSA-2048",
                nistStandard: "Legacy-PKCS1",
                quantumSafe: false,
                keyEpoch: 1
            )
        ]
    }

    public func auditCbom() -> CbomAuditReport {
        lock.lock()
        let snap = entries
        lock.unlock()

        let total = snap.count
        let vuln = snap.filter { !$0.quantumSafe }.count
        let rawScore = total == 0 ? 100.0 : (Double(total - vuln) / Double(total)) * 100.0
        let score = (rawScore * 10.0).rounded() / 10.0

        return CbomAuditReport(
            bomFormat: "CycloneDX-CBOM-1.6",
            totalPrimitives: total,
            shorVulnerableCount: vuln,
            readinessScorePercent: score,
            entries: snap
        )
    }

    public func rotateToHybridPqc() -> PqcRotationResult {
        lock.lock()
        defer { lock.unlock() }

        epoch += 1
        var upgraded = 0
        for i in 0..<entries.count {
            entries[i].keyEpoch = epoch
            if !entries[i].quantumSafe {
                upgraded += 1
                if entries[i].usage.localizedCaseInsensitiveContains("Signature") {
                    entries[i].algorithm = "ML-DSA-65"
                    entries[i].nistStandard = "FIPS-204"
                } else {
                    entries[i].algorithm = "X25519MLKEM768"
                    entries[i].nistStandard = "FIPS-203"
                }
                entries[i].quantumSafe = true
            }
        }

        let allSafe = entries.allSatisfy(\.quantumSafe)
        return PqcRotationResult(
            newEpoch: epoch,
            upgradedCount: upgraded,
            kemSuite: "X25519MLKEM768",
            signatureSuite: "ML-DSA-65",
            allQuantumSafe: allSafe
        )
    }

    public func generateEnvoyPqcConfig(clusterName: String = "kite-mesh-upstream") -> PqcTlsConfigBundle {
        let safeCluster = clusterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "kite-mesh-upstream"
            : clusterName.trimmingCharacters(in: .whitespacesAndNewlines)
        let audit = auditCbom()

        let envoy = """
        transport_socket:
          name: envoy.transport_sockets.tls
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
            sni: \(safeCluster).internal
            common_tls_context:
              tls_params:
                tls_minimum_protocol_version: TLSv1_3
                tls_maximum_protocol_version: TLSv1_3
                ecdh_curves:
                  - X25519MLKEM768
                  - X25519
                signature_algorithms:
                  - mldsa65
                  - ecdsa_secp256r1_sha256
        """

        let cbomJson = """
        {
          "bomFormat": "CycloneDX",
          "specVersion": "1.6",
          "cryptoProperties": {
            "hybridKem": "X25519MLKEM768",
            "signature": "ML-DSA-65",
            "readinessPercent": \(String(format: "%.1f", audit.readinessScorePercent))
          }
        }
        """

        return PqcTlsConfigBundle(
            clusterName: safeCluster,
            hybridKemGroup: "X25519MLKEM768",
            signatureAlgorithm: "ML-DSA-65",
            envoySdsYaml: envoy,
            cbomJson: cbomJson
        )
    }
}
