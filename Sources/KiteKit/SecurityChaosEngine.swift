//
// SecurityChaosEngine.swift
// KiteKit
//
// Architectural Security Red Team & Chaos Injection Engine.
// Evaluates STRIDE threat surfaces, computes dynamic blast radii,
// and synthesizes executable Chaos Mesh manifests and rollback runbooks.
//

import Foundation

public enum ThreatCategory: String, Codable, Sendable, Equatable {
    case spoofing
    case tampering
    case repudiation
    case informationDisclosure
    case denialOfService
    case elevationOfPrivilege
}

public enum ThreatSeverity: String, Codable, Sendable, Equatable {
    case critical
    case high
    case medium
    case low
}

public struct IdentifiedThreat: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public let category: ThreatCategory
    public let severity: ThreatSeverity
    public let targetNodeId: String
    public let targetNodeName: String
    public let description: String
    public let mitigationGuide: String
    public var isMitigated: Bool

    public init(
        id: String = UUID().uuidString,
        category: ThreatCategory,
        severity: ThreatSeverity,
        targetNodeId: String,
        targetNodeName: String,
        description: String,
        mitigationGuide: String,
        isMitigated: Bool = false
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.targetNodeId = targetNodeId
        self.targetNodeName = targetNodeName
        self.description = description
        self.mitigationGuide = mitigationGuide
        self.isMitigated = isMitigated
    }
}

public struct BlastRadiusReport: Codable, Sendable, Equatable {
    public let originNodeId: String
    public let originNodeName: String
    public let affectedUpstreamNodes: [String]
    public let affectedDownstreamNodes: [String]
    public let totalImpactPercentage: Double
    public let criticalPathRisk: String

    public init(
        originNodeId: String,
        originNodeName: String,
        affectedUpstreamNodes: [String],
        affectedDownstreamNodes: [String],
        totalImpactPercentage: Double,
        criticalPathRisk: String
    ) {
        self.originNodeId = originNodeId
        self.originNodeName = originNodeName
        self.affectedUpstreamNodes = affectedUpstreamNodes
        self.affectedDownstreamNodes = affectedDownstreamNodes
        self.totalImpactPercentage = totalImpactPercentage
        self.criticalPathRisk = criticalPathRisk
    }
}

public enum ChaosExperimentType: String, Codable, Sendable, Equatable {
    case podKill
    case networkLatency
    case packetDrop
    case cpuSpike
    case databaseFailover
}

public struct ChaosExperimentSpec: Codable, Sendable, Identifiable, Equatable {
    public var id: String { experimentId }
    public let experimentId: String
    public let type: ChaosExperimentType
    public let targetNodeName: String
    public let durationSec: Int
    public let blastRadiusPct: Double
    public let yamlManifest: String
    public let rollbackRunbook: String

    public init(
        experimentId: String = "chaos-" + UUID().uuidString.prefix(8).lowercased(),
        type: ChaosExperimentType,
        targetNodeName: String,
        durationSec: Int = 60,
        blastRadiusPct: Double = 25.0,
        yamlManifest: String,
        rollbackRunbook: String
    ) {
        self.experimentId = experimentId
        self.type = type
        self.targetNodeName = targetNodeName
        self.durationSec = durationSec
        self.blastRadiusPct = blastRadiusPct
        self.yamlManifest = yamlManifest
        self.rollbackRunbook = rollbackRunbook
    }
}

public struct SecurityScorecard: Codable, Sendable, Equatable {
    public let healthScore: Int
    public let totalThreatsCount: Int
    public let criticalCount: Int
    public let highCount: Int
    public let threats: [IdentifiedThreat]
    public let strideBreakdown: [String: Int]

    public init(
        healthScore: Int,
        totalThreatsCount: Int,
        criticalCount: Int,
        highCount: Int,
        threats: [IdentifiedThreat],
        strideBreakdown: [String: Int]
    ) {
        self.healthScore = healthScore
        self.totalThreatsCount = totalThreatsCount
        self.criticalCount = criticalCount
        self.highCount = highCount
        self.threats = threats
        self.strideBreakdown = strideBreakdown
    }
}

public final class SecurityChaosEngine: @unchecked Sendable {
    public static let shared = SecurityChaosEngine()
    private let lock = NSLock()

    public init() {}

