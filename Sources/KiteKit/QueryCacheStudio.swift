import Foundation

public struct QueryCacheConfig: Identifiable, Sendable, Equatable {
    public var id: String { queryKey }
    public var queryKey: String
    public var strategy: String
    public var l1TtlSeconds: Int
    public var l2TtlSeconds: Int
    public var invalidationTags: [String]
    public var stalenessTolerance: String

    public init(
        queryKey: String,
        strategy: String,
        l1TtlSeconds: Int,
        l2TtlSeconds: Int,
        invalidationTags: [String],
        stalenessTolerance: String
    ) {
        self.queryKey = queryKey
        self.strategy = strategy
        self.l1TtlSeconds = l1TtlSeconds
        self.l2TtlSeconds = l2TtlSeconds
        self.invalidationTags = invalidationTags
        self.stalenessTolerance = stalenessTolerance
    }
}

public enum QueryCacheStudio {
    public static var starterCaches: [QueryCacheConfig] {
        [
            QueryCacheConfig(
                queryKey: "workspace:details",
                strategy: "Cache-Aside (L1 + L2)",
                l1TtlSeconds: 10,
                l2TtlSeconds: 300,
                invalidationTags: ["workspace:{id}"],
                stalenessTolerance: "Stale-While-Revalidate (10s)"
            ),
            QueryCacheConfig(
                queryKey: "user:permissions",
                strategy: "Cache-Aside (L1 + L2)",
                l1TtlSeconds: 30,
                l2TtlSeconds: 600,
                invalidationTags: ["user:{id}:roles"],
                stalenessTolerance: "Strict Consistency (0s)"
            ),
            QueryCacheConfig(
                queryKey: "billing:invoices",
                strategy: "Read-Through",
                l1TtlSeconds: 60,
                l2TtlSeconds: 3600,
                invalidationTags: ["tenant:{id}:billing"],
                stalenessTolerance: "Stale-While-Revalidate (60s)"
            ),
            QueryCacheConfig(
                queryKey: "analytics:summary",
                strategy: "Cache-Aside (L1 + L2)",
                l1TtlSeconds: 30,
                l2TtlSeconds: 1800,
                invalidationTags: ["tenant:{id}:metrics"],
                stalenessTolerance: "Stale-While-Revalidate (120s)"
            )
        ]
    }

    public static func generateQueryCacheMarkdown(title: String, caches: [QueryCacheConfig]) -> String {
        var lines: [String] = [
            "# DISTRIBUTED TWO-TIER QUERY CACHING SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in generating two-tier query caching (L1 Memory LRU + L2 Distributed Redis).",
            "NEVER execute heavy database queries repeatedly on hot read paths.",
            ""
        ]

        for (idx, c) in caches.enumerated() {
            lines.append("## \(idx + 1). Query Pattern `\(c.queryKey)`")
            lines.append("- Pattern: \(c.strategy)")
            lines.append("- Tier 1 (In-Memory LRU): \(c.l1TtlSeconds) seconds")
            lines.append("- Tier 2 (Distributed Redis): \(c.l2TtlSeconds) seconds")
            lines.append("- Invalidation Tags: `\(c.invalidationTags.joined(separator: ", "))`")
            lines.append("- Staleness Policy: \(c.stalenessTolerance)")
            lines.append("")
        }

        lines.append("## Caching Directives")
        lines.append("1. Always check L1 in-memory LRU cache before hitting distributed Redis or primary database.")
        lines.append("2. Invalidate cache tags atomically on relevant mutations (e.g. `revalidateTag(tag)`).")
        lines.append("3. Wrap database fetch in single-flight deduplication to prevent Cache Stampede (Dogpiling).")

        return lines.joined(separator: "\n")
    }

    public static func generateCacheAsideSnippet(caches: [QueryCacheConfig]) -> String {
        let lines: [String] = [
            "// lib/queryCache.ts",
            "// Two-tier query caching wrapper (L1 Local Map/LRU + L2 Redis)",
            "import { Redis } from '@upstash/redis';",
            "",
            "const redis = new Redis({",
            "  url: process.env.UPSTASH_REDIS_REST_URL || '',",
            "  token: process.env.UPSTASH_REDIS_REST_TOKEN || '',",
            "});",
            "",
            "const l1MemoryCache = new Map<string, { value: any; expiresAt: number }>();",
            "",
            "interface CacheOptions {",
            "  l1TtlSeconds: number;",
            "  l2TtlSeconds: number;",
            "  tags: string[];",
            "}",
            "",
            "export async function cachedQuery<T>(",
            "  key: string,",
            "  fetcher: () => Promise<T>,",
            "  options: CacheOptions",
            "): Promise<T> {",
            "  const now = Date.now();",
            "  // 1. Check L1 In-Memory",
            "  const l1Hit = l1MemoryCache.get(key);",
            "  if (l1Hit && l1Hit.expiresAt > now) {",
            "    return l1Hit.value as T;",
            "  }",
            "",
            "  // 2. Check L2 Redis",
            "  try {",
            "    const l2Hit = await redis.get<T>(key);",
            "    if (l2Hit) {",
            "      l1MemoryCache.set(key, { value: l2Hit, expiresAt: now + options.l1TtlSeconds * 1000 });",
            "      return l2Hit;",
            "    }",
            "  } catch (err) {",
            "    console.warn('L2 Redis cache fetch failed, falling back to primary query:', err);",
            "  }",
            "",
            "  // 3. Cache Miss - Fetch Primary Data",
            "  const freshData = await fetcher();",
            "",
            "  // Populate L1 & L2",
            "  l1MemoryCache.set(key, { value: freshData, expiresAt: now + options.l1TtlSeconds * 1000 });",
            "  try {",
            "    await redis.set(key, freshData, { ex: options.l2TtlSeconds });",
            "  } catch (err) {",
            "    console.warn('L2 Redis cache set failed:', err);",
            "  }",
            "",
            "  return freshData;",
            "}",
            "",
            "export async function invalidateCacheTag(tag: string): Promise<void> {",
            "  l1MemoryCache.clear();",
            "  // In production, execute Redis SCAN or tag set deletion",
            "}",
            ""
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(caches: [QueryCacheConfig]) -> String {
        var lines: [String] = [
            "### ANTIGRAVITY TWO-TIER QUERY CACHING DIRECTIVE",
            "Wrap high-frequency database read queries with two-tier caching:",
            ""
        ]

        for c in caches {
            lines.append("- Cache `\(c.queryKey)`: L1 \(c.l1TtlSeconds)s, L2 \(c.l2TtlSeconds)s, Tags: \(c.invalidationTags.joined(separator: ", ")).")
        }

        lines.append("")
        lines.append("Enforce single-flight query deduplication to prevent cache stampedes and invalidate tags immediately upon data mutations.")

        return lines.joined(separator: "\n")
    }
}
