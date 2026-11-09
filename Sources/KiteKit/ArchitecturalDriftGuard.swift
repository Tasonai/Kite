import Foundation

public enum ViolationSeverity: String, Codable, Sendable {
    case warning = "warning"
    case error = "error"
}

public struct ArchitectureRule: Codable, Sendable, Identifiable {
    public var id: String { name }
    public var name: String
    public var sourceLayer: String
    public var forbiddenTargets: [String]
    public var severity: ViolationSeverity
    public var description: String

    public init(
        name: String,
        sourceLayer: String,
        forbiddenTargets: [String],
        severity: ViolationSeverity = .error,
        description: String
    ) {
        self.name = name
        self.sourceLayer = sourceLayer
        self.forbiddenTargets = forbiddenTargets
        self.severity = severity
        self.description = description
    }
}

public struct DriftViolation: Codable, Sendable, Identifiable {
    public var id: String
    public var ruleName: String
    public var sourceFile: String
    public var sourceLayer: String
    public var importedModule: String
    public var targetLayer: String
    public var severity: ViolationSeverity
    public var message: String

    public init(
        ruleName: String,
        sourceFile: String,
        sourceLayer: String,
        importedModule: String,
        targetLayer: String,
        severity: ViolationSeverity,
        message: String
    ) {
        self.id = "\(sourceFile)->\(importedModule)"
        self.ruleName = ruleName
        self.sourceFile = sourceFile
        self.sourceLayer = sourceLayer
        self.importedModule = importedModule
        self.targetLayer = targetLayer
        self.severity = severity
        self.message = message
    }
}

public enum ArchitecturalDriftGuard {
    public static var defaultRules: [ArchitectureRule] {
        [
            ArchitectureRule(
                name: "PresentationToDataBypass",
                sourceLayer: "Presentation",
                forbiddenTargets: ["Data", "Persistence", "Storage"],
                severity: .error,
                description: "Presentation layer components must access data via Domain/Services and cannot import database or persistence layers directly."
            ),
            ArchitectureRule(
                name: "DomainReverseDependency",
                sourceLayer: "Domain",
                forbiddenTargets: ["Presentation", "UI", "Infrastructure"],
                severity: .error,
                description: "Domain logic must remain pure and cannot depend on UI, presentation, or external driver infrastructure."
            ),
            ArchitectureRule(
                name: "DataReverseDependency",
                sourceLayer: "Data",
                forbiddenTargets: ["Presentation", "UI"],
                severity: .error,
                description: "Data layer must not hold references or dependencies to presentation views or UI components."
            )
        ]
    }

    public static func inferLayer(filePath: String) -> String {
        let normalized = filePath.lowercased()
        let clean = "/" + normalized.replacingOccurrences(of: "\\", with: "/").trimmingCharacters(in: CharacterSet(charactersIn: "/.")) + "/"

        func matches(_ keywords: [String]) -> Bool {
            for kw in keywords {
                if clean.contains("/\(kw)/") || clean.contains("/\(kw)") || clean.contains("\(kw)/") || normalized == kw || normalized.contains(".\(kw)") {
                    return true
                }
            }
            return false
        }

        if matches(["views", "pages", "ui", "components", "controllers", "viewmodels"]) {
            return "Presentation"
        }
        if matches(["domain", "services", "models", "usecases", "core"]) {
            return "Domain"
        }
        if matches(["data", "repositories", "storage", "persistence", "db", "database"]) {
            return "Data"
        }
        if matches(["infrastructure", "network", "drivers", "gateways"]) {
            return "Infrastructure"
        }
        return "Common"
    }

