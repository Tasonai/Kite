import Foundation

public enum RemediationAction: String, Codable, Sendable {
    case injectCacheLayer = "inject_cache_layer"
    case addRateLimiter = "add_rate_limiter"
    case scaleHorizontal = "scale_horizontal"
    case decoupleCyclicDependency = "decouple_cyclic_dependency"
}

public struct BenchmarkProfile: Codable, Sendable {
    public var targetRps: Double
    public var achievedRps: Double
    public var p99LatencyMs: Double
    public var errorRate: Double
    public var bottleneckNodeId: String?

    public init(
        targetRps: Double,
        achievedRps: Double,
        p99LatencyMs: Double,
        errorRate: Double,
        bottleneckNodeId: String? = nil
    ) {
        self.targetRps = targetRps
        self.achievedRps = achievedRps
        self.p99LatencyMs = p99LatencyMs
        self.errorRate = errorRate
        self.bottleneckNodeId = bottleneckNodeId
    }
}

public struct ArchitecturalRemediationPatch: Codable, Sendable, Identifiable {
    public var id: String
    public var targetNodeId: String
    public var action: RemediationAction
    public var patchDescription: String
    public var diffSnippet: String

    public init(
        id: String = UUID().uuidString,
        targetNodeId: String,
        action: RemediationAction,
        patchDescription: String,
        diffSnippet: String
    ) {
        self.id = id
        self.targetNodeId = targetNodeId
        self.action = action
        self.patchDescription = patchDescription
        self.diffSnippet = diffSnippet
    }
}

public enum SelfHealingEngine {
    public static func diagnoseBottleneck(
        benchmark: BenchmarkProfile,
        frames: [CanvasFrame]
    ) -> [ArchitecturalRemediationPatch] {
        var patches: [ArchitecturalRemediationPatch] = []
        let targetId = benchmark.bottleneckNodeId ?? frames.first?.id.uuidString ?? "primary-service"

        // Latency SLA violation (> 300 ms) -> inject caching layer
        if benchmark.p99LatencyMs > 300.0 {
            patches.append(
                ArchitecturalRemediationPatch(
                    targetNodeId: targetId,
                    action: .injectCacheLayer,
                    patchDescription: "High latency (\(Int(benchmark.p99LatencyMs)) ms) detected. Inject Redis LRU cache layer ahead of database persistence.",
                    diffSnippet: """
                    + [CanvasFrame: Redis Cache Layer (6379)]
                    +   Connection: [API Service] -> [Redis Cache] (Cache-Aside, TTL=300s)
                    +   Connection: [Redis Cache] -> [Database] (On-Miss Fallback)
                    """
                )
            )
        }

        // Error rate SLA violation (> 1%) -> add rate limiter and circuit breaker
        if benchmark.errorRate > 0.01 {
            patches.append(
                ArchitecturalRemediationPatch(
                    targetNodeId: targetId,
                    action: .addRateLimiter,
                    patchDescription: "Elevated error rate (\(String(format: "%.1f", benchmark.errorRate * 100))%) detected. Inject Token Bucket Rate Limiter and Circuit Breaker.",
                    diffSnippet: """
                    + [CanvasFrame: Envoy / Traefik Rate Limiter (8080)]
                    +   Policy: 500 RPS Token Bucket with burst capacity 1000
                    +   Circuit Breaker: Trip on 5 consecutive 5xx errors (cooldown 15s)
                    """
                )
            )
        }

        // Throughput deficit (> 20% below target) -> horizontal scaling
        if benchmark.achievedRps < (benchmark.targetRps * 0.8) {
            patches.append(
                ArchitecturalRemediationPatch(
                    targetNodeId: targetId,
                    action: .scaleHorizontal,
                    patchDescription: "Throughput shortfall (\(Int(benchmark.achievedRps)) / \(Int(benchmark.targetRps)) RPS). Scale cluster replicas from 1 to 3 with round-robin load balancer.",
                    diffSnippet: """
                    ~ services:
                    ~   \(targetId):
                    +     deploy:
                    +       replicas: 3
                    +       resources:
                    +         limits:
                    +           cpus: '1.5'
                    +           memory: 1024M
                    """
                )
            )
        }

        return patches
    }
}
