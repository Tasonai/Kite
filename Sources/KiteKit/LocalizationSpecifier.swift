import Foundation

public struct LocalizedStringEntry: Identifiable, Sendable, Equatable {
    public var id: String { key }
    public var key: String
    public var namespace: String
    public var ruText: String
    public var enText: String
    public var hasVariables: Bool

    public init(key: String, namespace: String, ruText: String, enText: String, hasVariables: Bool = false) {
        self.key = key
        self.namespace = namespace
        self.ruText = ruText
        self.enText = enText
        self.hasVariables = hasVariables
    }
}

public enum LocalizationSpecifier {
    public static var starterEntries: [LocalizedStringEntry] {
        [
            LocalizedStringEntry(
                key: "common.save",
                namespace: "common",
                ruText: "Сохранить",
                enText: "Save"
            ),
            LocalizedStringEntry(
                key: "common.cancel",
                namespace: "common",
                ruText: "Отмена",
                enText: "Cancel"
            ),
            LocalizedStringEntry(
                key: "canvas.nodes_count",
                namespace: "canvas",
                ruText: "Узлов на холсте: {count}",
                enText: "Nodes on canvas: {count}",
                hasVariables: true
            ),
            LocalizedStringEntry(
                key: "errors.unauthorized",
                namespace: "errors",
                ruText: "Требуется авторизация для доступа к ресурсу",
                enText: "Authentication required to access this resource"
            )
        ]
    }

    public static func generateDictionaryJSON(entries: [LocalizedStringEntry], language: String) -> String {
        var dict: [String: String] = [:]
        for entry in entries {
            dict[entry.key] = language == "ru" ? entry.ruText : entry.enText
        }

        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    public static func generateLocalizationMarkdown(title: String, entries: [LocalizedStringEntry]) -> String {
        var lines: [String] = [
            "# LOCALIZATION (I18N) CATALOG SPEC: \(title.uppercased())",
            "This document defines externalized interface strings for Google DeepMind Antigravity.",
            "NEVER hardcode raw user-visible strings inside JSX, HTML, or SwiftUI views.",
            ""
        ]

        for (idx, e) in entries.enumerated() {
            lines.append("## \(idx + 1). `\(e.key)` [\(e.namespace)]")
            lines.append("- RU: \"\(e.ruText)\"")
            lines.append("- EN: \"\(e.enText)\"")
            lines.append("- Dynamic Interpolation: `\(e.hasVariables)`")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(entries: [LocalizedStringEntry]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY I18N DIRECTIVE]",
            "Do NOT hardcode UI text strings in templates.",
            "Use the translation hook `t(key)` and pull strings from catalog keys:",
            ""
        ]

        for e in entries {
            lines.append("- `\(e.key)` -> RU: \"\(e.ruText)\" / EN: \"\(e.enText)\"")
        }

        lines.append("")
        lines.append("Store all texts in locales/en.json and locales/ru.json.")
        return lines.joined(separator: "\n")
    }
}
