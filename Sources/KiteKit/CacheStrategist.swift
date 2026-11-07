import Foundation

public struct CacheRuleConfig: Identifiable, Sendable, Equatable {
    public var id: String { resourcePattern }
    public var resourcePattern: String
    public var strategy: String
    public var maxAgeSeconds: Int
    public var staleWhileRevalidateSeconds: Int
    public var cacheHeader: String
    public var targetLayer: String

    public init(
        resourcePattern: String,
        strategy: String,
        maxAgeSeconds: Int,
        staleWhileRevalidateSeconds: Int,
        cacheHeader: String,
        targetLayer: String
    ) {
        self.resourcePattern = resourcePattern
        self.strategy = strategy
        self.maxAgeSeconds = maxAgeSeconds
        self.staleWhileRevalidateSeconds = staleWhileRevalidateSeconds
        self.cacheHeader = cacheHeader
        self.targetLayer = targetLayer
    }
}

public enum CacheStrategist {
    public static var starterRules: [CacheRuleConfig] {
        [
            CacheRuleConfig(
                resourcePattern: "/static/*, /_next/static/*",
                strategy: "Cache-First (Immutable)",
                maxAgeSeconds: 31536000,
                staleWhileRevalidateSeconds: 0,
                cacheHeader: "public, max-age=31536000, immutable",
                targetLayer: "Browser & Edge CDN"
            ),
            CacheRuleConfig(
                resourcePattern: "/api/v1/projects, /api/v1/stats",
                strategy: "Stale-While-Revalidate",
                maxAgeSeconds: 60,
                staleWhileRevalidateSeconds: 300,
                cacheHeader: "public, s-maxage=60, stale-while-revalidate=300",
                targetLayer: "Edge CDN & Vercel Cache"
            ),
            CacheRuleConfig(
                resourcePattern: "/api/v1/user/*, /api/v1/checkout",
                strategy: "Network-Only (No-Store)",
                maxAgeSeconds: 0,
                staleWhileRevalidateSeconds: 0,
                cacheHeader: "private, no-cache, no-store, must-revalidate",
                targetLayer: "Origin Only (Bypass Cache)"
            )
        ]
    }

    public static func generateCacheMarkdown(title: String, rules: [CacheRuleConfig]) -> String {
        var lines: [String] = [
            "# HTTP, CDN & SERVICE WORKER CACHE STRATEGY: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in configuring cache headers and invalidation tags.",
            "Never send ambiguous Cache-Control headers on mutable APIs. Guard against stale client state.",
            ""
        ]

        for (idx, r) in rules.enumerated() {
            lines.append("## \(idx + 1). Pattern `\(r.resourcePattern)`")
            lines.append("- Strategy: \(r.strategy)")
            lines.append("- Target Layer: \(r.targetLayer)")
            lines.append("- TTL (max-age): \(r.maxAgeSeconds)s, SWR: \(r.staleWhileRevalidateSeconds)s")
            lines.append("- Header:")
            lines.append("```http")
            lines.append("Cache-Control: \(r.cacheHeader)")
            lines.append("```")
            lines.append("")
        }

        lines.append("## Cache Invalidation Principles")
        lines.append("1. Static bundled assets must contain content hashes for safe 1-year immutable caching.")
        lines.append("2. High-throughput read APIs must use Stale-While-Revalidate to eliminate TTFB spikes.")
        lines.append("3. All authenticated mutations must trigger server-side revalidateTag() or revalidatePath().")

        return lines.joined(separator: "\n")
    }

    public static func generateCacheMiddlewareSnippet(rules: [CacheRuleConfig]) -> String {
        let lines: [String] = [
            "// middleware.ts",
            "// Edge-level Cache-Control header injection",
            "import { NextResponse } from 'next/server';",
            "import type { NextRequest } from 'next/server';",
            "",
            "export function middleware(request: NextRequest) {",
            "  const response = NextResponse.next();",
            "  const pathname = request.nextUrl.pathname;",
            "",
            "  if (pathname.startsWith('/_next/static')) {",
            "    response.headers.set('Cache-Control', 'public, max-age=31536000, immutable');",
            "  } else if (pathname.startsWith('/api/v1/user') || pathname.startsWith('/api/v1/auth')) {",
            "    response.headers.set('Cache-Control', 'private, no-cache, no-store, must-revalidate');",
            "  } else if (pathname.startsWith('/api/v1/')) {",
            "    response.headers.set('Cache-Control', 'public, s-maxage=60, stale-while-revalidate=300');",
            "  }",
            "",
            "  return response;",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(rules: [CacheRuleConfig]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY CACHE STRATEGY DIRECTIVE]",
            "Apply explicit Cache-Control headers across all routes and API endpoints:",
            ""
        ]

        for r in rules {
            lines.append("- `\(r.resourcePattern)`: [\(r.strategy)] `\(r.cacheHeader)`")
        }

        lines.append("")
        lines.append("Never omit Cache-Control. Always pair mutable cached routes with revalidateTag() keys.")
        return lines.joined(separator: "\n")
    }
}
