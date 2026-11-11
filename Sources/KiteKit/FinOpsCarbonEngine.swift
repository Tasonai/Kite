//
// FinOpsCarbonEngine.swift
// KiteKit
//
// FinOps Cloud Cost Arbitrage & Carbon-Aware Green Scheduler Engine.
// Analyzes multi-cloud unit economics across AWS, GCP, Azure, and bare-metal providers,
// synthesizes ARM64 Graviton/Axion & Spot savings plans, profiles regional grid carbon intensity
// (gCO2eq/kWh), and generates Karpenter NodePool + KEDA carbon-aware batch/AI scalers.
//

import Foundation

public struct CloudWorkloadSpend: Codable, Sendable, Identifiable, Equatable {
    public var id: String { workloadId }
    public let workloadId: String
    public let provider: String
    public let region: String
    public let instanceFamily: String
    public let architecture: String
    public let monthlyCostUsd: Double
    public let cpuUtilizationPercent: Double
    public let gridCarbonGco2PerKwh: Int

    public init(
        workloadId: String,
        provider: String,
        region: String,
        instanceFamily: String,
        architecture: String = "x86_64",
        monthlyCostUsd: Double,
        cpuUtilizationPercent: Double,
        gridCarbonGco2PerKwh: Int
    ) {
        self.workloadId = workloadId
        self.provider = provider
        self.region = region
        self.instanceFamily = instanceFamily
        self.architecture = architecture
        self.monthlyCostUsd = monthlyCostUsd
        self.cpuUtilizationPercent = cpuUtilizationPercent
        self.gridCarbonGco2PerKwh = gridCarbonGco2PerKwh
    }
}

public struct ArbitrageRecommendation: Codable, Sendable, Identifiable, Equatable {
    public var id: String { workloadId }
    public let workloadId: String
    public let currentMonthlyUsd: Double
    public let projectedMonthlyUsd: Double
    public let monthlySavingsUsd: Double
    public let targetArchitecture: String
    public let strategy: String

    public init(
        workloadId: String,
        currentMonthlyUsd: Double,
        projectedMonthlyUsd: Double,
        monthlySavingsUsd: Double,
        targetArchitecture: String,
        strategy: String
    ) {
        self.workloadId = workloadId
        self.currentMonthlyUsd = currentMonthlyUsd
        self.projectedMonthlyUsd = projectedMonthlyUsd
        self.monthlySavingsUsd = monthlySavingsUsd
        self.targetArchitecture = targetArchitecture
        self.strategy = strategy
    }
}

public struct FinOpsArbitrageReport: Codable, Sendable, Equatable {
    public let totalCurrentMonthlyUsd: Double
    public let totalProjectedMonthlyUsd: Double
    public let totalMonthlySavingsUsd: Double
    public let savingsPercent: Double
    public let recommendations: [ArbitrageRecommendation]

    public init(
        totalCurrentMonthlyUsd: Double,
        totalProjectedMonthlyUsd: Double,
        totalMonthlySavingsUsd: Double,
        savingsPercent: Double,
        recommendations: [ArbitrageRecommendation]
    ) {
        self.totalCurrentMonthlyUsd = totalCurrentMonthlyUsd
        self.totalProjectedMonthlyUsd = totalProjectedMonthlyUsd
        self.totalMonthlySavingsUsd = totalMonthlySavingsUsd
        self.savingsPercent = savingsPercent
        self.recommendations = recommendations
    }
}

public struct GreenScheduleBundle: Codable, Sendable, Equatable {
    public let optimalLowCarbonRegion: String
    public let optimalCarbonGco2PerKwh: Int
    public let carbonReductionPercent: Double
    public let karpenterNodePoolYaml: String
    public let kedaCarbonScalerYaml: String

    public init(
        optimalLowCarbonRegion: String,
        optimalCarbonGco2PerKwh: Int,
        carbonReductionPercent: Double,
        karpenterNodePoolYaml: String,
        kedaCarbonScalerYaml: String
    ) {
        self.optimalLowCarbonRegion = optimalLowCarbonRegion
        self.optimalCarbonGco2PerKwh = optimalCarbonGco2PerKwh
        self.carbonReductionPercent = carbonReductionPercent
        self.karpenterNodePoolYaml = karpenterNodePoolYaml
        self.kedaCarbonScalerYaml = kedaCarbonScalerYaml
    }
}

public final class FinOpsCarbonEngine: @unchecked Sendable {
    public static let shared = FinOpsCarbonEngine()

    private let lock = NSLock()
    private var workloads: [CloudWorkloadSpend] = []

    public init() {
        seedWorkloads()
    }

    private func seedWorkloads() {
        workloads = [
            CloudWorkloadSpend(
                workloadId: "api-core-fleet",
                provider: "aws",
                region: "eu-central-1",
                instanceFamily: "m6i.4xlarge",
                architecture: "x86_64",
                monthlyCostUsd: 4800.0,
                cpuUtilizationPercent: 28.5,
                gridCarbonGco2PerKwh: 315
            ),
            CloudWorkloadSpend(
                workloadId: "ml-embedding-batch",
                provider: "aws",
                region: "us-east-1",
                instanceFamily: "g5.2xlarge",
                architecture: "x86_64",
                monthlyCostUsd: 6200.0,
                cpuUtilizationPercent: 41.0,
                gridCarbonGco2PerKwh: 365
            ),
            CloudWorkloadSpend(
                workloadId: "analytics-warehouse-workers",
                provider: "gcp",
                region: "eu-north-1",
                instanceFamily: "t2a-standard-8",
                architecture: "arm64",
                monthlyCostUsd: 1900.0,
                cpuUtilizationPercent: 72.0,
                gridCarbonGco2PerKwh: 28
            )
        ]
    }

