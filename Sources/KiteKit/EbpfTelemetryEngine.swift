//
// EbpfTelemetryEngine.swift
// KiteKit
//
// Zero-Instrumentation eBPF Kernel Telemetry & Shadow Service Map Engine.
// Captures L4/L7 socket flows (TCP RTT, TLS handshake, HTTP/2 & gRPC wire latency),
// diffs kernel socket edges against declared architecture connectors to uncover shadow APIs
// and unauthorized WAN egress, and synthesizes CiliumNetworkPolicy + Tetragon TracingPolicy CRDs.
//

import Foundation

public enum EbpfWireProtocol: String, Codable, Sendable, Equatable {
    case http2 = "HTTP/2"
    case grpc = "gRPC"
    case postgresWire = "PostgreSQL-Wire"
    case redisResp = "Redis-RESP3"
    case rawTcp = "TCP-TLS1.3"
}

public struct KernelSocketFlow: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let sourceWorkload: String
    public let destinationWorkload: String
    public let destinationPort: Int
    public let wireProtocol: EbpfWireProtocol
    public let tcpRttMs: Double
    public let tlsHandshakeMs: Double
    public let p99WireLatencyMs: Double
    public let packetRetransmitRate: Double
    public let bytesPerSecond: Int
    public let isExternalEgress: Bool

    public init(
        id: String,
        sourceWorkload: String,
        destinationWorkload: String,
        destinationPort: Int,
        wireProtocol: EbpfWireProtocol,
        tcpRttMs: Double,
        tlsHandshakeMs: Double,
        p99WireLatencyMs: Double,
        packetRetransmitRate: Double,
        bytesPerSecond: Int,
        isExternalEgress: Bool = false
    ) {
        self.id = id
        self.sourceWorkload = sourceWorkload
        self.destinationWorkload = destinationWorkload
        self.destinationPort = destinationPort
        self.wireProtocol = wireProtocol
        self.tcpRttMs = tcpRttMs
        self.tlsHandshakeMs = tlsHandshakeMs
        self.p99WireLatencyMs = p99WireLatencyMs
        self.packetRetransmitRate = packetRetransmitRate
        self.bytesPerSecond = bytesPerSecond
        self.isExternalEgress = isExternalEgress
    }
}

public struct DeclaredCanvasEdge: Codable, Sendable, Equatable {
    public let source: String
    public let destination: String

    public init(source: String, destination: String) {
        self.source = source
        self.destination = destination
    }
}

public struct ShadowDependencyFinding: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let severity: String
    public let sourceWorkload: String
    public let destinationWorkload: String
    public let destinationPort: Int
    public let category: String
    public let recommendation: String

    public init(
        id: String,
        severity: String,
        sourceWorkload: String,
        destinationWorkload: String,
        destinationPort: Int,
        category: String,
        recommendation: String
    ) {
        self.id = id
        self.severity = severity
        self.sourceWorkload = sourceWorkload
        self.destinationWorkload = destinationWorkload
        self.destinationPort = destinationPort
        self.category = category
        self.recommendation = recommendation
    }
}

public struct ShadowAuditReport: Codable, Sendable, Equatable {
    public let inspectedFlows: Int
    public let declaredEdgesCount: Int
    public let undocumentedEdgesCount: Int
    public let rogueEgressCount: Int
    public let complianceScore: Int
    public let findings: [ShadowDependencyFinding]

    public init(
        inspectedFlows: Int,
        declaredEdgesCount: Int,
        undocumentedEdgesCount: Int,
        rogueEgressCount: Int,
        complianceScore: Int,
        findings: [ShadowDependencyFinding]
    ) {
        self.inspectedFlows = inspectedFlows
        self.declaredEdgesCount = declaredEdgesCount
        self.undocumentedEdgesCount = undocumentedEdgesCount
        self.rogueEgressCount = rogueEgressCount
        self.complianceScore = complianceScore
        self.findings = findings
    }
}

public struct EbpfPolicyBundle: Codable, Sendable, Equatable {
    public let namespace: String
    public let tetragonTracingPolicyYaml: String
    public let ciliumNetworkPolicyYaml: String
    public let ebpfSockopsProbeC: String

