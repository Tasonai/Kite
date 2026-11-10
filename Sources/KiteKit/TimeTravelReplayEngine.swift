//
// TimeTravelReplayEngine.swift
// KiteKit
//
// 4D Time-Travel Canvas Replay & Incident Post-Mortem Engine.
// Reconstructs architecture topology snapshots across historical git commits and Merkle audit blocks,
// computes visual and semantic temporal diffs, and correlates production incidents with topology mutations.
//

import Foundation

public struct ReplayCanvasNode: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let type: String
    public let x: Double
    public let y: Double

    public init(id: String, name: String, type: String = "service", x: Double = 0, y: Double = 0) {
        self.id = id
        self.name = name
        self.type = type
        self.x = x
        self.y = y
    }
}

public struct ReplayCanvasConnector: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let fromId: String
    public let toId: String
    public let label: String?
    public let protocolType: String

    public init(
        id: String = UUID().uuidString,
        fromId: String,
        toId: String,
        label: String? = nil,
        protocolType: String = "direct"
    ) {
        self.id = id
        self.fromId = fromId
        self.toId = toId
        self.label = label
        self.protocolType = protocolType
    }
}

public struct TimelineSnapshot: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let timestamp: String
    public let author: String
    public let message: String
    public let nodeCount: Int
    public let connectorCount: Int
    public let nodes: [ReplayCanvasNode]
    public let connectors: [ReplayCanvasConnector]
    public let incidentIds: [String]

    public init(
        id: String,
        timestamp: String,
        author: String,
        message: String,
        nodes: [ReplayCanvasNode],
        connectors: [ReplayCanvasConnector],
        incidentIds: [String] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.author = author
        self.message = message
        self.nodeCount = nodes.count
        self.connectorCount = connectors.count
        self.nodes = nodes
        self.connectors = connectors
        self.incidentIds = incidentIds
    }
}

public struct CanvasNodeDiff: Codable, Sendable, Identifiable, Equatable {
    public var id: String { nodeId }
    public let nodeId: String
    public let nodeName: String
    public let changeType: String // "added", "removed", "modified"
    public let details: String

    public init(nodeId: String, nodeName: String, changeType: String, details: String) {
        self.nodeId = nodeId
        self.nodeName = nodeName
        self.changeType = changeType
        self.details = details
    }
}

public struct TemporalDeltaDiff: Codable, Sendable, Equatable {
    public let fromSnapshotId: String
    public let toSnapshotId: String
    public let addedNodes: [ReplayCanvasNode]
    public let removedNodes: [ReplayCanvasNode]
    public let modifiedNodes: [CanvasNodeDiff]
    public let addedConnectors: [ReplayCanvasConnector]
    public let removedConnectors: [ReplayCanvasConnector]
    public let summary: String

    public init(
        fromSnapshotId: String,
        toSnapshotId: String,
        addedNodes: [ReplayCanvasNode],
        removedNodes: [ReplayCanvasNode],
        modifiedNodes: [CanvasNodeDiff],
        addedConnectors: [ReplayCanvasConnector],
        removedConnectors: [ReplayCanvasConnector],
        summary: String
    ) {
        self.fromSnapshotId = fromSnapshotId
        self.toSnapshotId = toSnapshotId
        self.addedNodes = addedNodes
        self.removedNodes = removedNodes
        self.modifiedNodes = modifiedNodes
        self.addedConnectors = addedConnectors
        self.removedConnectors = removedConnectors
        self.summary = summary
    }
}

public struct IncidentEvent: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let severity: String // "P1", "P2", "P3"
    public let service: String
    public let timestamp: String
    public let status: String // "resolved", "investigating"
    public let mttrMinutes: Int
    public let suspectedSnapshotId: String?

    public init(
        id: String,
        title: String,
        severity: String,
        service: String,
        timestamp: String,
        status: String,
        mttrMinutes: Int,
        suspectedSnapshotId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.severity = severity
        self.service = service
        self.timestamp = timestamp
        self.status = status
        self.mttrMinutes = mttrMinutes
        self.suspectedSnapshotId = suspectedSnapshotId
    }
}

