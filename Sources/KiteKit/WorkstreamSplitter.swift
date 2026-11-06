import Foundation

public struct Workstream: Identifiable, Sendable, Equatable {
    public var id: String { name }
    public var name: String
    public var subagentRole: String
    public var targetFiles: [String]
    public var dependencies: [String]
    public var directive: String

    public init(name: String, subagentRole: String, targetFiles: [String], dependencies: [String], directive: String) {
        self.name = name
        self.subagentRole = subagentRole
        self.targetFiles = targetFiles
        self.dependencies = dependencies
        self.directive = directive
    }
}

public enum WorkstreamSplitter {
    public static func defaultWorkstreams(title: String) -> [Workstream] {
        [
            Workstream(
                name: "Workstream 1: Design Tokens & UI Skeleton",
                subagentRole: "UI/Frontend Specialist",
                targetFiles: ["src/theme.ts", "src/components/HeaderBar.tsx", "src/components/StatCard.tsx", "src/styles.css"],
                dependencies: [],
                directive: "Реализует верстку дизайн-системы, токенов и базовых компонентов. Не подключает бизнес-логику и стейт."
            ),
            Workstream(
                name: "Workstream 2: Data Schema & Local Mock API",
                subagentRole: "Backend & Data Architect",
                targetFiles: ["src/types/schema.ts", "src/api/mockClient.ts", "prisma/schema.prisma", "seed.sql"],
                dependencies: [],
                directive: "Реализует типизацию сущностей, парсер фикстур и мок-роуты. Не трогает верстку UI-компонентов."
            ),
            Workstream(
                name: "Workstream 3: State Machine & Interaction Flow",
                subagentRole: "State & Logic Engineer",
                targetFiles: ["src/state/useAppStore.ts", "src/state/stateMachine.ts"],
                dependencies: ["Workstream 1", "Workstream 2"],
                directive: "Связывает интерфейс компонентов с данными. Обрабатывает состояния loading, empty, error."
            ),
            Workstream(
                name: "Workstream 4: Acceptance Tests & Verification",
                subagentRole: "QA & Verification Specialist",
                targetFiles: ["tests/acceptance.spec.ts", "features/acceptance.feature"],
                dependencies: ["Workstream 3"],
                directive: "Пишет и запускает автоматические тесты Playwright по утвержденным критериям приемки."
            )
        ]
    }

    public static func generateWorkstreamsMarkdown(title: String, workstreams: [Workstream]) -> String {
        var lines: [String] = [
            "# PARALLEL WORKSTREAMS SPECIFICATION: \(title.uppercased())",
            "This document divides tasks into strictly isolated scopes for parallel AI subagents.",
            "Subagents MUST NOT edit files outside their assigned scope to avoid merge conflicts.",
            ""
        ]

        for (idx, ws) in workstreams.enumerated() {
            lines.append("## \(idx + 1). \(ws.name)")
            lines.append("- Subagent Role: \(ws.subagentRole)")
            lines.append("- Dependencies: \(ws.dependencies.isEmpty ? "None (Ready to dispatch immediately)" : ws.dependencies.joined(separator: ", "))")
            lines.append("- Exclusive Files:")
            for file in ws.targetFiles {
                lines.append("  * `\(file)`")
            }
            lines.append("- Subagent Directive: \(ws.directive)")
            lines.append("")
        }

        lines.append("Execution Strategy: Wave 1 (Workstreams 1 & 2 in parallel) -> Wave 2 (Workstream 3) -> Wave 3 (Workstream 4).")
        return lines.joined(separator: "\n")
    }

    public static func generateAntigravityPrompt(workstreams: [Workstream]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY PARALLEL SUBAGENT DISPATCH DIRECTIVE]",
            "Execute this phase using isolated subagents with non-overlapping file boundaries:",
            ""
        ]

        for ws in workstreams {
            lines.append("TASK [\(ws.name)] -> Role: '\(ws.subagentRole)'")
            lines.append("  Allowed Files: \(ws.targetFiles.joined(separator: ", "))")
            lines.append("  Directive: \(ws.directive)")
            lines.append("")
        }

        lines.append("Strict Boundary Rule: If a subagent touches files assigned to another workstream, fail the subagent.")
        return lines.joined(separator: "\n")
    }
}