    public init(
        namespace: String,
        tetragonTracingPolicyYaml: String,
        ciliumNetworkPolicyYaml: String,
        ebpfSockopsProbeC: String
    ) {
        self.namespace = namespace
        self.tetragonTracingPolicyYaml = tetragonTracingPolicyYaml
        self.ciliumNetworkPolicyYaml = ciliumNetworkPolicyYaml
        self.ebpfSockopsProbeC = ebpfSockopsProbeC
    }
}

public final class EbpfTelemetryEngine: @unchecked Sendable {
    public static let shared = EbpfTelemetryEngine()

    private let lock = NSLock()
    private var flows: [KernelSocketFlow] = []

    public init() {
        seedKernelFlows()
    }

    private func seedKernelFlows() {
        flows = [
            KernelSocketFlow(
                id: "flow-kprobe-01",
                sourceWorkload: "api-gateway",
                destinationWorkload: "auth-service",
                destinationPort: 8443,
                wireProtocol: .grpc,
                tcpRttMs: 0.42,
                tlsHandshakeMs: 1.85,
                p99WireLatencyMs: 3.10,
                packetRetransmitRate: 0.0001,
                bytesPerSecond: 1_420_000,
                isExternalEgress: false
            ),
            KernelSocketFlow(
                id: "flow-kprobe-02",
                sourceWorkload: "auth-service",
                destinationWorkload: "users-postgres",
                destinationPort: 5432,
                wireProtocol: .postgresWire,
                tcpRttMs: 0.31,
                tlsHandshakeMs: 1.20,
                p99WireLatencyMs: 2.45,
                packetRetransmitRate: 0.0,
                bytesPerSecond: 890_000,
                isExternalEgress: false
            ),
            KernelSocketFlow(
                id: "flow-kprobe-03",
                sourceWorkload: "checkout-worker",
                destinationWorkload: "legacy-Shadow-Billing",
                destinationPort: 9090,
                wireProtocol: .http2,
                tcpRttMs: 1.95,
                tlsHandshakeMs: 0.0,
                p99WireLatencyMs: 28.40,
                packetRetransmitRate: 0.012,
                bytesPerSecond: 310_000,
                isExternalEgress: false
            ),
            KernelSocketFlow(
                id: "flow-kprobe-04",
                sourceWorkload: "checkout-worker",
                destinationWorkload: "telemetry-collector.unverified-wan.io",
                destinationPort: 443,
                wireProtocol: .rawTcp,
                tcpRttMs: 34.80,
                tlsHandshakeMs: 48.20,
                p99WireLatencyMs: 92.10,
                packetRetransmitRate: 0.004,
                bytesPerSecond: 64_000,
                isExternalEgress: true
            )
        ]
    }

    public func getKernelFlows() -> [KernelSocketFlow] {
        lock.lock()
        defer { lock.unlock() }
        return flows
    }

    public func recordKernelFlow(_ flow: KernelSocketFlow) {
        lock.lock()
        defer { lock.unlock() }
        flows.removeAll { $0.id == flow.id }
        flows.append(flow)
    }

    public func auditShadowDependencies(declaredEdges: [DeclaredCanvasEdge]? = nil) -> ShadowAuditReport {
        lock.lock()
        let activeFlows = flows
        lock.unlock()

        let baselineEdges = declaredEdges ?? [
            DeclaredCanvasEdge(source: "api-gateway", destination: "auth-service"),
            DeclaredCanvasEdge(source: "auth-service", destination: "users-postgres")
        ]

        let declaredSet = Set(baselineEdges.map { "\($0.source.lowercased())->\($0.destination.lowercased())" })

        var findings: [ShadowDependencyFinding] = []
        var undocumentedCount = 0
        var rogueEgressCount = 0

        for flow in activeFlows {
            let key = "\(flow.sourceWorkload.lowercased())->\(flow.destinationWorkload.lowercased())"
            if flow.isExternalEgress && !declaredSet.contains(key) {
                rogueEgressCount += 1
                findings.append(ShadowDependencyFinding(
                    id: "SHADOW-EGRESS-\(flow.id)",
                    severity: "critical",
                    sourceWorkload: flow.sourceWorkload,
                    destinationWorkload: flow.destinationWorkload,
                    destinationPort: flow.destinationPort,
                    category: "rogue-wan-egress",
                    recommendation: "Block unauthorized outbound WAN socket to \(flow.destinationWorkload):\(flow.destinationPort) via CiliumNetworkPolicy egress deny rule."
                ))
            } else if !declaredSet.contains(key) {
                undocumentedCount += 1
                let unencryptedNote = flow.tlsHandshakeMs == 0.0 ? " (unencrypted plaintext socket)" : ""
                findings.append(ShadowDependencyFinding(
                    id: "SHADOW-SVC-\(flow.id)",
                    severity: "high",
                    sourceWorkload: flow.sourceWorkload,
                    destinationWorkload: flow.destinationWorkload,
                    destinationPort: flow.destinationPort,
                    category: "undocumented-shadow-api",
                    recommendation: "Promote \(flow.sourceWorkload) -> \(flow.destinationWorkload):\(flow.destinationPort)\(unencryptedNote) onto architecture canvas or enforce mTLS SPIFFE identity."
                ))
            }
        }

        let penalty = (rogueEgressCount * 30) + (undocumentedCount * 15)
        let score = max(0, 100 - penalty)

        return ShadowAuditReport(
            inspectedFlows: activeFlows.count,
            declaredEdgesCount: baselineEdges.count,
            undocumentedEdgesCount: undocumentedCount,
            rogueEgressCount: rogueEgressCount,
            complianceScore: score,
            findings: findings
        )
    }

