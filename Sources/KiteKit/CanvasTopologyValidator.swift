import Foundation

public enum TopologySeverity: String, Sendable, Codable {
    case critical = "Критично"
    case warning = "Предупреждение"
    case info = "Совет"
}

public struct TopologyNodeDescriptor: Identifiable, Sendable, Equatable {
    public var id: String
    public var title: String
    public var role: String

    public init(id: String, title: String, role: String = "service") {
        self.id = id
        self.title = title
        self.role = role
    }
}

public struct TopologyIssue: Identifiable, Sendable, Equatable, Codable {
    public var id: String
    public var severity: TopologySeverity
    public var title: String
    public var message: String
    public var recommendation: String
    public var involvedNodeIds: [String]

    public init(
        id: String = UUID().uuidString,
        severity: TopologySeverity,
        title: String,
        message: String,
        recommendation: String,
        involvedNodeIds: [String] = []
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.message = message
        self.recommendation = recommendation
        self.involvedNodeIds = involvedNodeIds
    }
}

public struct TopologyReport: Sendable, Equatable {
    public var healthScore: Int
    public var issues: [TopologyIssue]
    public var totalConnections: Int
    public var totalNodes: Int

    public var isSecure: Bool {
        issues.allSatisfy { $0.severity != .critical }
    }

    public init(healthScore: Int, issues: [TopologyIssue], totalConnections: Int, totalNodes: Int) {
        self.healthScore = healthScore
        self.issues = issues
        self.totalConnections = totalConnections
        self.totalNodes = totalNodes
    }
}

public enum CanvasTopologyValidator {
    public static func inferRole(title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("db") || lower.contains("database") || lower.contains("postgres") ||
           lower.contains("redis") || lower.contains("mongo") || lower.contains("sql") || lower.contains("storage") ||
           lower.contains("база") || lower.contains("бд") || lower.contains("хранилище") {
            return "database"
        }
        if lower.contains("ui") || lower.contains("frontend") || lower.contains("client") ||
           lower.contains("mobile") || lower.contains("web") || lower.contains("app") || lower.contains("view") ||
           lower.contains("клиент") || lower.contains("интерфейс") || lower.contains("экран") || lower.contains("состояни") {
            return "client"
        }
        if lower.contains("gateway") || lower.contains("proxy") || lower.contains("ingress") || lower.contains("router") ||
           lower.contains("шлюз") || lower.contains("роутер") {
            return "gateway"
        }
        if lower.contains("queue") || lower.contains("kafka") || lower.contains("bus") || lower.contains("event") ||
           lower.contains("очередь") || lower.contains("событи") {
            return "eventbus"
        }
        return "service"
    }

