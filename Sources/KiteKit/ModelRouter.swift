import Foundation

public struct ModelRouteRule: Identifiable, Sendable, Equatable {
    public var id: String { taskType }
    public var taskType: String
    public var primaryModel: String
    public var fallbackModel: String
    public var maxTokens: Int
    public var temperature: Double
    public var targetLatencyMs: Int

    public init(
        taskType: String,
        primaryModel: String,
        fallbackModel: String,
        maxTokens: Int,
        temperature: Double,
        targetLatencyMs: Int
    ) {
        self.taskType = taskType
        self.primaryModel = primaryModel
        self.fallbackModel = fallbackModel
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.targetLatencyMs = targetLatencyMs
    }
}

public enum ModelRouter {
    public static var starterRoutes: [ModelRouteRule] {
        [
            ModelRouteRule(
                taskType: "Fast Autocomplete & Micro-edits",
                primaryModel: "gemini-3.8-flash",
                fallbackModel: "gemini-3.5-flash",
                maxTokens: 2048,
                temperature: 0.1,
                targetLatencyMs: 250
            ),
            ModelRouteRule(
                taskType: "Architectural Reasoning & Specs",
                primaryModel: "gemini-3.8-pro",
                fallbackModel: "gemini-3.8-flash",
                maxTokens: 8192,
                temperature: 0.2,
                targetLatencyMs: 800
            ),
            ModelRouteRule(
                taskType: "Deep Audits & Frontier Verification",
                primaryModel: "gemini-3.8-ultra",
                fallbackModel: "gemini-3.8-pro",
                maxTokens: 16384,
                temperature: 0.0,
                targetLatencyMs: 2000
            )
        ]
    }

    public static func generateRoutingMarkdown(title: String, routes: [ModelRouteRule]) -> String {
        var lines: [String] = [
            "# MULTI-MODEL ORCHESTRATION & LLM ROUTER: \(title.uppercased())",
            "Configured for the Google DeepMind Gemini 3.8 model family.",
            "This specification guides Google DeepMind Antigravity in intelligently routing AI calls by task complexity.",
            ""
        ]

        for (idx, r) in routes.enumerated() {
            lines.append("## \(idx + 1). \(r.taskType)")
            lines.append("- Primary Model: `\(r.primaryModel)`")
            lines.append("- Fallback Chain: `\(r.fallbackModel)`")
            lines.append("- Token Budget: \(r.maxTokens) tokens")
            lines.append("- Temperature: \(r.temperature)")
            lines.append("- SLA Target Latency: < \(r.targetLatencyMs)ms")
            lines.append("")
        }

        lines.append("## Gemini 3.8 Selection Principles")
        lines.append("- `gemini-3.8-flash`: Default for high-frequency interactive canvas updates, micro-edits, and token-budget conscious loops.")
        lines.append("- `gemini-3.8-pro`: Complex multi-file planning, state machine synthesis, and full-stack architecture specs.")
        lines.append("- `gemini-3.8-ultra`: Mathematical proofs, deep security auditing, and comprehensive adversarial verification.")

        return lines.joined(separator: "\n")
    }

    public static func generateTypeScriptRouter(routes: [ModelRouteRule]) -> String {
        let lines: [String] = [
            "// lib/modelRouter.ts",
            "// Intelligent LLM Router with Gemini 3.8 fallback chains",
            "import { GoogleGenAI } from '@google/genai';",
            "",
            "export type TaskComplexity = 'fast' | 'reasoning' | 'ultra';",
            "",
            "interface RouteConfig {",
            "  primary: string;",
            "  fallback: string;",
            "  temperature: number;",
            "  maxOutputTokens: number;",
            "}",
            "",
            "const ROUTING_TABLE: Record<TaskComplexity, RouteConfig> = {",
            "  fast: { primary: 'gemini-3.8-flash', fallback: 'gemini-3.5-flash', temperature: 0.1, maxOutputTokens: 2048 },",
            "  reasoning: { primary: 'gemini-3.8-pro', fallback: 'gemini-3.8-flash', temperature: 0.2, maxOutputTokens: 8192 },",
            "  ultra: { primary: 'gemini-3.8-ultra', fallback: 'gemini-3.8-pro', temperature: 0.0, maxOutputTokens: 16384 },",
            "};",
            "",
            "export async function routeGeminiCall(complexity: TaskComplexity, prompt: string) {",
            "  const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY! });",
            "  const config = ROUTING_TABLE[complexity];",
            "",
            "  try {",
            "    const response = await ai.models.generateContent({",
            "      model: config.primary,",
            "      contents: prompt,",
            "      config: { temperature: config.temperature, maxOutputTokens: config.maxOutputTokens }",
            "    });",
            "    return { text: response.text, model: config.primary };",
            "  } catch (error) {",
            "    console.warn(`[Router] Primary model ${config.primary} failed, switching to ${config.fallback}:`, error);",
            "    const fallbackResponse = await ai.models.generateContent({",
            "      model: config.fallback,",
            "      contents: prompt,",
            "      config: { temperature: config.temperature, maxOutputTokens: config.maxOutputTokens }",
            "    });",
            "    return { text: fallbackResponse.text, model: config.fallback };",
            "  }",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(routes: [ModelRouteRule]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY GEMINI 3.8 MODEL ROUTING DIRECTIVE]",
            "Route LLM API requests dynamically based on task type:",
            ""
        ]

        for r in routes {
            lines.append("- [\(r.taskType)]: Use `\(r.primaryModel)` (fallback: `\(r.fallbackModel)`), max tokens: \(r.maxTokens)")
        }

        lines.append("")
        lines.append("Never hardcode a single model globally. Route via lib/modelRouter.ts.")
        return lines.joined(separator: "\n")
    }
}