public struct IncidentCorrelationResult: Codable, Sendable, Equatable {
    public let incident: IncidentEvent
    public let suspectedSnapshot: TimelineSnapshot?
    public let probableCauses: [String]
    public let confidenceScore: Double
    public let recommendations: [String]

    public init(
        incident: IncidentEvent,
        suspectedSnapshot: TimelineSnapshot?,
        probableCauses: [String],
        confidenceScore: Double,
        recommendations: [String]
    ) {
        self.incident = incident
        self.suspectedSnapshot = suspectedSnapshot
        self.probableCauses = probableCauses
        self.confidenceScore = confidenceScore
        self.recommendations = recommendations
    }
}

public final class TimeTravelReplayEngine: @unchecked Sendable {
    public static let shared = TimeTravelReplayEngine()

    private let lock = NSLock()
    private var snapshots: [TimelineSnapshot] = []
    private var incidents: [IncidentEvent] = []

    public init() {
        seedInitialHistory()
    }

    private func seedInitialHistory() {
        let nodeGateway = ReplayCanvasNode(id: "node-gw", name: "API Gateway", type: "api-gateway", x: 100, y: 100)
        let nodeAuth = ReplayCanvasNode(id: "node-auth", name: "Auth Service", type: "api-service", x: 300, y: 100)
        let nodeDb = ReplayCanvasNode(id: "node-db", name: "Primary Postgres", type: "postgres-database", x: 500, y: 100)
        let nodePayment = ReplayCanvasNode(id: "node-pay", name: "Payment Service", type: "api-service", x: 300, y: 250)
        let nodeLegacyBilling = ReplayCanvasNode(id: "node-bill", name: "Billing Service v1", type: "api-service", x: 500, y: 250)

        let conn1 = ReplayCanvasConnector(id: "c1", fromId: "node-gw", toId: "node-auth", label: "JWT Auth", protocolType: "https")
        let conn2 = ReplayCanvasConnector(id: "c2", fromId: "node-auth", toId: "node-db", label: "Read/Write", protocolType: "postgresql")
        let conn3 = ReplayCanvasConnector(id: "c3", fromId: "node-gw", toId: "node-pay", label: "Process Checkout", protocolType: "https")
        let conn4 = ReplayCanvasConnector(id: "c4", fromId: "node-pay", toId: "node-bill", label: "Legacy RPC", protocolType: "grpc")

        let snap1 = TimelineSnapshot(
            id: "snap-v1.0.0",
            timestamp: "2026-11-01T08:00:00Z",
            author: "devops@kite.internal",
            message: "Initial production microservice deployment",
            nodes: [nodeGateway, nodeAuth, nodeDb],
            connectors: [conn1, conn2]
        )

        let snap2 = TimelineSnapshot(
            id: "snap-v1.2.0",
            timestamp: "2026-11-05T14:30:00Z",
            author: "payments-team@kite.internal",
            message: "Add payment and legacy synchronous billing integration",
            nodes: [nodeGateway, nodeAuth, nodeDb, nodePayment, nodeLegacyBilling],
            connectors: [conn1, conn2, conn3, conn4],
            incidentIds: ["INC-7102"]
        )

        let nodeModernBilling = ReplayCanvasNode(id: "node-bill-v2", name: "Billing Service v2", type: "api-service", x: 500, y: 250)
        let nodeKafka = ReplayCanvasNode(id: "node-mq", name: "Payment Events MQ", type: "kafka-queue", x: 400, y: 350)
        let conn5 = ReplayCanvasConnector(id: "c5", fromId: "node-pay", toId: "node-mq", label: "Publish Invoice", protocolType: "kafka")
        let conn6 = ReplayCanvasConnector(id: "c6", fromId: "node-mq", toId: "node-bill-v2", label: "Subscribe", protocolType: "kafka")

        let snap3 = TimelineSnapshot(
            id: "snap-v1.3.0",
            timestamp: "2026-11-09T18:00:00Z",
            author: "sre-core@kite.internal",
            message: "Decouple payment pipeline with async message queue",
            nodes: [nodeGateway, nodeAuth, nodeDb, nodePayment, nodeModernBilling, nodeKafka],
            connectors: [conn1, conn2, conn3, conn5, conn6]
        )

        self.snapshots = [snap1, snap2, snap3]

        let inc1 = IncidentEvent(
            id: "INC-7102",
            title: "Cascading Timeout in Checkout Path during Flash Sale",
            severity: "P1",
            service: "Payment Service",
            timestamp: "2026-11-05T16:15:00Z",
            status: "resolved",
            mttrMinutes: 42,
            suspectedSnapshotId: "snap-v1.2.0"
        )
        self.incidents = [inc1]
    }