    public static func validate(
        nodes: [TopologyNodeDescriptor],
        connections: [CanvasConnection]
    ) -> TopologyReport {
        var issues: [TopologyIssue] = []
        let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

        // 1. Direct Client-to-Database trap
        for conn in connections {
            guard let from = nodeMap[conn.fromId], let to = nodeMap[conn.toId] else { continue }
            if from.role == "client" && to.role == "database" {
                issues.append(TopologyIssue(
                    severity: .critical,
                    title: "Прямой доступ клиента к базе данных",
                    message: "Компонент '\(from.title)' обращается напрямую к хранилищу '\(to.title)'.",
                    recommendation: "Добавьте защищенный backend-сервис или API Gateway с обязательной JWT/Session проверкой.",
                    involvedNodeIds: [from.id, to.id]
                ))
            }
        }

        // 2. Missing Rate Limiter on public client endpoints
        for conn in connections {
            guard let from = nodeMap[conn.fromId], let to = nodeMap[conn.toId] else { continue }
            if from.role == "client" && to.role == "service" {
                let lbl = conn.label.lowercased()
                if !lbl.contains("limit") && !lbl.contains("guard") && !lbl.contains("auth") && !lbl.contains("gateway") {
                    issues.append(TopologyIssue(
                        severity: .warning,
                        title: "Отсутствует Rate Limiting на публичном маршруте",
                        message: "Запросы от '\(from.title)' к '\(to.title)' не защищены лимитированием частоты.",
                        recommendation: "Настройте Upstash Redis или API Gateway Rate Limiter для защиты от DDoS.",
                        involvedNodeIds: [from.id, to.id]
                    ))
                }
            }
        }

        // 3. Cyclic Synchronous Dependencies (Deadlock / Cascading Failure Risk)
        var adj: [String: [String]] = [:]
        for conn in connections {
            let pType = conn.label.lowercased()
            // Asynchronous event bus breaks sync cycles
            if !pType.contains("event") && !pType.contains("queue") && !pType.contains("kafka") {
                adj[conn.fromId, default: []].append(conn.toId)
            }
        }

        var visited: Set<String> = []
        var recStack: Set<String> = []
        var cycleNodes: [String] = []

        func dfsCycle(_ u: String) -> Bool {
            visited.insert(u)
            recStack.insert(u)

            for v in adj[u, default: []] {
                if !visited.contains(v) {
                    if dfsCycle(v) { return true }
                } else if recStack.contains(v) {
                    cycleNodes.append(u)
                    cycleNodes.append(v)
                    return true
                }
            }

            recStack.remove(u)
            return false
        }

        for n in nodes {
            if !visited.contains(n.id) {
                if dfsCycle(n.id) {
                    let names = cycleNodes.compactMap { nodeMap[$0]?.title }.joined(separator: " -> ")
                    issues.append(TopologyIssue(
                        severity: .critical,
                        title: "Синхронная циклическая зависимость",
                        message: "Обнаружен цикл синхронных вызовов между сервисами: \(names).",
                        recommendation: "Разорвите цикл, заменив один из синхронных RPC вызовов на асинхронный EventBus или Inngest очередь.",
                        involvedNodeIds: cycleNodes
                    ))
                    break
                }
            }
        }

        // 4. Isolated / Orphaned components (in systems with 3+ components)
        if nodes.count >= 3 {
            var connectedIds = Set<String>()
            for c in connections {
                connectedIds.insert(c.fromId)
                connectedIds.insert(c.toId)
            }
            for n in nodes where !connectedIds.contains(n.id) {
                issues.append(TopologyIssue(
                    severity: .info,
                    title: "Изолированный компонент",
                    message: "Компонент '\(n.title)' не имеет активных связей на холсте.",
                    recommendation: "Соедините компонент с целевым сервисом или удалите, если он не входит в MVP.",
                    involvedNodeIds: [n.id]
                ))
            }
        }

        // Calculate health score: 100 base, -25 per critical, -10 per warning, -5 per info
        var deductions = 0
        for issue in issues {
            switch issue.severity {
            case .critical: deductions += 25
            case .warning: deductions += 10
            case .info: deductions += 5
            }
        }
        let score = max(0, min(100, 100 - deductions))

        return TopologyReport(
            healthScore: score,
            issues: issues,
            totalConnections: connections.count,
            totalNodes: nodes.count
        )
    }

    public static func generateTopologyMarkdown(
        title: String,
        report: TopologyReport
    ) -> String {
        var lines: [String] = [
            "# ARCHITECTURE TOPOLOGY & AUDIT REPORT: \(title.uppercased())",
            "Generated by Kite Architecture Studio for Google DeepMind Antigravity.",
            "",
            "## 1. Executive Summary",
            "- Architecture Health Score: **\(report.healthScore)/100** (\(report.isSecure ? "SECURE TOPOLOGY" : "CRITICAL REMEDIATION REQUIRED"))",
            "- Total Components: \(report.totalNodes)",
            "- Total Protocol Connections: \(report.totalConnections)",
            "- Total Identified Issues: \(report.issues.count)",
            "",
            "## 2. Identified Vulnerabilities & Smells"
        ]

        if report.issues.isEmpty {
            lines.append("No architectural smells detected. All components and protocols adhere to production security standards.")
        } else {
            for (idx, issue) in report.issues.enumerated() {
                lines.append("### \(idx + 1). [\(issue.severity.rawValue.uppercased())] \(issue.title)")
                lines.append("- **Diagnosis**: \(issue.message)")
                lines.append("- **Recommendation**: \(issue.recommendation)")
                lines.append("")
            }
        }

        lines.append("## 3. Directives for Antigravity Vibe-Coding")
        lines.append("1. Never allow direct database access from frontend/client code.")
        lines.append("2. Implement edge rate limiting on all public API endpoints.")
        lines.append("3. Decouple synchronous circular service calls using event queues.")

        return lines.joined(separator: "\n")
    }
}
