import Foundation

public struct ScopeConstraint: Identifiable, Sendable, Equatable {
    public var id: String { title }
    public var title: String
    public var category: String
    public var rationale: String

    public init(title: String, category: String, rationale: String) {
        self.title = title
        self.category = category
        self.rationale = rationale
    }
}

public enum NegativeScopeFirewall {
    public static var defaultConstraints: [ScopeConstraint] {
        [
            ScopeConstraint(
                title: "Никаких внешних OAuth-провайдеров на этапе прототипа",
                category: "Аутентификация",
                rationale: "Используйте мок-пользователя или простое локальное состояние, чтобы не тратить кредиты на настройку Google/GitHub OAuth."
            ),
            ScopeConstraint(
                title: "Никаких внешних баз данных в облаке (Supabase/Neon)",
                category: "Данные",
                rationale: "Используйте localStorage, SQLite или JSON-фикстуры, сохраняя быстрый автономный цикл разработки."
            ),
            ScopeConstraint(
                title: "Никаких тяжелых стейт-менеджеров (Redux, MobX)",
                category: "Архитектура",
                rationale: "Достаточно нативного React state/context или легковесного Zustand/Signals."
            ),
            ScopeConstraint(
                title: "Никаких платежных шлюзов (Stripe SDK)",
                category: "Монетизация",
                rationale: "Ограничьтесь мок-окном успешной оплаты без подключения реальных вебхуков."
            ),
            ScopeConstraint(
                title: "Никакого стороннего бэкенда при локальной верстке",
                category: "Инфраструктура",
                rationale: "Используйте встроенный локальный mock-сервер Kite для симуляции ответов."
            )
        ]
    }

    public static func generateManifest(title: String, constraints: [ScopeConstraint]) -> String {
        var lines: [String] = [
            "# OUT OF SCOPE MANIFEST: \(title.uppercased())",
            "This document establishes strict boundaries for Google DeepMind Antigravity.",
            "DO NOT implement, scaffold, or import any of the following items in this wave:",
            ""
        ]

        for (idx, c) in constraints.enumerated() {
            lines.append("### \(idx + 1). [\(c.category)] \(c.title)")
            lines.append("Strict Rule: Under no circumstances should this capability be added now.")
            lines.append("Rationale: \(c.rationale)")
            lines.append("")
        }

        lines.append("Failure condition: If the model creates files or imports packages for these items, the wave is rejected.")
        return lines.joined(separator: "\n")
    }

    public static func generateFirewallPrompt(constraints: [ScopeConstraint]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY SCOPE FIREWALL]",
            "STRICT NEGATIVE BOUNDARIES — DO NOT IMPLEMENT:",
            ""
        ]

        for c in constraints {
            lines.append("- [FORBIDDEN] \(c.title) (\(c.category))")
        }

        lines.append("")
        lines.append("Focus solely on the positive requirements. Reject any urge to add speculative infrastructure.")
        return lines.joined(separator: "\n")
    }
}
