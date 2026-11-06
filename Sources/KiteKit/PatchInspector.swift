import Foundation

public struct PatchAuditFinding: Identifiable, Sendable, Equatable {
    public var id: String { "\(line ?? 0)-\(message)" }
    public var severity: Severity
    public var message: String
    public var line: Int?

    public enum Severity: String, Sendable, CaseIterable {
        case critical = "Критично"
        case warning = "Предупреждение"
        case info = "Информация"
    }

    public init(severity: Severity, message: String, line: Int? = nil) {
        self.severity = severity
        self.message = message
        self.line = line
    }
}

public struct PatchReport: Sendable, Equatable {
    public var riskLevel: RiskLevel
    public var findings: [PatchAuditFinding]
    public var fixPrompt: String

    public enum RiskLevel: String, Sendable {
        case low = "Низкий (Безопасно)"
        case medium = "Средний (Требует внимания)"
        case high = "Высокий (Риск поломки)"
        case critical = "Критический (Откатить патч)"
    }

    public init(riskLevel: RiskLevel, findings: [PatchAuditFinding], fixPrompt: String) {
        self.riskLevel = riskLevel
        self.findings = findings
        self.fixPrompt = fixPrompt
    }
}

public enum PatchInspector {
    public static func inspect(patchText: String) -> PatchReport {
        guard !patchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return PatchReport(
                riskLevel: .low,
                findings: [],
                fixPrompt: "Вставьте diff или код для анализа изменений."
            )
        }

        var findings: [PatchAuditFinding] = []
        let lines = patchText.components(separatedBy: .newlines)

        for (idx, line) in lines.enumerated() {
            let lno = idx + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 1. Check for removed interfaces or types
            if trimmed.hasPrefix("-") && (trimmed.contains("interface ") || trimmed.contains("type ") || trimmed.contains("export interface") || trimmed.contains("protocol ")) {
                findings.append(PatchAuditFinding(
                    severity: .critical,
                    message: "Удален интерфейс или тип: '\(trimmed.prefix(40))'",
                    line: lno
                ))
            }

            // 2. Check for leftover console.log / debugger
            if (trimmed.hasPrefix("+") || !trimmed.hasPrefix("-")) && (trimmed.contains("console.log(") || trimmed.contains("debugger;")) {
                findings.append(PatchAuditFinding(
                    severity: .warning,
                    message: "Оставлен отладочный вызов: '\(trimmed.prefix(40))'",
                    line: lno
                ))
            }

            // 3. Check for API keys
            let secrets = SecretShield.scan(text: line)
            if !secrets.isEmpty {
                findings.append(PatchAuditFinding(
                    severity: .critical,
                    message: "Обнаружена утечка API-ключа: \(secrets.first?.kind.rawValue ?? "Token")",
                    line: lno
                ))
            }
        }

        let risk: PatchReport.RiskLevel
        if findings.contains(where: { $0.severity == .critical }) {
            risk = .critical
        } else if findings.contains(where: { $0.severity == .warning }) {
            risk = .medium
        } else {
            risk = .low
        }

        var promptLines: [String] = [
            "[ANTIGRAVITY SURGICAL PATCH FIX]",
            "Исправь следующие регрессии в последнем сгенерированном патче:",
            ""
        ]

        if findings.isEmpty {
            promptLines.append("Патч чист и не содержит критических регрессий.")
        } else {
            for f in findings {
                promptLines.append("- [\(f.severity.rawValue)] \(f.message)")
            }
            promptLines.append("")
            promptLines.append("Восстанови удаленные типы, удали лишние console.log и вынеси секреты в переменные окружения.")
        }

        return PatchReport(
            riskLevel: risk,
            findings: findings,
            fixPrompt: promptLines.joined(separator: "\n")
        )
    }
}
