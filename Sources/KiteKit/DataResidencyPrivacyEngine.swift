//
// DataResidencyPrivacyEngine.swift
// KiteKit
//
// Sovereign Data Residency, PII Lineage & Differential Privacy Engine (Phase 31).
// Traces GDPR/PCI data-classification lineage across cloud jurisdictions, enforces
// Schrems II / GDPR Art. 44 cross-border transfer guardrails, and calibrates
// (epsilon, delta)-Differential Privacy noise scales alongside PostgreSQL RLS DDL.
//

import Foundation

public struct DataLineageFlow: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let datasetName: String
    public let classification: String
    public let sourceJurisdiction: String
    public let destinationRegion: String
    public let pseudonymized: Bool

    public init(
        id: String,
        datasetName: String,
        classification: String,
        sourceJurisdiction: String,
        destinationRegion: String,
        pseudonymized: Bool
    ) {
        self.id = id
        self.datasetName = datasetName
        self.classification = classification
        self.sourceJurisdiction = sourceJurisdiction
        self.destinationRegion = destinationRegion
        self.pseudonymized = pseudonymized
    }
}

public struct ResidencyComplianceReport: Codable, Sendable, Equatable {
    public let inspectedFlows: Int
    public let violationsCount: Int
    public let gdprCompliant: Bool
    public let violations: [String]

    public init(
        inspectedFlows: Int,
        violationsCount: Int,
        gdprCompliant: Bool,
        violations: [String]
    ) {
        self.inspectedFlows = inspectedFlows
        self.violationsCount = violationsCount
        self.gdprCompliant = gdprCompliant
        self.violations = violations
    }
}

public struct DifferentialPrivacyBundle: Codable, Sendable, Equatable {
    public let epsilon: Double
    public let delta: Double
    public let l2Sensitivity: Double
    public let laplaceScaleB: Double
    public let gaussianSigma: Double
    public let postgresRlsMaskingSql: String

    public init(
        epsilon: Double,
        delta: Double,
        l2Sensitivity: Double,
        laplaceScaleB: Double,
        gaussianSigma: Double,
        postgresRlsMaskingSql: String
    ) {
        self.epsilon = epsilon
        self.delta = delta
        self.l2Sensitivity = l2Sensitivity
        self.laplaceScaleB = laplaceScaleB
        self.gaussianSigma = gaussianSigma
        self.postgresRlsMaskingSql = postgresRlsMaskingSql
    }
}

public final class DataResidencyPrivacyEngine: @unchecked Sendable {
    public static let shared = DataResidencyPrivacyEngine()

    private let lock = NSLock()
    private var lineageFlows: [DataLineageFlow] = []

    public init() {
        seedFlows()
    }

    private func seedFlows() {
        lineageFlows = [
            DataLineageFlow(
                id: "flow-pii-eu-local",
                datasetName: "customer_identity_vault",
                classification: "GDPR_PII",
                sourceJurisdiction: "EU-EEA",
                destinationRegion: "eu-central-1",
                pseudonymized: false
            ),
            DataLineageFlow(
                id: "flow-pci-ch-vault",
                datasetName: "cardholder_pan_tokens",
                classification: "PCI_CHD",
                sourceJurisdiction: "CH-SOVEREIGN",
                destinationRegion: "ch-zurich-1",
                pseudonymized: true
            ),
            DataLineageFlow(
                id: "flow-pii-us-export",
                datasetName: "marketing_clickstream_raw",
                classification: "GDPR_PII",
                sourceJurisdiction: "EU-EEA",
                destinationRegion: "us-east-1",
                pseudonymized: false
            ),
            DataLineageFlow(
                id: "flow-telem-global",
                datasetName: "edge_pop_latency_histograms",
                classification: "PUBLIC_TELEMETRY",
                sourceJurisdiction: "EU-EEA",
                destinationRegion: "us-east-1",
                pseudonymized: true
            )
        ]
    }

    public func getLineageFlows() -> [DataLineageFlow] {
        lock.lock()
        defer { lock.unlock() }
        return lineageFlows
    }

    public func auditResidencyCompliance(enforceStrictSchremsII: Bool = true) -> ResidencyComplianceReport {
        lock.lock()
        let flows = lineageFlows
        lock.unlock()

        var violations: [String] = []
        for flow in flows {
            let isRegulated = flow.classification == "GDPR_PII" || flow.classification == "PCI_CHD"
            guard isRegulated else { continue }

            let isSovereignSource = flow.sourceJurisdiction == "EU-EEA" || flow.sourceJurisdiction == "CH-SOVEREIGN"
            let isAdequateDest = flow.destinationRegion.hasPrefix("eu-") || flow.destinationRegion.hasPrefix("ch-")

            if isSovereignSource && !isAdequateDest && !flow.pseudonymized {
                if enforceStrictSchremsII || flow.classification == "PCI_CHD" {
                    violations.append(
                        "GDPR Art. 44 / Schrems II violation on \(flow.id) (\(flow.datasetName)): unpseudonymized \(flow.classification) exported from \(flow.sourceJurisdiction) to \(flow.destinationRegion)."
                    )
                }
            }
        }

        return ResidencyComplianceReport(
            inspectedFlows: flows.count,
            violationsCount: violations.count,
            gdprCompliant: violations.isEmpty,
            violations: violations
        )
    }

    public func calibrateDifferentialPrivacy(
        epsilon: Double = 0.5,
        delta: Double = 1e-5,
        sensitivity: Double = 1.0
    ) -> DifferentialPrivacyBundle {
        let eps = max(epsilon, 0.0001)
        let del = min(max(delta, 1e-12), 0.1)
        let sens = max(sensitivity, 0.0001)

        let rawLaplace = sens / eps
        let rawGaussian = (sens * sqrt(2.0 * log(1.25 / del))) / eps

        let laplaceB = (rawLaplace * 10000.0).rounded() / 10000.0
        let gaussianSig = (rawGaussian * 10000.0).rounded() / 10000.0

        let sqlDdl = """
        -- Sovereign Row-Level Security & Differential Privacy Rollup (epsilon=\(eps), delta=\(del))
        ALTER TABLE customer_identity_vault ENABLE ROW LEVEL SECURITY;
        ALTER TABLE customer_identity_vault FORCE ROW LEVEL SECURITY;

        CREATE POLICY sovereign_jurisdiction_isolation
            ON customer_identity_vault
            FOR ALL
            USING (source_jurisdiction = current_setting('app.sovereign_jurisdiction', true));

        CREATE OR REPLACE VIEW analytics_dp_customer_rollup AS
        SELECT
            source_jurisdiction,
            encode(digest(customer_email, 'sha256'), 'hex') AS pseudonymized_subject_key,
            COUNT(*) + dp_gaussian_noise(0.0, \(gaussianSig)) AS dp_cohort_count
        FROM customer_identity_vault
        GROUP BY source_jurisdiction, encode(digest(customer_email, 'sha256'), 'hex');
        """

        return DifferentialPrivacyBundle(
            epsilon: eps,
            delta: del,
            l2Sensitivity: sens,
            laplaceScaleB: laplaceB,
            gaussianSigma: gaussianSig,
            postgresRlsMaskingSql: sqlDdl
        )
    }
}