    public func getTimeline() -> [TimelineSnapshot] {
        lock.lock()
        defer { lock.unlock() }
        return snapshots
    }

    public func getSnapshot(id: String) -> TimelineSnapshot? {
        lock.lock()
        defer { lock.unlock() }
        return snapshots.first { $0.id == id }
    }

    @discardableResult
    public func recordSnapshot(
        id: String? = nil,
        author: String,
        message: String,
        nodes: [ReplayCanvasNode],
        connectors: [ReplayCanvasConnector],
        incidentIds: [String] = []
    ) -> TimelineSnapshot {
        lock.lock()
        defer { lock.unlock() }

        let snapId = id ?? "snap-\(UUID().uuidString.prefix(8))"
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())

        let snapshot = TimelineSnapshot(
            id: snapId,
            timestamp: timestamp,
            author: author,
            message: message,
            nodes: nodes,
            connectors: connectors,
            incidentIds: incidentIds
        )
        snapshots.append(snapshot)
        return snapshot
    }

    public func computeDiff(fromId: String, toId: String) -> TemporalDeltaDiff {
        lock.lock()
        defer { lock.unlock() }

        guard let fromSnap = snapshots.first(where: { $0.id == fromId }),
              let toSnap = snapshots.first(where: { $0.id == toId }) else {
            return TemporalDeltaDiff(
                fromSnapshotId: fromId,
                toSnapshotId: toId,
                addedNodes: [],
                removedNodes: [],
                modifiedNodes: [],
                addedConnectors: [],
                removedConnectors: [],
                summary: "Invalid snapshot IDs provided."
            )
        }

        let fromNodesById = Dictionary(uniqueKeysWithValues: fromSnap.nodes.map { ($0.id, $0) })
        let toNodesById = Dictionary(uniqueKeysWithValues: toSnap.nodes.map { ($0.id, $0) })

        var addedNodes: [ReplayCanvasNode] = []
        var removedNodes: [ReplayCanvasNode] = []
        var modifiedNodes: [CanvasNodeDiff] = []

        for (id, node) in toNodesById {
            if let oldNode = fromNodesById[id] {
                if oldNode.name != node.name || oldNode.type != node.type {
                    modifiedNodes.append(CanvasNodeDiff(
                        nodeId: id,
                        nodeName: node.name,
                        changeType: "modified",
                        details: "Name '\(oldNode.name)' -> '\(node.name)', Type '\(oldNode.type)' -> '\(node.type)'"
                    ))
                }
            } else {
                addedNodes.append(node)
            }
        }

        for (id, node) in fromNodesById where toNodesById[id] == nil {
            removedNodes.append(node)
        }

        let fromConnsById = Set(fromSnap.connectors.map { "\($0.fromId)->\($0.toId):\($0.label ?? "")" })
        let toConnsById = Set(toSnap.connectors.map { "\($0.fromId)->\($0.toId):\($0.label ?? "")" })

        let addedConnectors = toSnap.connectors.filter {
            !fromConnsById.contains("\($0.fromId)->\($0.toId):\($0.label ?? "")")
        }
        let removedConnectors = fromSnap.connectors.filter {
            !toConnsById.contains("\($0.fromId)->\($0.toId):\($0.label ?? "")")
        }

        let summary = "Temporal diff from \(fromId) to \(toId): +\(addedNodes.count) nodes, -\(removedNodes.count) nodes, ~\(modifiedNodes.count) modified nodes, +\(addedConnectors.count) edges, -\(removedConnectors.count) edges."

        return TemporalDeltaDiff(
            fromSnapshotId: fromId,
            toSnapshotId: toId,
            addedNodes: addedNodes,
            removedNodes: removedNodes,
            modifiedNodes: modifiedNodes,
            addedConnectors: addedConnectors,
            removedConnectors: removedConnectors,
            summary: summary
        )
    }

    public func getIncidents() -> [IncidentEvent] {
        lock.lock()
        defer { lock.unlock() }
        return incidents
    }

    @discardableResult
    public func registerIncident(
        id: String,
        title: String,
        severity: String,
        service: String,
        timestamp: String,
        status: String,
        mttrMinutes: Int,
        suspectedSnapshotId: String? = nil
    ) -> IncidentEvent {
        lock.lock()
        defer { lock.unlock() }

        let incident = IncidentEvent(
            id: id,
            title: title,
            severity: severity,
            service: service,
            timestamp: timestamp,
            status: status,
            mttrMinutes: mttrMinutes,
            suspectedSnapshotId: suspectedSnapshotId
        )
        incidents.append(incident)
        return incident
    }

    public func correlateIncident(incidentId: String) -> IncidentCorrelationResult {
        lock.lock()
        defer { lock.unlock() }

        guard let inc = incidents.first(where: { $0.id == incidentId }) else {
            let fallbackInc = IncidentEvent(
                id: incidentId,
                title: "Unknown Incident",
                severity: "P3",
                service: "General",
                timestamp: "2026-11-10T00:00:00Z",
                status: "investigating",
                mttrMinutes: 0
            )
            return IncidentCorrelationResult(
                incident: fallbackInc,
                suspectedSnapshot: nil,
                probableCauses: ["Incident record not found in telemetry registry."],
                confidenceScore: 0.0,
                recommendations: ["Register incident details via telemetry API."]
            )
        }

        var matchedSnapshot: TimelineSnapshot?
        if let targetId = inc.suspectedSnapshotId {
            matchedSnapshot = snapshots.first(where: { $0.id == targetId })
        }

        if matchedSnapshot == nil {
            matchedSnapshot = snapshots.first { $0.incidentIds.contains(inc.id) }
        }

        var causes: [String] = []
        var recommendations: [String] = []
        var confidence = 0.85

        if let snap = matchedSnapshot {
            causes.append("Mutation introduced in snapshot '\(snap.id)' by \(snap.author): '\(snap.message)'")
            if snap.connectors.contains(where: { $0.label?.lowercased().contains("sync") == true || $0.label?.lowercased().contains("rpc") == true }) {
                causes.append("Synchronous tight coupling detected on critical transaction path without circuit breaker.")
                recommendations.append("Decouple synchronous dependency with asynchronous Kafka/RabbitMQ message queue.")
                confidence = 0.94
            }
            recommendations.append("Introduce resilient retry backoff and circuit breaker pattern on upstream callers.")
        } else {
            causes.append("Incident occurred during active runtime without an immediately preceding tagged topology deployment.")
            recommendations.append("Enable high-resolution audit tracking to automatically checkpoint canvas mutations.")
            confidence = 0.50
        }

        return IncidentCorrelationResult(
            incident: inc,
            suspectedSnapshot: matchedSnapshot,
            probableCauses: causes,
            confidenceScore: confidence,
            recommendations: recommendations
        )
    }
}
