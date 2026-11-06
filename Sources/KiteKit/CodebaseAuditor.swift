import Foundation

public struct AuditFinding: Identifiable, Sendable {
    public var id: String
    public var file: String
    public var line: Int
    public var issueType: IssueType
    public var description: String

    public enum IssueType: String, Sendable {
        case leftoverLog = "Оставленный отладочный лог"
        case emojiSlop = "Недопустимый эмодзи"
        case todoLeftover = "Незавершенный TODO/FIXME"
        case missingSpec = "Отсутствует спецификация"
    }

    public init(id: String = UUID().uuidString, file: String, line: Int, issueType: IssueType, description: String) {
        self.id = id
        self.file = file
        self.line = line
        self.issueType = issueType
        self.description = description
    }
}

public struct CodebaseAuditReport: Sendable {
    public var directory: URL
    public var totalFiles: Int
    public var totalLines: Int
    public var findings: [AuditFinding]
    public var score: Int
    public var polishPrompt: String

    public init(directory: URL, totalFiles: Int, totalLines: Int, findings: [AuditFinding], score: Int, polishPrompt: String) {
        self.directory = directory
        self.totalFiles = totalFiles
        self.totalLines = totalLines
        self.findings = findings
        self.score = score
        self.polishPrompt = polishPrompt
    }
}

public enum CodebaseAuditor {
    public static func audit(directory: URL) -> CodebaseAuditReport {
        let fm = FileManager.default
        var totalFiles = 0
        var totalLines = 0
        var findings: [AuditFinding] = []

        guard let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return CodebaseAuditReport(directory: directory, totalFiles: 0, totalLines: 0, findings: [], score: 0, polishPrompt: "")
        }

        let relevantExts: Set<String> = ["swift", "ts", "tsx", "js", "jsx", "py", "css", "html", "json", "md"]

        for case let fileURL as URL in enumerator {
            if fileURL.path.contains("node_modules") || fileURL.path.contains(".build") || fileURL.path.contains(".git") {
                continue
            }

            let ext = fileURL.pathExtension.lowercased()
            guard relevantExts.contains(ext) else { continue }

            totalFiles += 1
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: "\n")
            totalLines += lines.count

            let relPath = fileURL.path.replacingOccurrences(of: directory.path + "/", with: "")

            for (idx, line) in lines.enumerated() {
                let lineNum = idx + 1
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // 1. Debugger / console.log
                if (trimmed.contains("console.log(") || trimmed.contains("print(") && !fileURL.path.contains("SelfTest.swift")) && !trimmed.hasPrefix("//") {
                    findings.append(AuditFinding(
                        file: relPath,
                        line: lineNum,
                        issueType: .leftoverLog,
                        description: "Отладочный вывод: \"\(trimmed.prefix(40))\""
                    ))
                }

                // 2. TODO / FIXME
                if trimmed.contains("TODO:") || trimmed.contains("FIXME:") {
                    findings.append(AuditFinding(
                        file: relPath,
                        line: lineNum,
                        issueType: .todoLeftover,
                        description: "Незавершенная пометка: \"\(trimmed.prefix(40))\""
                    ))
                }

                // 3. Emoji audit
                for scalar in line.unicodeScalars {
                    if (0x1F300...0x1F9FF).contains(scalar.value) || (0x2600...0x26FF).contains(scalar.value) {
                        findings.append(AuditFinding(
                            file: relPath,
                            line: lineNum,
                            issueType: .emojiSlop,
                            description: "Обнаружен эмодзи символ в коде"
                        ))
                        break
                    }
                }
            }
        }

        let penalty = min(findings.count * 6, 80)
        let finalScore = max(100 - penalty, 20)

        // Compile Polish Prompt for Antigravity
        let polishPrompt: String
        if findings.isEmpty {
            polishPrompt = "[ANTIGRAVITY AUDIT PASS]\nВсе файлы чисты: отладочные логи, TODO и эмодзи отсутствуют. Проект готов к релизу!"
        } else {
            let issuesList = findings.prefix(8).map { "- \($0.file):\($0.line) (\($0.issueType.rawValue))" }.joined(separator: "\n")
            polishPrompt = """
            [ANTIGRAVITY CLEANUP & POLISH]
            В проекте обнаружены замечания чистоты кода:
            \(issuesList)
            
            СТРОГИЕ ПРАВИЛА ОЧИСТКИ:
            1. Удали неиспользуемые console.log и print.
            2. Устрани пометки TODO/FIXME или заверши реализацию.
            3. Замени все эмодзи на строгие системные иконки или текстовые метки.
            4. Не меняй архитектуру и работающую бизнес-логику.
            """
        }

        return CodebaseAuditReport(
            directory: directory,
            totalFiles: totalFiles,
            totalLines: totalLines,
            findings: findings,
            score: finalScore,
            polishPrompt: polishPrompt
        )
    }
}
