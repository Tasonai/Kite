import Foundation

public struct TelemetryEvent: Identifiable, Sendable, Equatable {
    public var id: String { name }
    public var name: String
    public var category: String
    public var description: String
    public var properties: [String]
    public var isPIIFree: Bool

    public init(name: String, category: String, description: String, properties: [String], isPIIFree: Bool) {
        self.name = name
        self.category = category
        self.description = description
        self.properties = properties
        self.isPIIFree = isPIIFree
    }
}

public enum TelemetrySpecifier {
    public static var starterEvents: [TelemetryEvent] {
        [
            TelemetryEvent(
                name: "user_signup_completed",
                category: "Authentication",
                description: "Пользователь успешно зарегистрировался в сервисе",
                properties: ["authProvider: 'email' | 'google' | 'github'", "source: string", "durationMs: number"],
                isPIIFree: true
            ),
            TelemetryEvent(
                name: "prompt_compilation_started",
                category: "AI Engine",
                description: "Запуск генерации архитектурного промпта",
                properties: ["templateId: string", "nodeCount: number", "selectedModel: string"],
                isPIIFree: true
            ),
            TelemetryEvent(
                name: "canvas_export_downloaded",
                category: "Canvas",
                description: "Скачивание холста в одном из графических форматов",
                properties: ["format: 'svg' | 'png' | 'pdf' | 'html' | 'mermaid'", "fileSizeKb: number"],
                isPIIFree: true
            ),
            TelemetryEvent(
                name: "api_request_failed",
                category: "Network",
                description: "Сбой клиентского запроса к серверу",
                properties: ["endpoint: string", "statusCode: number", "errorCode: string"],
                isPIIFree: true
            )
        ]
    }

    public static func generateTelemetryMarkdown(title: String, events: [TelemetryEvent]) -> String {
        var lines: [String] = [
            "# TELEMETRY & PRODUCT ANALYTICS SPEC: \(title.uppercased())",
            "This specification defines observable product events for Google DeepMind Antigravity.",
            "All user actions, state transitions, and errors MUST emit structured, PII-free events.",
            ""
        ]

        for (idx, e) in events.enumerated() {
            lines.append("## \(idx + 1). `\(e.name)` [\(e.category)]")
            lines.append("- Description: \(e.description)")
            lines.append("- PII-Free Verified: `\(e.isPIIFree)`")
            lines.append("- Payload Properties:")
            for p in e.properties {
                lines.append("  - `\(p)`")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateTypeScriptClient(events: [TelemetryEvent]) -> String {
        var lines: [String] = [
            "// lib/telemetry.ts",
            "// Type-safe product telemetry client for Antigravity-generated code",
            "",
            "export interface TelemetryEventMap {",
        ]

        for e in events {
            lines.append("  '\(e.name)': {")
            for p in e.properties {
                lines.append("    \(p);")
            }
            lines.append("  };")
        }

        lines.append("}")
        lines.append("")
        lines.append("export function track<E extends keyof TelemetryEventMap>(")
        lines.append("  eventName: E,")
        lines.append("  properties: TelemetryEventMap[E]")
        lines.append("): void {")
        lines.append("  const payload = {")
        lines.append("    event: eventName,")
        lines.append("    properties,")
        lines.append("    timestamp: new Date().toISOString(),")
        lines.append("  };")
        lines.append("  if (process.env.NODE_ENV === 'development') {")
        lines.append("    console.log('[Telemetry]', payload);")
        lines.append("    return;")
        lines.append("  }")
        lines.append("  // Integrate with PostHog / Mixpanel / Google Analytics")
        lines.append("  if (typeof window !== 'undefined' && (window as any).analytics) {")
        lines.append("    (window as any).analytics.track(eventName, properties);")
        lines.append("  }")
        lines.append("}")

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(events: [TelemetryEvent]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY TELEMETRY DIRECTIVE]",
            "Do NOT write silent code without product observability.",
            "Instrument the following business events using `track(name, properties)`:",
            ""
        ]

        for e in events {
            let props = e.properties.joined(separator: ", ")
            lines.append("- [\(e.category)] `\(e.name)`: payload {\(props)}")
        }

        lines.append("")
        lines.append("Never include passwords, emails, raw secret keys, or PII in telemetry payload.")
        return lines.joined(separator: "\n")
    }
}
