import Foundation

public struct ExperimentConfig: Identifiable, Sendable, Equatable {
    public var id: String { experimentKey }
    public var experimentKey: String
    public var experimentDescription: String
    public var variants: [String]
    public var trafficWeights: [Int]
    public var primaryMetric: String
    public var targetAudience: String

    public init(
        experimentKey: String,
        experimentDescription: String,
        variants: [String],
        trafficWeights: [Int],
        primaryMetric: String,
        targetAudience: String
    ) {
        self.experimentKey = experimentKey
        self.experimentDescription = experimentDescription
        self.variants = variants
        self.trafficWeights = trafficWeights
        self.primaryMetric = primaryMetric
        self.targetAudience = targetAudience
    }
}

public enum ExperimentStudio {
    public static var starterExperiments: [ExperimentConfig] {
        [
            ExperimentConfig(
                experimentKey: "onboarding_flow_v2",
                experimentDescription: "Compare step-by-step wizard vs immediate canvas template drop.",
                variants: ["control_wizard", "instant_canvas"],
                trafficWeights: [50, 50],
                primaryMetric: "First spec export completed within 5 minutes",
                targetAudience: "All newly registered accounts"
            ),
            ExperimentConfig(
                experimentKey: "ai_canvas_autoprompt",
                experimentDescription: "Test real-time architectural gap advisor on canvas drop.",
                variants: ["control_manual", "variant_active_coach"],
                trafficWeights: [50, 50],
                primaryMetric: "Prompt translator engagement rate (QPS)",
                targetAudience: "Active desktop canvas sessions"
            ),
            ExperimentConfig(
                experimentKey: "checkout_pricing_table",
                experimentDescription: "Test annual savings badge vs feature comparison matrix.",
                variants: ["control_annual_badge", "feature_matrix"],
                trafficWeights: [50, 50],
                primaryMetric: "Annual subscription checkout conversion",
                targetAudience: "Users initiating subscription upgrade"
            )
        ]
    }

    public static func generateExperimentMarkdown(title: String, experiments: [ExperimentConfig]) -> String {
        var lines: [String] = [
            "# A/B TESTING & EXPERIMENT BUCKETING SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in deterministic user cohort allocation.",
            "All variant assignments MUST be deterministic (hashed by userId) to avoid variant flicker.",
            ""
        ]

        for (idx, exp) in experiments.enumerated() {
            lines.append("## \(idx + 1). Experiment `\(exp.experimentKey)`")
            lines.append("- Purpose: \(exp.experimentDescription)")
            lines.append("- Target Audience: \(exp.targetAudience)")
            lines.append("- Variants: `\(exp.variants.joined(separator: ", "))`")
            lines.append("- Split Weights: `\(exp.trafficWeights.map { "\($0)%" }.joined(separator: " / "))`")
            lines.append("- Primary Success Metric: \(exp.primaryMetric)")
            lines.append("")
        }

        lines.append("## Experimentation Integrity Rules")
        lines.append("1. Compute cohort variant on the server or in edge middleware to prevent layout shift.")
        lines.append("2. Persist experiment assignment in user cookie or profile metadata.")
        lines.append("3. Emit telemetry event `experiment_assigned` with `experiment_key` and `variant` on first exposure.")

        return lines.joined(separator: "\n")
    }

    public static func generateBucketingClientSnippet(experiments: [ExperimentConfig]) -> String {
        let lines: [String] = [
            "// lib/experiments.ts",
            "// Deterministic user bucketing using SHA-256 modulus",
            "import { createHash } from 'crypto';",
            "",
            "export function getExperimentVariant(experimentKey: string, userId: string, variants: string[]): string {",
            "  const hash = createHash('sha256').update(`${experimentKey}:${userId}`).digest('hex');",
            "  const bucket = parseInt(hash.substring(0, 8), 16) % 100;",
            "  // Equal 50/50 split for 2 variants",
            "  const index = Math.floor((bucket / 100) * variants.length);",
            "  return variants[index] || variants[0];",
            "}",
            "",
            "export function trackExperimentExposure(experimentKey: string, variant: string, userId: string) {",
            "  console.log(`[Experiment] user: ${userId} -> ${experimentKey}:${variant}`);",
            "  // Dispatch to telemetry provider",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(experiments: [ExperimentConfig]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY A/B EXPERIMENTATION DIRECTIVE]",
            "Gate features behind deterministic experiment bucketing:",
            ""
        ]

        for exp in experiments {
            lines.append("- `\(exp.experimentKey)`: variants [\(exp.variants.joined(separator: ", "))], goal: \"\(exp.primaryMetric)\"")
        }

        lines.append("")
        lines.append("Never randomize variant assignments per request. Deterministically hash userId + experimentKey.")
        return lines.joined(separator: "\n")
    }
}
