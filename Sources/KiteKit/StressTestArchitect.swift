import Foundation

public struct StressScenario: Identifiable, Sendable, Equatable {
    public var id: String { scenarioName }
    public var scenarioName: String
    public var targetEndpoint: String
    public var virtualUsers: Int
    public var durationSeconds: Int
    public var maxP95LatencyMs: Int

    public init(scenarioName: String, targetEndpoint: String, virtualUsers: Int, durationSeconds: Int, maxP95LatencyMs: Int) {
        self.scenarioName = scenarioName
        self.targetEndpoint = targetEndpoint
        self.virtualUsers = virtualUsers
        self.durationSeconds = durationSeconds
        self.maxP95LatencyMs = maxP95LatencyMs
    }
}

public enum StressTestArchitect {
    public static var starterScenarios: [StressScenario] {
        [
            StressScenario(
                scenarioName: "Поиск по холсту и чтение узлов",
                targetEndpoint: "/api/canvas/query",
                virtualUsers: 50,
                durationSeconds: 60,
                maxP95LatencyMs: 300
            ),
            StressScenario(
                scenarioName: "Генерация архитектурного промпта",
                targetEndpoint: "/api/ai/compile-prompt",
                virtualUsers: 20,
                durationSeconds: 120,
                maxP95LatencyMs: 2500
            ),
            StressScenario(
                scenarioName: "Проверка liveness и healthz",
                targetEndpoint: "/api/healthz",
                virtualUsers: 100,
                durationSeconds: 30,
                maxP95LatencyMs: 80
            )
        ]
    }

    public static func generateStressMarkdown(title: String, scenarios: [StressScenario]) -> String {
        var lines: [String] = [
            "# STRESS & LOAD TESTING SPECIFICATION: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in designing high-throughput backends.",
            "All endpoints MUST pass these concurrent load criteria without connection exhaustion.",
            ""
        ]

        for (idx, s) in scenarios.enumerated() {
            lines.append("## \(idx + 1). \(s.scenarioName)")
            lines.append("- Endpoint: `\(s.targetEndpoint)`")
            lines.append("- Virtual Users (VUs): \(s.virtualUsers)")
            lines.append("- Duration: \(s.durationSeconds) seconds")
            lines.append("- Max P95 Latency: \(s.maxP95LatencyMs) ms")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateK6Script(scenarios: [StressScenario]) -> String {
        var lines: [String] = [
            "// tests/k6_load_test.js",
            "// Executable k6 load testing script for Antigravity-generated deployments",
            "import http from 'k6/http';",
            "import { check, sleep } from 'k6';",
            "",
            "export const options = {",
            "  stages: [",
            "    { duration: '10s', target: 20 },",
            "    { duration: '30s', target: 50 },",
            "    { duration: '10s', target: 0 },",
            "  ],",
            "  thresholds: {",
            "    http_req_failed: ['rate<0.01'],",
            "    http_req_duration: ['p(95)<800'],",
            "  },",
            "};",
            "",
            "export default function () {",
            "  const baseUrl = __ENV.TARGET_URL || 'http://localhost:3000';",
            ""
        ]

        for s in scenarios {
            lines.append("  {")
            lines.append("    const res = http.get(`${baseUrl}\(s.targetEndpoint)`);")
            lines.append("    check(res, {")
            lines.append("      '\(s.scenarioName) status 200': (r) => r.status === 200,")
            lines.append("    });")
            lines.append("  }")
        }

        lines.append("")
        lines.append("  sleep(1);")
        lines.append("}")

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(scenarios: [StressScenario]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY LOAD & STRESS TESTING DIRECTIVE]",
            "Do NOT write un-indexed queries or unpooled database operations that crash under load.",
            "Verify resilience against these high-concurrency benchmarks:",
            ""
        ]

        for s in scenarios {
            lines.append("- [\(s.targetEndpoint)] VUs: \(s.virtualUsers), Max P95: \(s.maxP95LatencyMs)ms")
        }

        lines.append("")
        lines.append("Ensure database connection pooling (pgbouncer/Prisma accelerate) and response caching.")
        return lines.joined(separator: "\n")
    }
}