    /// Performs STRIDE threat model audit on canvas nodes and connections
    public func auditTopology(
        nodes: [(id: String, name: String, type: String)],
        connections: [(fromId: String, toId: String, protocolType: String)]
    ) -> SecurityScorecard {
        lock.lock()
        defer { lock.unlock() }

        var threats: [IdentifiedThreat] = []
        var breakdown: [String: Int] = [
            "spoofing": 0,
            "tampering": 0,
            "repudiation": 0,
            "informationDisclosure": 0,
            "denialOfService": 0,
            "elevationOfPrivilege": 0
        ]

        let hasSecurityGate = nodes.contains { n in
            let lower = n.type.lowercased()
            return lower.contains("waf") || lower.contains("firewall") || lower.contains("gateway") || lower.contains("auth")
        }

        // 1. Check entry security
        if !hasSecurityGate && !nodes.isEmpty {
            let t = IdentifiedThreat(
                category: .elevationOfPrivilege,
                severity: .critical,
                targetNodeId: nodes.first?.id ?? "perimeter",
                targetNodeName: nodes.first?.name ?? "Edge",
                description: "Ingress points lack unified API Gateway / WAF authentication boundary",
                mitigationGuide: "Insert an API Gateway or WAF frame in front of application services."
            )
            threats.append(t)
            breakdown["elevationOfPrivilege", default: 0] += 1
        }

        // 2. Audit each node
        for node in nodes {
            let lower = node.type.lowercased()
            if lower.contains("db") || lower.contains("database") || lower.contains("postgres") {
                // Check if any frontend directly connects to DB
                let incoming = connections.filter { $0.toId == node.id }
                let directFrontend = incoming.contains { conn in
                    let caller = nodes.first(where: { $0.id == conn.fromId })
                    let callerType = caller?.type.lowercased() ?? ""
                    return callerType.contains("web") || callerType.contains("frontend") || callerType.contains("client")
                }

                if directFrontend {
                    let t = IdentifiedThreat(
                        category: .tampering,
                        severity: .critical,
                        targetNodeId: node.id,
                        targetNodeName: node.name,
                        description: "Direct client connection to database bypasses business logic validation",
                        mitigationGuide: "Route client requests through an authenticated backend service layer."
                    )
                    threats.append(t)
                    breakdown["tampering", default: 0] += 1
                }
            } else if lower.contains("queue") || lower.contains("stream") {
                let t = IdentifiedThreat(
                    category: .denialOfService,
                    severity: .medium,
                    targetNodeId: node.id,
                    targetNodeName: node.name,
                    description: "Message stream lacks backpressure buffer and Dead Letter Queue (DLQ)",
                    mitigationGuide: "Configure Dead Letter Queue and exponential retry limits."
                )
                threats.append(t)
                breakdown["denialOfService", default: 0] += 1
            }
        }

        // Compute health score
        let critCount = threats.filter { $0.severity == .critical }.count
        let highCount = threats.filter { $0.severity == .high }.count
        let medCount = threats.filter { $0.severity == .medium }.count
        let penalty = (critCount * 30) + (highCount * 15) + (medCount * 5)
        let score = max(10, min(100, 100 - penalty))

        return SecurityScorecard(
            healthScore: score,
            totalThreatsCount: threats.count,
            criticalCount: critCount,
            highCount: highCount,
            threats: threats,
            strideBreakdown: breakdown
        )
    }