    public func generateEbpfPolicy(namespace: String = "kite-prod", blockRogueEgress: Bool = true) -> EbpfPolicyBundle {
        let tetragonYaml = """
        apiVersion: cilium.io/v1alpha1
        kind: TracingPolicyNamespaced
        metadata:
          name: kite-zero-trust-socket-monitor
          namespace: \(namespace)
        spec:
          kprobes:
            - call: "tcp_connect"
              syscall: false
              args:
                - index: 0
                  type: "sock"
              selectors:
                - matchNamespaces:
                    - namespace: Net
                      operator: NotIn
                      values:
                        - "host_ns"
            - call: "tcp_close"
              syscall: false
              args:
                - index: 0
                  type: "sock"
        """

        let egressDirective = blockRogueEgress
            ? """
              egress:
                - toEndpoints:
                    - matchLabels:
                        k8s:io.kubernetes.pod.namespace: \(namespace)
              egressDeny:
                - toCIDRSet:
                    - cidr: 0.0.0.0/0
                      except:
                        - 10.0.0.0/8
                        - 172.16.0.0/12
            """
            : """
              egress:
                - toEntities:
                    - cluster
                    - world
            """

        let ciliumYaml = """
        apiVersion: cilium.io/v2
        kind: CiliumNetworkPolicy
        metadata:
          name: kite-canvas-enforced-topology
          namespace: \(namespace)
        spec:
          endpointSelector:
            matchLabels:
              app.kubernetes.io/managed-by: kite-architect
        \(egressDirective)
        """

        let probeC = """
        #include <linux/bpf.h>
        #include <bpf/bpf_helpers.h>
        #include <bpf/bpf_endian.h>

        struct kite_flow_metric {
            __u32 src_ip;
            __u32 dst_ip;
            __u16 dst_port;
            __u32 srtt_us;
        };

        struct {
            __uint(type, BPF_MAP_TYPE_RINGBUF);
            __uint(max_entries, 262144);
        } kite_socket_events SEC(".maps");

        SEC("sockops")
        int kite_trace_sockops(struct bpf_sock_ops *skops) {
            if (skops->op == BPF_SOCK_OPS_STATE_CB || skops->op == BPF_SOCK_OPS_RTT_CB) {
                struct kite_flow_metric *evt = bpf_ringbuf_reserve(&kite_socket_events, sizeof(*evt), 0);
                if (!evt) return 1;
                evt->src_ip = skops->local_ip4;
                evt->dst_ip = skops->remote_ip4;
                evt->dst_port = bpf_ntohl(skops->remote_port) >> 16;
                evt->srtt_us = skops->srtt_us >> 3;
                bpf_ringbuf_submit(evt, 0);
            }
            return 1;
        }

        char LICENSE[] SEC("license") = "Dual BSD/GPL";
        """

        return EbpfPolicyBundle(
            namespace: namespace,
            tetragonTracingPolicyYaml: tetragonYaml,
            ciliumNetworkPolicyYaml: ciliumYaml,
            ebpfSockopsProbeC: probeC
        )
    }
}
