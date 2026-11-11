import AppKit
import SwiftUI
import KiteKit

enum HyperscaleInspectorTab: String, CaseIterable, Identifiable {
    case spatial3D = "3D Страты и glTF"
    case ebpfEdge = "eBPF и WASI PoP"
    case drFinops = "DR и FinOps Carbon"
    case governance = "TLA+, PQC и SLO-Гейт"

    var id: String { rawValue }
}

struct HyperscaleInspectorView: View {
    var onDismiss: (() -> Void)? = nil

    @State private var selectedTab: HyperscaleInspectorTab = .spatial3D
    @State private var snapshot: HyperscaleCockpitSnapshot = HyperscaleCockpitAggregator.shared.captureSnapshot()
    @State private var scene3D: Spatial3DScene = Spatial3DTopologyEngine.shared.getScene()
    @State private var ebpfFlows: [KernelSocketFlow] = EbpfTelemetryEngine.shared.getKernelFlows()
    @State private var edgePops: [EdgePopNode] = WasmEdgeMeshEngine.shared.getGlobalPops()
    @State private var drRegions: [CloudDrRegion] = DisasterRecoveryEngine.shared.getRegions()
    @State private var finopsArbitrage: FinOpsArbitrageReport = FinOpsCarbonEngine.shared.computeArbitrage(allowSpotForStateless: true)
    @State private var formalInvariants: [FormalInvariant] = FormalVerificationEngine.shared.getInvariants()
    @State private var cbomReport: CbomAuditReport = PostQuantumCryptoEngine.shared.auditCbom()
    @State private var sloBudgets: [SloServiceBudget] = SloBurnRateEngine.shared.getBudgets()
    @State private var trustDomains: [FederatedTrustDomain] = FederationCatalogEngine.shared.getTrustDomains()
    @State private var statusBanner: String = "Все 10 движков Milestone 4.0 и 5.0 активны и синхронизированы."

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerBar

