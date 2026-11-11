//
// HyperscaleCockpitAggregator.swift
// KiteKit
//
// Unified cross-engine view-model aggregator for the Native Hyperscale & Governance
// Inspector UI (Milestone 4.0 + Milestone 5.0 engines).
//

import Foundation

public struct HyperscaleCockpitSnapshot: Codable, Sendable, Equatable {
    public let strataCount: Int
    public let spatialNodesCount: Int
    public let ebpfFlowsCount: Int
    public let shadowApiCount: Int
    public let healthyEdgePopsCount: Int
    public let drRegionsCount: Int
    public let monthlyArbitrageSavingsUsd: Double
    public let optimalGreenRegion: String
    public let formalVerified: Bool
    public let formalStatesExplored: Int
    public let pqcReadinessPercent: Double
    public let frozenSloServicesCount: Int
    public let remediationPlaybooksCount: Int
    public let spiffeTrustDomainsCount: Int

    public init(
        strataCount: Int,
        spatialNodesCount: Int,
        ebpfFlowsCount: Int,
        shadowApiCount: Int,
        healthyEdgePopsCount: Int,
        drRegionsCount: Int,
        monthlyArbitrageSavingsUsd: Double,
        optimalGreenRegion: String,
        formalVerified: Bool,
        formalStatesExplored: Int,
        pqcReadinessPercent: Double,
        frozenSloServicesCount: Int,
        remediationPlaybooksCount: Int,
        spiffeTrustDomainsCount: Int
    ) {
        self.strataCount = strataCount
        self.spatialNodesCount = spatialNodesCount
        self.ebpfFlowsCount = ebpfFlowsCount
        self.shadowApiCount = shadowApiCount
        self.healthyEdgePopsCount = healthyEdgePopsCount
        self.drRegionsCount = drRegionsCount
        self.monthlyArbitrageSavingsUsd = monthlyArbitrageSavingsUsd
        self.optimalGreenRegion = optimalGreenRegion
        self.formalVerified = formalVerified
        self.formalStatesExplored = formalStatesExplored
        self.pqcReadinessPercent = pqcReadinessPercent
        self.frozenSloServicesCount = frozenSloServicesCount
        self.remediationPlaybooksCount = remediationPlaybooksCount
        self.spiffeTrustDomainsCount = spiffeTrustDomainsCount
    }
}

public final class HyperscaleCockpitAggregator: @unchecked Sendable {
    public static let shared = HyperscaleCockpitAggregator()

    public init() {}

    public func captureSnapshot() -> HyperscaleCockpitSnapshot {
        let scene = Spatial3DTopologyEngine.shared.getScene()
        let flows = EbpfTelemetryEngine.shared.getKernelFlows()
        let shadow = EbpfTelemetryEngine.shared.auditShadowDependencies()
        let pops = WasmEdgeMeshEngine.shared.getGlobalPops()
        let regions = DisasterRecoveryEngine.shared.getRegions()
        let arb = FinOpsCarbonEngine.shared.computeArbitrage(allowSpotForStateless: true)
        let green = FinOpsCarbonEngine.shared.generateGreenSchedule(maxCarbonThresholdGco2: 80)
        let formal = FormalVerificationEngine.shared.runBoundedModelCheck(maxDepth: 8, injectSplitBrainFault: false)
        let cbom = PostQuantumCryptoEngine.shared.auditCbom()
        let budgets = SloBurnRateEngine.shared.getBudgets()
        let frozen = budgets.filter {
            SloBurnRateEngine.shared.evaluateReleaseGate(serviceId: $0.serviceId).verdict == "FREEZE_RELEASE"
        }.count
        let playbooks = AutoRemediationEngine.shared.getPlaybooks()
        let domains = FederationCatalogEngine.shared.getTrustDomains()

        return HyperscaleCockpitSnapshot(
            strataCount: scene.strataCount,
            spatialNodesCount: scene.nodes.count,
            ebpfFlowsCount: flows.count,
            shadowApiCount: shadow.undocumentedEdgesCount + shadow.rogueEgressCount,
            healthyEdgePopsCount: pops.filter(\.isHealthy).count,
            drRegionsCount: regions.count,
            monthlyArbitrageSavingsUsd: arb.totalMonthlySavingsUsd,
            optimalGreenRegion: green.optimalLowCarbonRegion,
            formalVerified: formal.verified,
            formalStatesExplored: formal.distinctStatesExplored,
            pqcReadinessPercent: cbom.readinessScorePercent,
            frozenSloServicesCount: frozen,
            remediationPlaybooksCount: playbooks.count,
            spiffeTrustDomainsCount: domains.count
        )
    }
}
