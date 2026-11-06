import Foundation

public struct FeatureTokenBudget: Identifiable, Sendable, Equatable {
    public var id: String { featureName }
    public var featureName: String
    public var targetModel: String
    public var maxInputTokens: Int
    public var maxOutputTokens: Int
    public var maxLatencyMs: Int
    public var costPerThousandCalls: String

    public init(featureName: String, targetModel: String, maxInputTokens: Int, maxOutputTokens: Int, maxLatencyMs: Int, costPerThousandCalls: String) {
        self.featureName = featureName
        self.targetModel = targetModel
        self.maxInputTokens = maxInputTokens
        self.maxOutputTokens = maxOutputTokens
        self.maxLatencyMs = maxLatencyMs
        self.costPerThousandCalls = costPerThousandCalls
    }
}

public enum TokenBudgeteer {
    public static var starterBudgets: [FeatureTokenBudget] {
        [
            FeatureTokenBudget(
                featureName: "Инлайн-автодополнение промпта",
                targetModel: "gemini-2.5-flash",
                maxInputTokens: 800,
                maxOutputTokens: 120,
                maxLatencyMs: 400,
                costPerThousandCalls: "$0.04"
            ),
            FeatureTokenBudget(
                featureName: "Генератор полной архитектуры проекта",
                targetModel: "gemini-2.5-pro",
                maxInputTokens: 8000,
                maxOutputTokens: 2000,
                maxLatencyMs: 3200,
                costPerThousandCalls: "$2.50"
            ),
            FeatureTokenBudget(
                featureName: "Аудит безопасности и OWASP сканер",
                targetModel: "gemini-2.5-flash",
                maxInputTokens: 3000,
                maxOutputTokens: 600,
                maxLatencyMs: 1200,
                costPerThousandCalls: "$0.18"
            )
        ]
    }

    public static func generateTokenBudgetMarkdown(title: String, budgets: [FeatureTokenBudget]) -> String {
        var lines: [String] = [
            "# AI TOKEN, LATENCY & COST BUDGET SPEC: \(title.uppercased())",
            "This specification mandates resource constraints for Google DeepMind Antigravity AI calls.",
            "All model interactions MUST stay within declared token and latency budgets.",
            ""
        ]

        for (idx, b) in budgets.enumerated() {
            lines.append("## \(idx + 1). \(b.featureName)")
            lines.append("- Target Model: `\(b.targetModel)`")
            lines.append("- Max Input Tokens: \(b.maxInputTokens)")
            lines.append("- Max Output Tokens: \(b.maxOutputTokens)")
            lines.append("- Max Target Latency: \(b.maxLatencyMs) ms")
            lines.append("- Estimated Cost: \(b.costPerThousandCalls) / 1K calls")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(budgets: [FeatureTokenBudget]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY TOKEN & LATENCY BUDGET DIRECTIVE]",
            "Do NOT use heavy models for lightweight tasks or generate unbounded outputs.",
            "Respect the following resource limits:",
            ""
        ]

        for b in budgets {
            lines.append("- [\(b.featureName)] Model: `\(b.targetModel)`, Max Input: \(b.maxInputTokens), Max Output: \(b.maxOutputTokens), Target Latency: <\(b.maxLatencyMs)ms")
        }

        lines.append("")
        lines.append("Use Gemini 2.5 Flash for sub-second responses and enable prompt caching whenever applicable.")
        return lines.joined(separator: "\n")
    }
}