    /// Computes dynamic blast radius of failure for a specific target node
    public func calculateBlastRadius(
        targetNodeId: String,
        nodes: [(id: String, name: String, type: String)],
        connections: [(fromId: String, toId: String, protocolType: String)]
    ) -> BlastRadiusReport {
        lock.lock()
        defer { lock.unlock() }

        guard let target = nodes.first(where: { $0.id == targetNodeId }) else {
            return BlastRadiusReport(
                originNodeId: targetNodeId,
                originNodeName: "Unknown",
                affectedUpstreamNodes: [],
                affectedDownstreamNodes: [],
                totalImpactPercentage: 0.0,
                criticalPathRisk: "Low"
            )
        }

        // Upstream callers (nodes pointing to target)
        var upstream: Set<String> = []
        for c in connections where c.toId == targetNodeId {
            if let n = nodes.first(where: { $0.id == c.fromId }) {
                upstream.insert(n.name)
            }
        }

        // Downstream dependencies (nodes target points to)
        var downstream: Set<String> = []
        for c in connections where c.fromId == targetNodeId {
            if let n = nodes.first(where: { $0.id == c.toId }) {
                downstream.insert(n.name)
            }
        }

        let totalNodes = max(1, nodes.count)
        let impactedCount = upstream.count + downstream.count + 1
        let impactPct = min(100.0, (Double(impactedCount) / Double(totalNodes)) * 100.0)

        let riskLevel: String
        if impactPct >= 66.0 {
            riskLevel = "Critical (Tier-0 Core Failure)"
        } else if impactPct >= 33.0 {
            riskLevel = "High (Cross-Service Degradation)"
        } else {
            riskLevel = "Moderate (Isolated Component)"
        }

        return BlastRadiusReport(
            originNodeId: target.id,
            originNodeName: target.name,
            affectedUpstreamNodes: Array(upstream).sorted(),
            affectedDownstreamNodes: Array(downstream).sorted(),
            totalImpactPercentage: impactPct,
            criticalPathRisk: riskLevel
        )
    }

    /// Synthesizes executable Chaos Mesh Kubernetes YAML manifest and rollback runbook
    public func generateChaosExperiment(
        type: ChaosExperimentType,
        targetNodeName: String,
        durationSec: Int = 60
    ) -> ChaosExperimentSpec {
        lock.lock()
        defer { lock.unlock() }

        let safeName = targetNodeName.lowercased().replacingOccurrences(of: " ", with: "-")
        let experimentId = "chaos-\(safeName)-\(UUID().uuidString.prefix(6).lowercased())"

        let yamlManifest: String
        switch type {
        case .podKill:
            yamlManifest = """
            apiVersion: chaos-mesh.org/v1alpha1
            kind: PodChaos
            metadata:
              name: \(experimentId)
              namespace: default
            spec:
              action: pod-kill
              mode: one
              selector:
                namespaces:
                  - default
                labelSelectors:
                  app.kubernetes.io/name: \(safeName)
              duration: "\(durationSec)s"
              scheduler:
                cron: "@every 5m"
            """
        case .networkLatency:
            yamlManifest = """
            apiVersion: chaos-mesh.org/v1alpha1
            kind: NetworkChaos
            metadata:
              name: \(experimentId)
              namespace: default
            spec:
              action: delay
              mode: all
              selector:
                labelSelectors:
                  app.kubernetes.io/name: \(safeName)
              delay:
                latency: "250ms"
                jitter: "50ms"
              duration: "\(durationSec)s"
            """
        case .packetDrop:
            yamlManifest = """
            apiVersion: chaos-mesh.org/v1alpha1
            kind: NetworkChaos
            metadata:
              name: \(experimentId)
              namespace: default
            spec:
              action: corrupt
              mode: all
              selector:
                labelSelectors:
                  app.kubernetes.io/name: \(safeName)
              corrupt:
                corrupt: "30"
              duration: "\(durationSec)s"
            """
        case .cpuSpike:
            yamlManifest = """
            apiVersion: chaos-mesh.org/v1alpha1
            kind: StressChaos
            metadata:
              name: \(experimentId)
              namespace: default
            spec:
              mode: one
              selector:
                labelSelectors:
                  app.kubernetes.io/name: \(safeName)
              stressors:
                cpu:
                  workers: 4
                  load: 90
              duration: "\(durationSec)s"
            """
        case .databaseFailover:
            yamlManifest = """
            apiVersion: chaos-mesh.org/v1alpha1
            kind: PodChaos
            metadata:
              name: \(experimentId)
              namespace: default
            spec:
              action: pod-failure
              mode: fixed
              value: "1"
              selector:
                labelSelectors:
                  app.kubernetes.io/component: database
                  app.kubernetes.io/instance: \(safeName)
              duration: "\(durationSec)s"
            """
        }

        let rollbackRunbook = """
        # Rollback Runbook for \(experimentId)
        kubectl delete -f \(experimentId).yaml --ignore-not-found=true
        kubectl rollout status deployment/\(safeName) --timeout=60s
        """

        return ChaosExperimentSpec(
            experimentId: experimentId,
            type: type,
            targetNodeName: targetNodeName,
            durationSec: durationSec,
            blastRadiusPct: 35.0,
            yamlManifest: yamlManifest,
            rollbackRunbook: rollbackRunbook
        )
    }
}
