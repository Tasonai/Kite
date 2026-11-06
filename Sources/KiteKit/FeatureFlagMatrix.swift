import Foundation

public struct FeatureFlag: Identifiable, Sendable, Equatable {
    public var id: String { key }
    public var key: String
    public var title: String
    public var description: String
    public var rolloutPercentage: Int
    public var defaultEnabled: Bool
    public var targetAudience: String

    public init(key: String, title: String, description: String, rolloutPercentage: Int, defaultEnabled: Bool, targetAudience: String) {
        self.key = key
        self.title = title
        self.description = description
        self.rolloutPercentage = rolloutPercentage
        self.defaultEnabled = defaultEnabled
        self.targetAudience = targetAudience
    }
}

public enum FeatureFlagMatrix {
    public static var starterFlags: [FeatureFlag] {
        [
            FeatureFlag(
                key: "ai_smart_autocomplete",
                title: "ИИ-автодополнение промптов",
                description: "Инлайн-подсказки и генерация вариаций запросов на базе Gemini",
                rolloutPercentage: 20,
                defaultEnabled: false,
                targetAudience: "Бета-тестеры с активной подпиской"
            ),
            FeatureFlag(
                key: "canvas_infinite_search",
                title: "Полнотекстовый поиск по холсту",
                description: "Мгновенная подсветка и масштабирование узлов холста по поисковому запросу",
                rolloutPercentage: 100,
                defaultEnabled: true,
                targetAudience: "Все пользователи"
            ),
            FeatureFlag(
                key: "new_checkout_flow_v2",
                title: "Одностраничный чекаут V2",
                description: "Новый процесс оплаты через Stripe Elements без перезагрузки страницы",
                rolloutPercentage: 0,
                defaultEnabled: false,
                targetAudience: "Внутренняя команда QA"
            )
        ]
    }

    public static func generateFeatureFlagsMarkdown(title: String, flags: [FeatureFlag]) -> String {
        var lines: [String] = [
            "# FEATURE FLAG & ROLLOUT SPEC: \(title.uppercased())",
            "This document defines release gating rules for Google DeepMind Antigravity.",
            "All new UI components, heavy API queries, and experimental features MUST be guarded behind flags.",
            ""
        ]

        for (idx, f) in flags.enumerated() {
            lines.append("## \(idx + 1). `\(f.key)` — \(f.title)")
            lines.append("- Description: \(f.description)")
            lines.append("- Default Enabled: `\(f.defaultEnabled)`")
            lines.append("- Rollout: `\(f.rolloutPercentage)%`")
            lines.append("- Target Audience: \(f.targetAudience)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateTypeScriptClient(flags: [FeatureFlag]) -> String {
        var lines: [String] = [
            "// lib/flags.ts",
            "// Type-safe feature flags client for Antigravity-generated code",
            "",
            "export type FeatureFlagKey =",
        ]

        for f in flags {
            lines.append("  | '\(f.key)'")
        }
        lines.append(";")
        lines.append("")
        lines.append("export interface FlagConfig {")
        lines.append("  key: FeatureFlagKey;")
        lines.append("  enabled: boolean;")
        lines.append("  rollout: number;")
        lines.append("  audience: string;")
        lines.append("}")
        lines.append("")
        lines.append("export const FLAG_DEFINITIONS: Record<FeatureFlagKey, FlagConfig> = {")

        for f in flags {
            lines.append("  '\(f.key)': {")
            lines.append("    key: '\(f.key)',")
            lines.append("    enabled: \(f.defaultEnabled),")
            lines.append("    rollout: \(f.rolloutPercentage),")
            lines.append("    audience: '\(f.targetAudience)',")
            lines.append("  },")
        }

        lines.append("};")
        lines.append("")
        lines.append("export function isFeatureEnabled(key: FeatureFlagKey, userId?: string): boolean {")
        lines.append("  const flag = FLAG_DEFINITIONS[key];")
        lines.append("  if (!flag || !flag.enabled) return false;")
        lines.append("  if (flag.rollout >= 100) return true;")
        lines.append("  if (flag.rollout <= 0) return false;")
        lines.append("  if (!userId) return false;")
        lines.append("  // Deterministic hash based on userId and key")
        lines.append("  let hash = 0;")
        lines.append("  const str = `${key}:${userId}`;")
        lines.append("  for (let i = 0; i < str.length; i++) {")
        lines.append("    hash = (hash << 5) - hash + str.charCodeAt(i);")
        lines.append("    hash |= 0;")
        lines.append("  }")
        lines.append("  return Math.abs(hash % 100) < flag.rollout;")
        lines.append("}")

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(flags: [FeatureFlag]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY FEATURE FLAG DIRECTIVE]",
            "Do NOT expose unfinished or experimental capabilities directly to users.",
            "Gate all new features using the typed flag resolver `isFeatureEnabled(key)`:",
            ""
        ]

        for f in flags {
            lines.append("- Flag `\(f.key)` (\(f.title)): Default \(f.defaultEnabled), Rollout \(f.rolloutPercentage)%. Audience: \(f.targetAudience)")
        }

        lines.append("")
        lines.append("Ensure fallback UI or standard flow is rendered when a flag is disabled.")
        return lines.joined(separator: "\n")
    }
}