    public static func extractImports(from sourceCode: String) -> [String] {
        var imports: [String] = []
        let lines = sourceCode.components(separatedBy: .newlines)

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            // Swift: import Module
            if line.hasPrefix("import ") {
                let parts = line.components(separatedBy: .whitespaces)
                if parts.count >= 2 {
                    let mod = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: ";,"))
                    if !mod.isEmpty { imports.append(mod) }
                }
            }
            // TypeScript/JS: import ... from 'module' or require('module')
            else if line.contains("from \"") || line.contains("from '") {
                let quotes = line.components(separatedBy: CharacterSet(charactersIn: "\"'"))
                if quotes.count >= 2 {
                    let mod = quotes[1]
                    if !mod.isEmpty { imports.append(mod) }
                }
            } else if line.contains("require(\"") || line.contains("require('") {
                let quotes = line.components(separatedBy: CharacterSet(charactersIn: "\"'"))
                if quotes.count >= 2 {
                    let mod = quotes[1]
                    if !mod.isEmpty { imports.append(mod) }
                }
            }
            // C#: using Namespace;
            else if line.hasPrefix("using ") && line.hasSuffix(";") {
                let trimmed = line.dropFirst(6).dropLast(1).trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty && !trimmed.contains("=") {
                    imports.append(trimmed)
                }
            }
            // Python: from x import y OR import x
            else if line.hasPrefix("from ") {
                let parts = line.components(separatedBy: .whitespaces)
                if parts.count >= 2 {
                    let mod = parts[1]
                    if !mod.isEmpty { imports.append(mod) }
                }
            } else if line.hasPrefix("import ") {
                let parts = line.components(separatedBy: .whitespaces)
                if parts.count >= 2 {
                    let mod = parts[1].components(separatedBy: ",")[0]
                    if !mod.isEmpty { imports.append(mod) }
                }
            }
        }

        return Array(Set(imports)).sorted()
    }

    public static func evaluate(
        files: [String: String],
        rules: [ArchitectureRule] = defaultRules
    ) -> [DriftViolation] {
        var violations: [DriftViolation] = []

        for (filePath, content) in files {
            let sourceLayer = inferLayer(filePath: filePath)
            if sourceLayer == "Common" { continue }

            let importedModules = extractImports(from: content)

            for module in importedModules {
                let targetLayer = inferLayer(filePath: module)
                if targetLayer == "Common" || targetLayer == sourceLayer { continue }

                for rule in rules where rule.sourceLayer == sourceLayer {
                    if rule.forbiddenTargets.contains(targetLayer) {
                        violations.append(
                            DriftViolation(
                                ruleName: rule.name,
                                sourceFile: filePath,
                                sourceLayer: sourceLayer,
                                importedModule: module,
                                targetLayer: targetLayer,
                                severity: rule.severity,
                                message: "Architecture Drift: [\(sourceLayer)] '\(filePath)' forbidden from importing [\(targetLayer)] '\(module)'. \(rule.description)"
                            )
                        )
                    }
                }
            }
        }

        return violations
    }

    public static func generateMermaidTopology(violations: [DriftViolation] = []) -> String {
        var lines: [String] = [
            "graph TD",
            "    subgraph Presentation [Presentation Layer]",
            "        Views[Views and UI Components]",
            "        Controllers[Controllers and ViewModels]",
            "    end",
            "    subgraph Domain [Domain Layer]",
            "        Services[Application Services]",
            "        Entities[Domain Entities and UseCases]",
            "    end",
            "    subgraph Data [Data Layer]",
            "        Repos[Repositories and Storage]",
            "        Database[Database and Persistence]",
            "    end",
            "    subgraph Infrastructure [Infrastructure Layer]",
            "        Network[Network and Gateways]",
            "        Drivers[External Drivers]",
            "    end",
            "",
            "    %% Permitted architectural flow",
            "    Presentation --> Domain",
            "    Domain --> Repos",
            "    Repos --> Database",
            "    Infrastructure --> Domain"
        ]

        if !violations.isEmpty {
            lines.append("")
            lines.append("    %% Architectural Drift Violations Detected")
            for (_, v) in violations.prefix(5).enumerated() {
                lines.append("    \(v.sourceLayer) -.-|\"VIOLATION: \(v.importedModule)\"| \(v.targetLayer)")
                lines.append("    style \(v.sourceLayer) stroke:#e74c3c,stroke-width:2px")
                lines.append("    style \(v.targetLayer) stroke:#e74c3c,stroke-width:2px")
            }
        }

        return lines.joined(separator: "\n")
    }
}