            Picker("Раздел инспектора", selection: $selectedTab) {
                ForEach(HyperscaleInspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color.green)
                Text(statusBanner)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .spatial3D:
                        spatial3DPanel
                    case .ebpfEdge:
                        ebpfEdgePanel
                    case .drFinops:
                        drFinopsPanel
                    case .governance:
                        governancePanel
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .frame(minWidth: 720, minHeight: 520)
        .onAppear {
            refreshAll()
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "cube.transparent.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Text("Гиперскейл и 3D")
                        .font(.title2.weight(.bold))
                }
                Text("Инспектор 3D-топологии Z-страт, телеметрии eBPF, сети WASI, FinOps/DR, TLA+ и постквантовой защиты.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                refreshAll()
                statusBanner = "Метрики всех 10 движков обновлены."
            } label: {
                Label("Обновить", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            Button {
                let gltf = Spatial3DTopologyEngine.shared.exportGltfScene()
                copyToPasteboard(gltf.gltfJson)
                statusBanner = "Сцена \(gltf.formatVersion) (\(gltf.nodeCount) узлов) скопирована в буфер обмена."
            } label: {
                Label("glTF 2.0", systemImage: "doc.on.doc")
            }
            .buttonStyle(.borderedProminent)

            if let onDismiss {
                Button("Готово") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var spatial3DPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Label("3D Z-Стратифицированный граф (\(scene3D.strataCount) плоскостей)", systemImage: "layers.3d.top.filled")
                        .font(.headline)
                    Spacer()
                    Button {
                        scene3D = Spatial3DTopologyEngine.shared.computeForceDirectedLayout(iterations: 12)
                        snapshot = HyperscaleCockpitAggregator.shared.captureSnapshot()
                        statusBanner = "Выполнена 3D релаксация пружинно-отталкивающей раскладки (12 итераций)."
                    } label: {
                        Label("Релаксация 3D сил", systemImage: "waveform.path.ecg")
                    }
                    .buttonStyle(.bordered)
                }

                ForEach(scene3D.nodes) { node in
                    HStack(spacing: 12) {
                        Text(node.stratum)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .frame(width: 164, alignment: .leading)

                        Text(node.label)
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        Text(String(format: "(%.1f, %.1f, %.1f)", node.x, node.y, node.z))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(8)
        }
    }

    private var ebpfEdgePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Label("Сокетные потоки ядра eBPF L4/L7 (Теневых API: \(snapshot.shadowApiCount))", systemImage: "network.badge.shield.half.filled")
                            .font(.headline)
                        Spacer()
                        Button {
                            let pol = EbpfTelemetryEngine.shared.generateEbpfPolicy(namespace: "kite-prod", blockRogueEgress: true)
                            copyToPasteboard(pol.ciliumNetworkPolicyYaml)
                            statusBanner = "CiliumNetworkPolicy (Zero-Sidecar eBPF) скопирована в буфер обмена."
                        } label: {
                            Label("Cilium Policy", systemImage: "shield.lefthalf.filled")
                        }
                        .buttonStyle(.bordered)
                    }

                    ForEach(ebpfFlows) { flow in
                        HStack(spacing: 12) {
                            Text("\(flow.sourceWorkload) -> \(flow.destinationWorkload)")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(flow.wireProtocol.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                            Text(String(format: "RTT %.2f ms", flow.tcpRttMs))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Глобальная сеть изолятов WASI Preview 2 (\(snapshot.healthyEdgePopsCount)/\(edgePops.count) PoP)", systemImage: "globe")
                        .font(.headline)

                    ForEach(edgePops) { pop in
                        HStack(spacing: 12) {
                            Text(pop.iataCode)
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .frame(width: 48, alignment: .leading)
                            Text(pop.city)
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "ColdStart %.2f ms", pop.coldStartMs))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    private var drFinopsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Label("Мульти-региональный Active-Active DR", systemImage: "arrow.triangle.swap")
                            .font(.headline)
                        Spacer()
                        Button {
                            let sim = DisasterRecoveryEngine.shared.simulateRegionalBlackout(outageRegionId: "eu-central-1", rpoTargetSec: 1.0, rtoTargetSec: 30.0)
                            statusBanner = String(
                                format: "DR Failover: новый лидер %@ (кворум=%d, RPO=%.2fs, RTO=%.1fs).",
                                sim.promotedPrimaryRegionId,
                                sim.survivorQuorumVotes,
                                sim.achievedRpoSeconds,
                                sim.achievedRtoSeconds
                            )
                        } label: {
                            Label("Симуляция отказа региона", systemImage: "bolt.horizontal.circle")
                        }
                        .buttonStyle(.bordered)
                    }

                    ForEach(drRegions) { reg in
                        HStack(spacing: 12) {
                            Text(reg.regionId)
                                .font(.system(.subheadline, design: .monospaced))
                            Text(reg.role)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "Lag %.1f ms | Voters: %d", reg.replicationLagMs, reg.votingVoters))
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                .padding(8)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("FinOps ARM64/Spot Арбитраж и углеродный планировщик", systemImage: "leaf.fill")
                        .font(.headline)
                    Text(String(
                        format: "Потенциальная экономия: $%.0f/мес (%.1f%%) | Оптимальный зеленый регион: %@",
                        finopsArbitrage.totalMonthlySavingsUsd,
                        finopsArbitrage.savingsPercent,
                        snapshot.optimalGreenRegion
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(8)
            }
        }
    }

    private var governancePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Label("TLA+ Верификация (\(snapshot.formalStatesExplored) состояний) и Постквантовый шифр (\(String(format: "%.0f%%", cbomReport.readinessScorePercent)))", systemImage: "lock.shield.fill")
                            .font(.headline)
                        Spacer()
                        Button {
                            let rot = PostQuantumCryptoEngine.shared.rotateToHybridPqc()
                            refreshAll()
                            statusBanner = "Эпоха \(rot.newEpoch): активированы \(rot.kemSuite) и \(rot.signatureSuite) (100% PQ-Safe)."
                        } label: {
                            Label("Ротация ML-KEM/DSA", systemImage: "key.radiowaves.forward.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    ForEach(formalInvariants) { inv in
                        HStack(spacing: 8) {
                            Text(inv.category.uppercased())
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .clipShape(Capsule())
                            Text(inv.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                    }
                }
                .padding(8)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Label("SLO Error-Budget Gatekeeper и SPIFFE Федерация (\(trustDomains.count) домена)", systemImage: "gauge.with.dots.needle.67percent")
                            .font(.headline)
                        Spacer()
                        Button {
                            let exec = AutoRemediationEngine.shared.executePlaybook(
                                triggerSignal: "ErrorBudgetFastBurn",
                                targetService: "ledger-writer",
                                estimatedBlastRadius: 1,
                                dryRun: false
                            )
                            statusBanner = exec.actionSummary
                        } label: {
                            Label("Авто-откат Canary", systemImage: "arrow.uturn.backward.circle")
                        }
                        .buttonStyle(.bordered)
                    }

                    ForEach(sloBudgets) { b in
                        let gate = SloBurnRateEngine.shared.evaluateReleaseGate(serviceId: b.serviceId)
                        HStack(spacing: 12) {
                            Text(b.serviceId)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: "Budget %.1f%% | 1h %.1fx", b.remainingBudgetPercent, b.burnRate1h))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(gate.verdict)
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundStyle(gate.verdict == "FREEZE_RELEASE" ? Color.red : (gate.verdict == "CANARY_ONLY" ? Color.orange : Color.green))
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    private func refreshAll() {
        snapshot = HyperscaleCockpitAggregator.shared.captureSnapshot()
        scene3D = Spatial3DTopologyEngine.shared.getScene()
        ebpfFlows = EbpfTelemetryEngine.shared.getKernelFlows()
        edgePops = WasmEdgeMeshEngine.shared.getGlobalPops()
        drRegions = DisasterRecoveryEngine.shared.getRegions()
        finopsArbitrage = FinOpsCarbonEngine.shared.computeArbitrage(allowSpotForStateless: true)
        formalInvariants = FormalVerificationEngine.shared.getInvariants()
        cbomReport = PostQuantumCryptoEngine.shared.auditCbom()
        sloBudgets = SloBurnRateEngine.shared.getBudgets()
        trustDomains = FederationCatalogEngine.shared.getTrustDomains()
    }

    private func copyToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
