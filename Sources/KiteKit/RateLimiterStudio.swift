import Foundation

public struct RateLimitRuleConfig: Identifiable, Sendable, Equatable {
    public var id: String { routePattern }
    public var routePattern: String
    public var algorithm: String
    public var limit: Int
    public var windowSeconds: Int
    public var backend: String
    public var actionOnExceed: String

    public init(
        routePattern: String,
        algorithm: String,
        limit: Int,
        windowSeconds: Int,
        backend: String,
        actionOnExceed: String
    ) {
        self.routePattern = routePattern
        self.algorithm = algorithm
        self.limit = limit
        self.windowSeconds = windowSeconds
        self.backend = backend
        self.actionOnExceed = actionOnExceed
    }
}

public enum RateLimiterStudio {
    public static var starterRules: [RateLimitRuleConfig] {
        [
            RateLimitRuleConfig(
                routePattern: "/api/ai/generate",
                algorithm: "Sliding Window Counter",
                limit: 10,
                windowSeconds: 60,
                backend: "Upstash Redis",
                actionOnExceed: "HTTP 429 + Retry-After Header"
            ),
            RateLimitRuleConfig(
                routePattern: "/api/auth/login",
                algorithm: "Token Bucket",
                limit: 5,
                windowSeconds: 300,
                backend: "Upstash Redis",
                actionOnExceed: "HTTP 429 + Exponential Backoff"
            ),
            RateLimitRuleConfig(
                routePattern: "/api/checkout/pay",
                algorithm: "Sliding Window Counter",
                limit: 3,
                windowSeconds: 60,
                backend: "Upstash Redis",
                actionOnExceed: "HTTP 429 + Audit Log Alert"
            ),
            RateLimitRuleConfig(
                routePattern: "/api/public/search",
                algorithm: "Sliding Window Counter",
                limit: 60,
                windowSeconds: 60,
                backend: "Cloudflare KV",
                actionOnExceed: "HTTP 429 Rate Exceeded"
            )
        ]
    }

    public static func generateRateLimitMarkdown(title: String, rules: [RateLimitRuleConfig]) -> String {
        var lines: [String] = [
            "# DISTRIBUTED RATE LIMITING & DDOS DEFENSE SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in generating resilient rate limiting middleware and defense layers.",
            "NEVER expose unthrottled AI generation, authentication, or payment routes to the public internet.",
            ""
        ]

        for (idx, r) in rules.enumerated() {
            lines.append("## \(idx + 1). Route `\(r.routePattern)`")
            lines.append("- Algorithm: \(r.algorithm)")
            lines.append("- Quota: \(r.limit) requests per \(r.windowSeconds) seconds")
            lines.append("- Storage Engine: \(r.backend)")
            lines.append("- Violation Handler: \(r.actionOnExceed)")
            lines.append("")
        }

        lines.append("## Production Enforcement Rules")
        lines.append("1. Extract client identifier via verified IP (`x-forwarded-for`) or authenticated user/organization ID.")
        lines.append("2. Always return standard headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, and `Retry-After` on 429 responses.")
        lines.append("3. Provide graceful fallback to in-memory sliding window when Redis backend encounters network timeout.")

        return lines.joined(separator: "\n")
    }

    public static func generateRateLimitMiddleware(rules: [RateLimitRuleConfig]) -> String {
        let lines: [String] = [
            "// middleware/rateLimiter.ts",
            "// Distributed edge rate limiting powered by Upstash Redis and Sliding Window",
            "import { NextRequest, NextResponse } from 'next/server';",
            "import { Ratelimit } from '@upstash/ratelimit';",
            "import { Redis } from '@upstash/redis';",
            "",
            "const redis = new Redis({",
            "  url: process.env.UPSTASH_REDIS_REST_URL || '',",
            "  token: process.env.UPSTASH_REDIS_REST_TOKEN || '',",
            "});",
            "",
            "const aiLimiter = new Ratelimit({",
            "  redis,",
            "  limiter: Ratelimit.slidingWindow(10, '60 s'),",
            "  analytics: true,",
            "  prefix: '@kite/ratelimit/ai',",
            "});",
            "",
            "const authLimiter = new Ratelimit({",
            "  redis,",
            "  limiter: Ratelimit.tokenBucket(5, '300 s', 5),",
            "  analytics: true,",
            "  prefix: '@kite/ratelimit/auth',",
            "});",
            "",
            "export async function checkRateLimit(req: NextRequest): Promise<NextResponse | null> {",
            "  const ip = req.headers.get('x-forwarded-for')?.split(',')[0].trim() || '127.0.0.1';",
            "  const pathname = req.nextUrl.pathname;",
            "",
            "  let limiter = null;",
            "  if (pathname.startsWith('/api/ai')) {",
            "    limiter = aiLimiter;",
            "  } else if (pathname.startsWith('/api/auth')) {",
            "    limiter = authLimiter;",
            "  }",
            "",
            "  if (!limiter) return null;",
            "",
            "  const { success, limit, remaining, reset } = await limiter.limit(ip);",
            "  if (!success) {",
            "    const retryAfter = Math.max(1, Math.ceil((reset - Date.now()) / 1000));",
            "    return new NextResponse(",
            "      JSON.stringify({ error: 'Too Many Requests', retryAfter }),",
            "      {",
            "        status: 429,",
            "        headers: {",
            "          'Content-Type': 'application/json',",
            "          'X-RateLimit-Limit': limit.toString(),",
            "          'X-RateLimit-Remaining': remaining.toString(),",
            "          'Retry-After': retryAfter.toString(),",
            "        },",
            "      }",
            "    );",
            "  }",
            "",
            "  return null;",
            "}",
            ""
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(rules: [RateLimitRuleConfig]) -> String {
        var lines: [String] = [
            "### ANTIGRAVITY DISTRIBUTED RATE LIMITING DIRECTIVE",
            "Apply production-grade rate limiting across all sensitive and expensive API handlers:",
            ""
        ]

        for r in rules {
            lines.append("- Guard `\(r.routePattern)` with \(r.algorithm) (\(r.limit) req/\(r.windowSeconds)s) using \(r.backend). On breach: \(r.actionOnExceed).")
        }

        lines.append("")
        lines.append("Enforce HTTP 429 status code, RFC 6585 Retry-After header, and fall back to local LRU memory if cache cluster times out.")

        return lines.joined(separator: "\n")
    }
}
