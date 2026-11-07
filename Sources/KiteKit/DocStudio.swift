import Foundation

public struct ApiDocEndpoint: Identifiable, Sendable, Equatable {
    public var id: String { "\(method) \(path)" }
    public var method: String
    public var path: String
    public var summary: String
    public var endpointDescription: String
    public var requestBodySchema: String
    public var responseSchema: String

    public init(
        method: String,
        path: String,
        summary: String,
        endpointDescription: String,
        requestBodySchema: String,
        responseSchema: String
    ) {
        self.method = method
        self.path = path
        self.summary = summary
        self.endpointDescription = endpointDescription
        self.requestBodySchema = requestBodySchema
        self.responseSchema = responseSchema
    }
}

public enum DocStudio {
    public static var starterEndpoints: [ApiDocEndpoint] {
        [
            ApiDocEndpoint(
                method: "POST",
                path: "/api/v1/generate",
                summary: "Generate vibe architecture and specs",
                endpointDescription: "Sends user prompt and workspace context to Gemini 3.8 model router.",
                requestBodySchema: """
                {
                  "prompt": "Create auth flow with Supabase",
                  "model": "gemini-3.8-flash",
                  "temperature": 0.2
                }
                """,
                responseSchema: """
                {
                  "status": "success",
                  "artifacts": [
                    { "name": "AUTH_SPEC.md", "content": "..." }
                  ],
                  "modelUsed": "gemini-3.8-flash"
                }
                """
            ),
            ApiDocEndpoint(
                method: "GET",
                path: "/api/v1/projects",
                summary: "List user projects and sync state",
                endpointDescription: "Fetches active projects, canvas node counts, and last synchronization timestamp.",
                requestBodySchema: "{}",
                responseSchema: """
                {
                  "projects": [
                    { "id": "proj_01", "name": "Kite Mac", "nodeCount": 42, "updatedAt": "2026-11-07T00:00:00Z" }
                  ]
                }
                """
            ),
            ApiDocEndpoint(
                method: "POST",
                path: "/api/v1/eval",
                summary: "Execute AI regression eval harness",
                endpointDescription: "Validates code quality and safety assertions using Gemini 3.8 test suite.",
                requestBodySchema: """
                {
                  "suiteId": "regression-eval-v1",
                  "model": "gemini-3.8-pro",
                  "runs": 5
                }
                """,
                responseSchema: """
                {
                  "passRate": 1.0,
                  "averageLatencyMs": 380,
                  "checksPassed": 99,
                  "verdict": "PASSED"
                }
                """
            )
        ]
    }

    public static func generateDocMarkdown(title: String, endpoints: [ApiDocEndpoint]) -> String {
        var lines: [String] = [
            "# API DOCUMENTATION & INTERACTIVE PLAYGROUND: \(title.uppercased())",
            "Built for Mintlify, Fumadocs, and Nextra documentation sites.",
            "This specification guides Google DeepMind Antigravity in generating docs and interactive playground components.",
            "",
            "## Recommended Directory Structure",
            "- `docs/guides/getting-started.mdx`: Руководство по быстрому старту",
            "- `docs/guides/authentication.mdx`: Настройка API-ключей и авторизации",
            "- `docs/api-reference/generate.mdx`: Спецификация генерации архитектуры",
            "- `docs/api-reference/projects.mdx`: Управление проектами и воркспейсами",
            "- `docs/api-reference/eval.mdx`: Запуск регрессионного AI-тестирования",
            ""
        ]

        for (idx, ep) in endpoints.enumerated() {
            lines.append("## \(idx + 1). \(ep.method) `\(ep.path)`")
            lines.append("**Summary:** \(ep.summary)")
            lines.append("**Description:** \(ep.endpointDescription)")
            lines.append("")
            lines.append("### Request Body")
            lines.append("```json")
            lines.append(ep.requestBodySchema.trimmingCharacters(in: .whitespacesAndNewlines))
            lines.append("```")
            lines.append("")
            lines.append("### Response Schema")
            lines.append("```json")
            lines.append(ep.responseSchema.trimmingCharacters(in: .whitespacesAndNewlines))
            lines.append("```")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateCurlSnippet(endpoint: ApiDocEndpoint) -> String {
        if endpoint.method == "GET" {
            return """
            curl -X GET "https://api.kite.dev\(endpoint.path)" \\
              -H "Authorization: Bearer $API_KEY" \\
              -H "Accept: application/json"
            """
        } else {
            return """
            curl -X \(endpoint.method) "https://api.kite.dev\(endpoint.path)" \\
              -H "Authorization: Bearer $API_KEY" \\
              -H "Content-Type: application/json" \\
              -d '\(endpoint.requestBodySchema.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: ""))'
            """
        }
    }

    public static func generateTypeScriptSnippet(endpoint: ApiDocEndpoint) -> String {
        let lines: [String] = [
            "// TypeScript / Fetch client snippet",
            "import { KiteClient } from '@kite/sdk';",
            "",
            "const kite = new KiteClient({ apiKey: process.env.KITE_API_KEY! });",
            "",
            "async function callEndpoint() {",
            "  const response = await fetch(`https://api.kite.dev\(endpoint.path)`, {",
            "    method: '\(endpoint.method)',",
            "    headers: {",
            "      'Authorization': `Bearer ${process.env.KITE_API_KEY}`,",
            "      'Content-Type': 'application/json'",
            "    },",
            endpoint.method != "GET" ? "    body: JSON.stringify(\(endpoint.requestBodySchema.trimmingCharacters(in: .whitespacesAndNewlines)))" : nil,
            "  });",
            "",
            "  const data = await response.json();",
            "  return data;",
            "}"
        ].compactMap { $0 }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(endpoints: [ApiDocEndpoint]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY API DOCS DIRECTIVE]",
            "Generate Mintlify / Fumadocs API documentation with interactive request playgrounds.",
            "All endpoints must include curl, TypeScript, and Python snippets with copy-paste readiness:",
            ""
        ]

        for ep in endpoints {
            lines.append("- [\(ep.method)] `\(ep.path)`: \(ep.summary)")
        }

        lines.append("")
        lines.append("Ensure full error codes (400, 401, 404, 429, 500) and response typing in TypeScript.")
        return lines.joined(separator: "\n")
    }
}
