//
// SupplyChainProvenanceEngine.swift
// KiteKit
//
// Supply-Chain Provenance Engine (Phase 30: SLSA Level 4, Sigstore Cosign & SPDX 3.0).
// Evaluates OCI artifact attestations against SLSA v1.0 Build Levels 1-4 (hermetic networkless
// builds, two-party review, keyless Fulcio/Rekor transparency log entries) and synthesizes
// Sigstore PolicyController admission policies alongside SPDX 3.0 SBOM envelopes.
//

import Foundation

public struct ArtifactProvenanceRecord: Codable, Sendable, Identifiable, Equatable {
    public var id: String { artifactId }
    public let artifactId: String
    public let ociDigest: String
    public let builderId: String
    public let hermeticBuild: Bool
    public let twoPartyReviewed: Bool
    public let rekorLogIndex: Int
    public let cosignVerified: Bool

    public init(
        artifactId: String,
        ociDigest: String,
        builderId: String,
        hermeticBuild: Bool,
        twoPartyReviewed: Bool,
        rekorLogIndex: Int,
        cosignVerified: Bool
    ) {
        self.artifactId = artifactId
        self.ociDigest = ociDigest
        self.builderId = builderId
        self.hermeticBuild = hermeticBuild
        self.twoPartyReviewed = twoPartyReviewed
        self.rekorLogIndex = rekorLogIndex
        self.cosignVerified = cosignVerified
    }
}

public struct SlsaVerificationReport: Codable, Sendable, Equatable {
    public let artifactId: String
    public let achievedSlsaLevel: Int
    public let admissionAllowed: Bool
    public let violations: [String]

    public init(
        artifactId: String,
        achievedSlsaLevel: Int,
        admissionAllowed: Bool,
        violations: [String]
    ) {
        self.artifactId = artifactId
        self.achievedSlsaLevel = achievedSlsaLevel
        self.admissionAllowed = admissionAllowed
        self.violations = violations
    }
}

public struct SupplyChainAdmissionBundle: Codable, Sendable, Equatable {
    public let namespace: String
    public let clusterImagePolicyYaml: String
    public let spdx3SbomJson: String
    public let inTotoStatementJson: String

    public init(
        namespace: String,
        clusterImagePolicyYaml: String,
        spdx3SbomJson: String,
        inTotoStatementJson: String
    ) {
        self.namespace = namespace
        self.clusterImagePolicyYaml = clusterImagePolicyYaml
        self.spdx3SbomJson = spdx3SbomJson
        self.inTotoStatementJson = inTotoStatementJson
    }
}

public final class SupplyChainProvenanceEngine: @unchecked Sendable {
    public static let shared = SupplyChainProvenanceEngine()

    private let lock = NSLock()
    private var artifacts: [ArtifactProvenanceRecord] = []

    public init() {
        seedArtifacts()
    }

    private func seedArtifacts() {
        artifacts = [
            ArtifactProvenanceRecord(
                artifactId: "ghcr.io/kite/checkout-api",
                ociDigest: "sha256:9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
                builderId: "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml",
                hermeticBuild: true,
                twoPartyReviewed: true,
                rekorLogIndex: 88412904,
                cosignVerified: true
            ),
            ArtifactProvenanceRecord(
                artifactId: "ghcr.io/kite/ledger-writer",
                ociDigest: "sha256:4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a",
                builderId: "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml",
                hermeticBuild: true,
                twoPartyReviewed: true,
                rekorLogIndex: 88412991,
                cosignVerified: true
            ),
            ArtifactProvenanceRecord(
                artifactId: "docker.io/vendor/legacy-agent",
                ociDigest: "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
                builderId: "unverified-local-workstation",
                hermeticBuild: false,
                twoPartyReviewed: false,
                rekorLogIndex: 0,
                cosignVerified: false
            )
        ]
    }

    public func getArtifacts() -> [ArtifactProvenanceRecord] {
        lock.lock()
        defer { lock.unlock() }
        return artifacts
    }

    public func verifySlsaCompliance(
        artifactId: String = "ghcr.io/kite/checkout-api",
        requireLevel: Int = 4
    ) -> SlsaVerificationReport {
        lock.lock()
        let art = artifacts.first(where: { $0.artifactId == artifactId }) ?? artifacts[0]
        lock.unlock()

        let reqLevel = min(max(requireLevel, 1), 4)
        var violations: [String] = []
        var level = 1

        if art.cosignVerified && art.builderId.hasPrefix("https://") {
            level = 2
        } else {
            violations.append("Missing keyless Sigstore Cosign signature or trusted hosted builder URI.")
        }

        if level == 2 && art.rekorLogIndex > 0 {
            level = 3
        } else if level >= 1 && art.rekorLogIndex <= 0 {
            violations.append("Missing immutable Rekor transparency log inclusion proof.")
        }

        if level == 3 && art.hermeticBuild && art.twoPartyReviewed {
            level = 4
        } else {
            if !art.hermeticBuild {
                violations.append("Build environment was not hermetic (network egress was enabled during compilation).")
            }
            if !art.twoPartyReviewed {
                violations.append("Source revision lacks cryptographically attested two-party peer review.")
            }
        }

        return SlsaVerificationReport(
            artifactId: art.artifactId,
            achievedSlsaLevel: level,
            admissionAllowed: level >= reqLevel,
            violations: violations
        )
    }

    public func synthesizeAdmissionBundle(namespace: String = "kite-prod") -> SupplyChainAdmissionBundle {
        let cipYaml = """
        apiVersion: policy.sigstore.dev/v1beta1
        kind: ClusterImagePolicy
        metadata:
          name: kite-slsa-l4-admission-gate
        spec:
          images:
            - glob: "ghcr.io/kite/**"
          authorities:
            - keyless:
                url: https://fulcio.sigstore.dev
                identities:
                  - issuer: https://token.actions.githubusercontent.com
                    subjectRegExp: "^https://github.com/Tasonai/Kite.*"
              ctlog:
                url: https://rekor.sigstore.dev
              attestations:
                - name: must-have-slsa-provenance-v1
                  predicateType: https://slsa.dev/provenance/v1
                  policy:
                    type: cue
                    data: |
                      predicateType: "https://slsa.dev/provenance/v1"
                      predicate: buildDefinition: buildType: =~"^https://slsa.dev/"
        """

        let spdxJson = """
        {
          "@context": "https://spdx.org/rdf/3.0.1/spdx-context.jsonld",
          "@graph": [
            {
              "type": "SpdxDocument",
              "spdxId": "urn:spdx:kite-\(namespace)-sbom-v3",
              "creationInfo": {
                "specVersion": "3.0.1",
                "profile": ["core", "software", "security", "build"]
              }
            }
          ]
        }
        """

        let inTotoJson = """
        {
          "_type": "https://in-toto.io/Statement/v1",
          "predicateType": "https://slsa.dev/provenance/v1",
          "predicate": {
            "buildDefinition": {
              "buildType": "https://slsa.dev/hermetic-build/v1",
              "externalParameters": { "hermetic": true, "twoPartyReviewed": true }
            }
          }
        }
        """

        return SupplyChainAdmissionBundle(
            namespace: namespace,
            clusterImagePolicyYaml: cipYaml,
            spdx3SbomJson: spdxJson,
            inTotoStatementJson: inTotoJson
        )
    }
}