    public func getWorkloads() -> [CloudWorkloadSpend] {
        lock.lock()
        defer { lock.unlock() }
        return workloads
    }

    public func computeArbitrage(allowSpotForStateless: Bool = true) -> FinOpsArbitrageReport {
        lock.lock()
        let items = workloads
        lock.unlock()

        var recs: [ArbitrageRecommendation] = []
        var totalCur = 0.0
        var totalProj = 0.0

        for w in items {
            totalCur += w.monthlyCostUsd
            var discountFactor = 1.0
            var reasons: [String] = []

            if w.architecture == "x86_64" {
                discountFactor *= 0.72
                reasons.append("Migrate x86_64 to ARM64 Graviton4/Axion (-28%)")
            }
            if w.cpuUtilizationPercent < 40.0 {
                discountFactor *= 0.75
                reasons.append("Right-size underutilized vCPUs (<40% avg)")
            }
            if allowSpotForStateless && w.workloadId.contains("batch") {
                discountFactor *= 0.55
                reasons.append("Shift fault-tolerant batch pool to Spot capacity (-45%)")
            }

            let projected = ((w.monthlyCostUsd * discountFactor) * 100.0).rounded() / 100.0
            let saved = ((w.monthlyCostUsd - projected) * 100.0).rounded() / 100.0
            totalProj += projected

            if saved > 0.0 {
                recs.append(ArbitrageRecommendation(
                    workloadId: w.workloadId,
                    currentMonthlyUsd: w.monthlyCostUsd,
                    projectedMonthlyUsd: projected,
                    monthlySavingsUsd: saved,
                    targetArchitecture: "arm64",
                    strategy: reasons.joined(separator: "; ")
                ))
            }
        }

        let totalSaved = ((totalCur - totalProj) * 100.0).rounded() / 100.0
        let pct = totalCur > 0 ? (((totalSaved / totalCur) * 1000.0).rounded() / 10.0) : 0.0

        return FinOpsArbitrageReport(
            totalCurrentMonthlyUsd: (totalCur * 100.0).rounded() / 100.0,
            totalProjectedMonthlyUsd: (totalProj * 100.0).rounded() / 100.0,
            totalMonthlySavingsUsd: totalSaved,
            savingsPercent: pct,
            recommendations: recs
        )
    }

    public func generateGreenSchedule(maxCarbonThresholdGco2: Int = 80) -> GreenScheduleBundle {
        lock.lock()
        let items = workloads
        lock.unlock()

        let greenest = items.min(by: { $0.gridCarbonGco2PerKwh < $1.gridCarbonGco2PerKwh })
            ?? CloudWorkloadSpend(workloadId: "default", provider: "gcp", region: "eu-north-1", instanceFamily: "t2a", architecture: "arm64", monthlyCostUsd: 1000, cpuUtilizationPercent: 70, gridCarbonGco2PerKwh: 28)

        let avgCarbon = items.isEmpty ? 300.0 : (Double(items.reduce(0) { $0 + $1.gridCarbonGco2PerKwh }) / Double(items.count))
        let reduction = avgCarbon > 0 ? ((((avgCarbon - Double(greenest.gridCarbonGco2PerKwh)) / avgCarbon) * 1000.0).rounded() / 10.0) : 0.0

        let karpenterYaml = """
        apiVersion: karpenter.sh/v1
        kind: NodePool
        metadata:
          name: kite-arm64-finops-pool
        spec:
          template:
            spec:
              requirements:
                - key: kubernetes.io/arch
                  operator: In
                  values: ["arm64"]
                - key: karpenter.sh/capacity-type
                  operator: In
                  values: ["spot", "on-demand"]
          disruption:
            consolidationPolicy: WhenEmptyOrUnderutilized
            consolidateAfter: 30s
        """

        let kedaYaml = """
        apiVersion: keda.sh/v1alpha1
        kind: ScaledObject
        metadata:
          name: kite-carbon-aware-batch-scaler
        spec:
          scaleTargetRef:
            name: ml-embedding-batch
          minReplicaCount: 0
          maxReplicaCount: 32
          triggers:
            - type: carbon-aware-grid
              metadata:
                targetRegion: "\(greenest.region)"
                maxCarbonIntensityGco2Kwh: "\(maxCarbonThresholdGco2)"
        """

        return GreenScheduleBundle(
            optimalLowCarbonRegion: greenest.region,
            optimalCarbonGco2PerKwh: greenest.gridCarbonGco2PerKwh,
            carbonReductionPercent: reduction,
            karpenterNodePoolYaml: karpenterYaml,
            kedaCarbonScalerYaml: kedaYaml
        )
    }
}
