//
// OtelTracingEngine.swift
// KiteKit
//
// Distributed OpenTelemetry Span Waterfall & Tail-Sampling Pipeline Engine (Phase 29).
// Reconstructs W3C traceparent span trees across architecture services, computes Critical Path
// self-time attribution, detects N+1 query cascades, and synthesizes OpenTelemetry Collector
// tail-sampling and PII-redaction YAML pipelines.
//

import Foundation

public struct DistributedTraceSpan: Codable, Sendable, Identifiable, Equatable {
    public var id: String { spanId }
    public let spanId: String
    public let parentSpanId: String?
    public let traceId: String
    public let serviceName: String
    public let operationName: String
    public let durationMs: Double
    public let dbStatementCount: Int
    public let hasError: Bool

    public init(
        spanId: String,
        parentSpanId: String?,
        traceId: String,
        serviceName: String,
        operationName: String,
        durationMs: Double,
        dbStatementCount: Int = 0,
        hasError: Bool = false
    ) {
        self.spanId = spanId
        self.parentSpanId = parentSpanId
        self.traceId = traceId
        self.serviceName = serviceName
        self.operationName = operationName
        self.durationMs = durationMs
        self.dbStatementCount = dbStatementCount
        self.hasError = hasError
    }
}

public struct CriticalPathAttribution: Codable, Sendable, Equatable {
    public let traceId: String
    public let totalDurationMs: Double
    public let bottleneckService: String
    public let bottleneckSelfTimeMs: Double
    public let nPlusOneDetected: Bool
    public let waterfallSummary: [String]

    public init(
        traceId: String,
        totalDurationMs: Double,
        bottleneckService: String,
        bottleneckSelfTimeMs: Double,
        nPlusOneDetected: Bool,
        waterfallSummary: [String]
    ) {
        self.traceId = traceId
        self.totalDurationMs = totalDurationMs
        self.bottleneckService = bottleneckService
        self.bottleneckSelfTimeMs = bottleneckSelfTimeMs
        self.nPlusOneDetected = nPlusOneDetected
        self.waterfallSummary = waterfallSummary
    }
}

public struct OtelCollectorPipelineBundle: Codable, Sendable, Equatable {
    public let clusterEnv: String
    public let tailSampleLatencyThresholdMs: Int
    public let otelCollectorYaml: String

    public init(
        clusterEnv: String,
        tailSampleLatencyThresholdMs: Int,
        otelCollectorYaml: String
    ) {
        self.clusterEnv = clusterEnv
        self.tailSampleLatencyThresholdMs = tailSampleLatencyThresholdMs
        self.otelCollectorYaml = otelCollectorYaml
    }
}

public final class OtelTracingEngine: @unchecked Sendable {
    public static let shared = OtelTracingEngine()

    public static let defaultTraceId = "4bf92f3577b34da6a3ce929d0e0e4736"

    private let lock = NSLock()
    private var spans: [DistributedTraceSpan] = []

    public init() {
        seedSpans()
    }

    private func seedSpans() {
        let tid = Self.defaultTraceId
        spans = [
            DistributedTraceSpan(
                spanId: "span-root-01",
                parentSpanId: nil,
                traceId: tid,
                serviceName: "api-gateway",
                operationName: "POST /v1/orders/checkout",
                durationMs: 210.0,
                dbStatementCount: 0,
                hasError: false
            ),
            DistributedTraceSpan(
                spanId: "span-checkout-02",
                parentSpanId: "span-root-01",
                traceId: tid,
                serviceName: "checkout-api",
                operationName: "GrpcOrderOrchestrator.Execute",
                durationMs: 186.0,
                dbStatementCount: 1,
                hasError: false
            ),
            DistributedTraceSpan(
                spanId: "span-inv-03",
                parentSpanId: "span-checkout-02",
                traceId: tid,
                serviceName: "inventory-service",
                operationName: "ReserveLineItemsLoop",
                durationMs: 164.0,
                dbStatementCount: 0,
                hasError: false
            ),
            DistributedTraceSpan(
                spanId: "span-pg-04",
                parentSpanId: "span-inv-03",
                traceId: tid,
                serviceName: "inventory-postgres",
                operationName: "SELECT stock FOR UPDATE (x24)",
                durationMs: 148.0,
                dbStatementCount: 24,
                hasError: false
            )
        ]
    }

    public func getTraceSpans(traceId: String = OtelTracingEngine.defaultTraceId) -> [DistributedTraceSpan] {
        lock.lock()
        defer { lock.unlock() }
        let matched = spans.filter { $0.traceId == traceId }
        return matched.isEmpty ? spans : matched
    }

    public func analyzeCriticalPath(traceId: String = OtelTracingEngine.defaultTraceId) -> CriticalPathAttribution {
        let traceSpans = getTraceSpans(traceId: traceId)
        let root = traceSpans.first(where: { $0.parentSpanId == nil }) ?? traceSpans[0]

        var maxSelfService = root.serviceName
        var maxSelfMs = 0.0
        var nPlusOne = false
        var summary: [String] = []

        for sp in traceSpans {
            let childrenDuration = traceSpans
                .filter { $0.parentSpanId == sp.spanId }
                .reduce(0.0) { $0 + $1.durationMs }
            let selfTime = max(0.0, ((sp.durationMs - childrenDuration) * 100.0).rounded() / 100.0)
            if selfTime > maxSelfMs {
                maxSelfMs = selfTime
                maxSelfService = sp.serviceName
            }
            if sp.dbStatementCount >= 10 {
                nPlusOne = true
            }
            summary.append("\(sp.serviceName) [\(sp.operationName)]: total=\(sp.durationMs)ms, self=\(selfTime)ms")
        }

        return CriticalPathAttribution(
            traceId: root.traceId,
            totalDurationMs: root.durationMs,
            bottleneckService: maxSelfService,
            bottleneckSelfTimeMs: maxSelfMs,
            nPlusOneDetected: nPlusOne,
            waterfallSummary: summary
        )
    }

    public func synthesizeCollectorConfig(
        clusterEnv: String = "prod-eu-central",
        tailSampleLatencyThresholdMs: Int = 150
    ) -> OtelCollectorPipelineBundle {
        let threshold = max(25, tailSampleLatencyThresholdMs)

        let yaml = """
        receivers:
          otlp:
            protocols:
              grpc:
                endpoint: 0.0.0.0:4317
              http:
                endpoint: 0.0.0.0:4318

        processors:
          attributes/pii_redact:
            actions:
              - key: http.request.header.authorization
                action: delete
              - key: user.email
                action: hash
          tail_sampling:
            decision_wait: 10s
            num_traces: 50000
            policies:
              - name: retain-errors-100pct
                type: status_code
                status_code: { status_codes: [ERROR] }
              - name: retain-high-latency-spans
                type: latency
                latency: { threshold_ms: \(threshold) }
              - name: baseline-probabilistic-5pct
                type: probabilistic
                probabilistic: { sampling_percentage: 5.0 }
          batch:
            send_batch_size: 2048
            timeout: 2s

        exporters:
          otlp/tempo:
            endpoint: tempo-distributor.\(clusterEnv).svc.cluster.local:4317
            tls:
              insecure: false

        service:
          pipelines:
            traces:
              receivers: [otlp]
              processors: [attributes/pii_redact, tail_sampling, batch]
              exporters: [otlp/tempo]
        """

        return OtelCollectorPipelineBundle(
            clusterEnv: clusterEnv,
            tailSampleLatencyThresholdMs: threshold,
            otelCollectorYaml: yaml
        )
    }
}
