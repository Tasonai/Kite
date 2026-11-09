import Foundation

public enum AgentRole: String, Codable, Sendable, CaseIterable, Identifiable {
    case architect = "Architect"
    case backendBuilder = "BackendBuilder"
    case frontendBuilder = "FrontendBuilder"
    case qaTester = "QATester"
    case securityAuditor = "SecurityAuditor"
    case siteReliability = "SiteReliability"

    public var id: String { rawValue }

    public var responsibilities: String {
        switch self {
        case .architect: return "Synthesizes data schemas, ERDs, and layer boundaries"
        case .backendBuilder: return "Builds backend controllers, migrations, and APIs"
        case .frontendBuilder: return "Synthesizes accessible UI components and design tokens"
        case .qaTester: return "Generates E2E integration test suites and boundary tests"
        case .securityAuditor: return "Enforces OWASP Top 10, sanitizes secrets, and audits drift"
        case .siteReliability: return "Configures health probes, rate limits, and SLA telemetry"
        }
    }
}

public enum AgentTaskStatus: String, Codable, Sendable {
    case pending = "pending"
    case running = "running"
    case completed = "completed"
    case failed = "failed"
}

public struct AgentTask: Codable, Sendable, Identifiable {
    public var id: String
    public var role: AgentRole
    public var title: String
    public var dependencies: [String]
    public var status: AgentTaskStatus
    public var estimatedDurationSec: Int

    public init(
        id: String,
        role: AgentRole,
        title: String,
        dependencies: [String] = [],
        status: AgentTaskStatus = .pending,
        estimatedDurationSec: Int = 10
    ) {
        self.id = id
        self.role = role
        self.title = title
        self.dependencies = dependencies
        self.status = status
        self.estimatedDurationSec = estimatedDurationSec
    }
}

public struct MultiAgentWave: Codable, Sendable, Identifiable {
    public var id: Int { waveIndex }
    public var waveIndex: Int
    public var tasks: [AgentTask]

    public init(waveIndex: Int, tasks: [AgentTask]) {
        self.waveIndex = waveIndex
        self.tasks = tasks
    }
}

public enum MultiAgentOrchestrator {
    public static func synthesizeDefaultWorkflow(for projectName: String) -> [AgentTask] {
        [
            AgentTask(id: "task-1", role: .architect, title: "Synthesize System Topology and ERD Schema", dependencies: []),
            AgentTask(id: "task-2", role: .securityAuditor, title: "Threat Model & Negative Scope Audit", dependencies: ["task-1"]),
            AgentTask(id: "task-3", role: .backendBuilder, title: "Scaffold Core API and PostgreSQL Migrations", dependencies: ["task-1"]),
            AgentTask(id: "task-4", role: .frontendBuilder, title: "Synthesize Responsive Design Token UI", dependencies: ["task-1"]),
            AgentTask(id: "task-5", role: .qaTester, title: "Generate Playwright E2E Integration Suite", dependencies: ["task-3", "task-4"]),
            AgentTask(id: "task-6", role: .siteReliability, title: "Configure Prometheus Telemetry and Docker Compose", dependencies: ["task-3", "task-5"])
        ]
    }

    public static func partitionIntoWaves(tasks: [AgentTask]) -> [MultiAgentWave] {
        var completed = Set<String>()
        var remaining = tasks
        var waves: [MultiAgentWave] = []
        var waveIdx = 1

        while !remaining.isEmpty {
            let readyTasks = remaining.filter { task in
                task.dependencies.allSatisfy { completed.contains($0) }
            }

            if readyTasks.isEmpty {
                // Circular dependency fallback: take remaining in order
                waves.append(MultiAgentWave(waveIndex: waveIdx, tasks: remaining))
                break
            }

            waves.append(MultiAgentWave(waveIndex: waveIdx, tasks: readyTasks))
            let readyIds = Set(readyTasks.map(\.id))
            for t in readyTasks {
                completed.insert(t.id)
            }
            remaining.removeAll(where: { readyIds.contains($0.id) })
            waveIdx += 1
        }

        return waves
    }
}
