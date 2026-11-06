import Foundation

public struct MonorepoPackage: Identifiable, Sendable, Equatable {
    public var id: String { packagePath }
    public var packagePath: String
    public var name: String
    public var packageType: String
    public var dependsOn: [String]

    public init(packagePath: String, name: String, packageType: String, dependsOn: [String]) {
        self.packagePath = packagePath
        self.name = name
        self.packageType = packageType
        self.dependsOn = dependsOn
    }
}

public enum MonorepoArchitect {
    public static var starterPackages: [MonorepoPackage] {
        [
            MonorepoPackage(
                packagePath: "apps/web",
                name: "@workspace/web",
                packageType: "Next.js 15 Web Application",
                dependsOn: ["@workspace/ui", "@workspace/types"]
            ),
            MonorepoPackage(
                packagePath: "apps/api",
                name: "@workspace/api",
                packageType: "Node / Fastify REST API Service",
                dependsOn: ["@workspace/types"]
            ),
            MonorepoPackage(
                packagePath: "packages/ui",
                name: "@workspace/ui",
                packageType: "Shared React / Tailwind Component Library",
                dependsOn: ["@workspace/types"]
            ),
            MonorepoPackage(
                packagePath: "packages/types",
                name: "@workspace/types",
                packageType: "Shared TypeScript Domain Contracts & DTOs",
                dependsOn: []
            )
        ]
    }

    public static func generateTurboJson() -> String {
        let lines: [String] = [
            "{",
            "  \"$schema\": \"https://turbo.build/schema.json\",",
            "  \"ui\": \"tui\",",
            "  \"tasks\": {",
            "    \"build\": {",
            "      \"dependsOn\": [\"^build\"],",
            "      \"outputs\": [\".next/**\", \"!.next/cache/**\", \"dist/**\"]",
            "    },",
            "    \"lint\": {",
            "      \"dependsOn\": [\"^lint\"]",
            "    },",
            "    \"dev\": {",
            "      \"cache\": false,",
            "      \"persistent\": true",
            "    }",
            "  }",
            "}"
        ]
        return lines.joined(separator: "\n")
    }

    public static func generatePnpmWorkspaceYaml() -> String {
        let lines: [String] = [
            "packages:",
            "  - 'apps/*'",
            "  - 'packages/*'"
        ]
        return lines.joined(separator: "\n")
    }

    public static func generateMonorepoMarkdown(title: String, packages: [MonorepoPackage]) -> String {
        var lines: [String] = [
            "# MONOREPO & WORKSPACE ARCHITECTURE SPEC: \(title.uppercased())",
            "This document establishes package boundaries and import rules for Google DeepMind Antigravity.",
            "All cross-package code sharing MUST pass through designated internal packages.",
            ""
        ]

        for (idx, pkg) in packages.enumerated() {
            lines.append("## \(idx + 1). `\(pkg.name)` [\(pkg.packagePath)]")
            lines.append("- Type: \(pkg.packageType)")
            if pkg.dependsOn.isEmpty {
                lines.append("- Dependencies: None (Root Leaf)")
            } else {
                lines.append("- Dependencies: \(pkg.dependsOn.joined(separator: ", "))")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(packages: [MonorepoPackage]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY MONOREPO DIRECTIVE]",
            "Do NOT cross boundary layers without using workspace package aliases.",
            "Respect the following package structure:",
            ""
        ]

        for p in packages {
            let deps = p.dependsOn.isEmpty ? "none" : p.dependsOn.joined(separator: ", ")
            lines.append("- `\(p.name)` at `\(p.packagePath)` (depends on: \(deps))")
        }

        lines.append("")
        lines.append("Never use relative imports across packages (e.g. '../../packages/ui'); use '@workspace/ui'.")
        return lines.joined(separator: "\n")
    }
}
