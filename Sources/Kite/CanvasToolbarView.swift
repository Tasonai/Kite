import SwiftUI
import KiteKit

struct CanvasToolbarView: View {
    let totalElementCount: Int
    @Binding var canvasTool: CanvasTool
    @Binding var isConnectingMode: Bool
    let connectingSourceId: String?
    let selectedElementCount: Int
    let lanPeers: [KitePeer]
    @Binding var zoomScale: CGFloat
    let toastMessage: String?
    @Binding var isSimulationActive: Bool

    // Action callbacks
    let onAIAutoLayout: () -> Void
    let onCoArchitect: () -> Void
    let onRepoIngestion: () -> Void
    let onRoadmapHUD: () -> Void

    let onAddFrame: () -> Void
    let onAddSticky: () -> Void
    let onAddNewIdea: () -> Void
    let onOpenReferencePicker: () -> Void
    let onDeployBlueprintPack: (CanvasBlueprintPack) -> Void

    let onGroupSelected: () -> Void
    let onDeleteSelected: () -> Void

    let onSyncPeer: (KitePeer) -> Void

    let onExportSVG: () -> Void
    let onExportPNG: () -> Void
    let onExportPDF: () -> Void
    let onExportHTML: () -> Void
    let onExportMermaid: () -> Void
    let onCopyMermaid: () -> Void
    let onOpenAntigravityPack: () -> Void
    let onOpenErrorDoctor: () -> Void
    let onOpenDataDesigner: () -> Void
    let onOpenAPIContract: () -> Void
    let onOpenStateFlow: () -> Void
    let onOpenSitemap: () -> Void
    let onOpenGitStory: () -> Void
    let onOpenCodebaseAuditor: () -> Void
    let onOpenSeedData: () -> Void
    let onOpenSecretShield: () -> Void
    let onOpenBloatGuard: () -> Void
    let onOpenDeployBlueprint: () -> Void
    let onOpenContextOptimizer: () -> Void
    let onOpenComponentMatrix: () -> Void
    let onOpenAcceptanceCriteria: () -> Void
    let onOpenScopeGuard: () -> Void
    let onOpenWorkstreamSplitter: () -> Void
    let onOpenPatchInspector: () -> Void
    let onOpenFallbackPlanner: () -> Void
    let onOpenRunbook: () -> Void
    let onOpenEvalHarness: () -> Void
    let onOpenFeatureFlagMatrix: () -> Void
    let onOpenTelemetrySpecifier: () -> Void
    let onOpenPerformanceBudget: () -> Void
    let onOpenThreatModeler: () -> Void
    let onOpenMigrationStrategist: () -> Void
    let onOpenLocalizationSpecifier: () -> Void
    let onOpenWebhookSimulator: () -> Void
    let onOpenAccessibilityAuditor: () -> Void
    let onOpenMonorepoArchitect: () -> Void
    let onOpenSEOStudio: () -> Void
    let onOpenSkillSynthesizer: () -> Void
    let onOpenTokenBudgeteer: () -> Void
    let onOpenRealtimeArchitect: () -> Void
    let onOpenJobQueueStrategist: () -> Void
    let onOpenIncidentCommander: () -> Void
    let onOpenVectorStoreSpecifier: () -> Void
    let onOpenComplianceGuardian: () -> Void
    let onOpenMultiTenantArchitect: () -> Void
    let onOpenStressTestArchitect: () -> Void
    let onOpenEmailStudio: () -> Void
    let onOpenDocStudio: () -> Void
    let onOpenIndexOptimizer: () -> Void
    let onOpenModelRouter: () -> Void
    let onOpenStorageGuard: () -> Void
    let onOpenCacheStrategist: () -> Void
    let onOpenRpcContractStudio: () -> Void
    let onOpenExperimentStudio: () -> Void
    let onCopyPNG: () -> Void
    let onOpenMockup: () -> Void

    let onResetZoom: () -> Void
    let onCancelConnecting: () -> Void

    @State private var showPeersPopover = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.split.3x3")
                        .foregroundStyle(Color.accentColor)
                    Text("Холст")
                        .font(.headline)
                        .fixedSize()
                    Text("\(totalElementCount)")
                        .font(.system(size: 10, design: .monospaced)) // grid: ok font
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
                .fixedSize()

                Spacer(minLength: 8)

                // AI Architecture Tools Menu
                Menu {
                    Button {
                        onAIAutoLayout()
                    } label: {
                        Label("AI-Раскладка секций", systemImage: "wand.and.stars")
                    }

                    Button {
                        onCoArchitect()
                    } label: {
                        Label("AI Ко-Архитектор (пробелы и защита)", systemImage: "cpu")
                    }

                    Button {
                        onRepoIngestion()
                    } label: {
                        Label("Импорт структуры репозитория", systemImage: "square.stack.3d.down.right")
                    }

                    Button {
                        onRoadmapHUD()
                    } label: {
                        Label("Дорожная карта (волны выполнения)", systemImage: "chart.bar.xaxis")
                    }

                    Divider()

                    Button {
                        onOpenDataDesigner()
                    } label: {
                        Label("Конструктор схемы данных", systemImage: "cylinder.split.1x2")
                    }

                    Button {
                        onOpenAPIContract()
                    } label: {
                        Label("API-контракты и Mock-сервер", systemImage: "arrow.triangle.swap")
                    }

                    Button {
                        onOpenStateFlow()
                    } label: {
                        Label("Симулятор стейт-машины", systemImage: "arrow.triangle.branch")
                    }

                    Button {
                        onOpenSitemap()
                    } label: {
                        Label("Карта экранов и навигации", systemImage: "map")
                    }

                    Divider()

                    Button {
                        onOpenErrorDoctor()
                    } label: {
                        Label("Доктор ошибок Antigravity", systemImage: "cross.case")
                    }

                    Button {
                        onOpenCodebaseAuditor()
                    } label: {
                        Label("Аудит чистоты репозитория", systemImage: "checkmark.seal")
                    }

                    Button {
                        onOpenGitStory()
                    } label: {
                        Label("Генератор Git PR и коммитов", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    }

                    Divider()

                    Button {
                        onOpenSeedData()
                    } label: {
                        Label("Генератор реалистичных данных (Seed/Fixtures)", systemImage: "tray.full")
                    }

                    Button {
                        onOpenSecretShield()
                    } label: {
                        Label("Secret Shield (защита API-ключей и .env)", systemImage: "lock.shield")
                    }

                    Button {
                        onOpenBloatGuard()
                    } label: {
                        Label("Bloat Guard (контроль зависимостей)", systemImage: "scalemass")
                    }

                    Button {
                        onOpenDeployBlueprint()
                    } label: {
                        Label("Чертежи деплоя (Vercel / Cloudflare / Docker)", systemImage: "cloud")
                    }

                    Divider()

                    Button {
                        onOpenContextOptimizer()
                    } label: {
                        Label("Оптимизатор контекста (сжатие токенов)", systemImage: "gauge.with.needle")
                    }

                    Button {
                        onOpenComponentMatrix()
                    } label: {
                        Label("Матрица UI-компонентов и пропсов", systemImage: "square.split.2x2")
                    }

                    Button {
                        onOpenAcceptanceCriteria()
                    } label: {
                        Label("Критерии приемки и E2E тесты", systemImage: "checklist.checked")
                    }

                    Button {
                        onOpenScopeGuard()
                    } label: {
                        Label("Барьер от оверинжиниринга (Scope Guard)", systemImage: "shield.slash")
                    }

                    Button {
                        onOpenWorkstreamSplitter()
                    } label: {
                        Label("Матрица параллельных потоков", systemImage: "arrow.triangle.pull")
                    }

                    Button {
                        onOpenPatchInspector()
                    } label: {
                        Label("Инспектор патчей Antigravity", systemImage: "shield.lefthalf.filled")
                    }

                    Button {
                        onOpenFallbackPlanner()
                    } label: {
                        Label("План отказоустойчивости (Fallbacks)", systemImage: "lifepreserver")
                    }

                    Button {
                        onOpenRunbook()
                    } label: {
                        Label("Инженерный ранбук (Dev Runbook)", systemImage: "terminal")
                    }

                    Button {
                        onOpenEvalHarness()
                    } label: {
                        Label("AI Eval Harness (Тест-бенч)", systemImage: "checkmark.shield")
                    }

                    Button {
                        onOpenFeatureFlagMatrix()
                    } label: {
                        Label("Матрица фиче-флагов (Rollout)", systemImage: "flag")
                    }

                    Button {
                        onOpenTelemetrySpecifier()
                    } label: {
                        Label("Спецификатор телеметрии (Events)", systemImage: "antenna.radiowaves.left.and.right")
                    }

                    Button {
                        onOpenPerformanceBudget()
                    } label: {
                        Label("Бюджет производительности (Vitals)", systemImage: "gauge.with.needle")
                    }

                    Button {
                        onOpenThreatModeler()
                    } label: {
                        Label("Моделирование угроз (OWASP)", systemImage: "exclamationmark.shield")
                    }

                    Button {
                        onOpenMigrationStrategist()
                    } label: {
                        Label("Стратег миграций БД (Expand/Contract)", systemImage: "arrow.triangle.2.circlepath.circle")
                    }

                    Button {
                        onOpenLocalizationSpecifier()
                    } label: {
                        Label("Спецификатор локализации (I18N)", systemImage: "character.book.closed")
                    }

                    Button {
                        onOpenWebhookSimulator()
                    } label: {
                        Label("Стенд вебхуков (Webhooks)", systemImage: "arrow.triangle.pull")
                    }

                    Button {
                        onOpenAccessibilityAuditor()
                    } label: {
                        Label("Аудитор доступности (WCAG 2.2)", systemImage: "figure.roll")
                    }

                    Button {
                        onOpenMonorepoArchitect()
                    } label: {
                        Label("Архитектор монорепо (Workspaces)", systemImage: "square.split.diagonal.2x2")
                    }

                    Button {
                        onOpenSEOStudio()
                    } label: {
                        Label("Студия SEO и OpenGraph", systemImage: "globe.desk")
                    }

                    Button {
                        onOpenSkillSynthesizer()
                    } label: {
                        Label("Синтезатор навыков и MCP (Skills)", systemImage: "puzzlepiece.extension")
                    }

                    Button {
                        onOpenTokenBudgeteer()
                    } label: {
                        Label("Бюджет токенов и стоимости ИИ", systemImage: "creditcard.and.123")
                    }

                    Button {
                        onOpenRealtimeArchitect()
                    } label: {
                        Label("Архитектор Real-time и SSE", systemImage: "dot.radiowaves.left.and.right")
                    }

                    Button {
                        onOpenJobQueueStrategist()
                    } label: {
                        Label("Стратег очередей и Cron (Jobs)", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }

                    Button {
                        onOpenIncidentCommander()
                    } label: {
                        Label("План реагирования и откат (Rollback)", systemImage: "cross.case")
                    }

                    Button {
                        onOpenVectorStoreSpecifier()
                    } label: {
                        Label("Векторные БД и RAG (pgvector)", systemImage: "point.3.filled.connected.triangle.path")
                    }

                    Button {
                        onOpenComplianceGuardian()
                    } label: {
                        Label("Комплаенс и GDPR (Privacy)", systemImage: "hand.raised.square")
                    }

                    Button {
                        onOpenMultiTenantArchitect()
                    } label: {
                        Label("Мульти-тенантность (RBAC)", systemImage: "building.2.crop.circle")
                    }

                    Button {
                        onOpenStressTestArchitect()
                    } label: {
                        Label("Стресс-тесты k6 (Load)", systemImage: "flame")
                    }

                    Button {
                        onOpenEmailStudio()
                    } label: {
                        Label("Студия писем (Email)", systemImage: "envelope.fill")
                    }

                    Button {
                        onOpenDocStudio()
                    } label: {
                        Label("Интерактивная документация (Docs API)", systemImage: "doc.text.magnifyingglass")
                    }

                    Button {
                        onOpenIndexOptimizer()
                    } label: {
                        Label("Оптимизатор индексов БД (Indexes)", systemImage: "point.filled.topleft.down.curvedto.point.bottomright.up")
                    }

                    Button {
                        onOpenModelRouter()
                    } label: {
                        Label("Мульти-модельный оркестратор (Gemini 3.8)", systemImage: "cpu.fill")
                    }

                    Button {
                        onOpenStorageGuard()
                    } label: {
                        Label("Страж облачных хранилищ (Storage)", systemImage: "externaldrive.badge.shield")
                    }

                    Button {
                        onOpenCacheStrategist()
                    } label: {
                        Label("Стратег кэширования (Cache)", systemImage: "bolt.horizontal.circle.fill")
                    }

                    Button {
                        onOpenRpcContractStudio()
                    } label: {
                        Label("Студия RPC-контрактов (tRPC)", systemImage: "arrow.triangle.swap")
                    }

                    Button {
                        onOpenExperimentStudio()
                    } label: {
                        Label("Песочница A/B тестов (Experiments)", systemImage: "slider.horizontal.2.square")
                    }

                    Divider()

                    Button {
                        isSimulationActive.toggle()
                    } label: {
                        Label(isSimulationActive ? "Остановить симуляцию потоков" : "Запуск симуляции потоков (QPS/RPS)", systemImage: "waveform.path.ecg")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("AI Архитектор")
                    }
                    .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .fixedSize()
                .help("Инструменты AI-проектирования: авто-раскладка, аудит пробелов, дорожная карта")

                // Add Elements Menu
                Menu {
                    Button {
                        onAddFrame()
                    } label: {
                        Label("Фрейм", systemImage: "squareshape.dashed.squareshape")
                    }

                    Button {
                        onAddSticky()
                    } label: {
                        Label("Стикер", systemImage: "note.text.badge.plus")
                    }

                    Button {
                        onAddNewIdea()
                    } label: {
                        Label("Идея", systemImage: "plus")
                    }

                    Button {
                        onOpenReferencePicker()
                    } label: {
                        Label("Референс (Mobbin / Figma)", systemImage: "photo.on.rectangle.angled")
                    }

                    Divider()

                    Menu("Шаблоны архитектуры") {
                        ForEach(CanvasBlueprintPacks.all) { pack in
                            Button {
                                onDeployBlueprintPack(pack)
                            } label: {
                                Label(pack.title, systemImage: pack.icon)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Добавить")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .fixedSize()

                // Connect Mode Toggle Button
                Button {
                    isConnectingMode.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isConnectingMode ? "xmark.circle.fill" : "link.badge.plus")
                        Text(isConnectingMode ? "Отмена связи" : "Связать")
                    }
                    .font(.caption)
                    .foregroundStyle(isConnectingMode ? Color.white : Color.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isConnectingMode ? Color.orange : Color.secondary.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .fixedSize()

                // Live Simulation Toggle Button
                Button {
                    isSimulationActive.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isSimulationActive ? "waveform.path.ecg" : "play.fill")
                        Text(isSimulationActive ? "Потоки" : "Симуляция")
                    }
                    .font(.caption)
                    .foregroundStyle(isSimulationActive ? Color.white : Color.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isSimulationActive ? Color.green : Color.secondary.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help("Живая симуляция потоков данных и пропускной способности связей (RPS/QPS)")

                // Canvas Tool Mode (Select vs Pan)
                Picker("", selection: $canvasTool) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right").tag(CanvasTool.select)
                    Image(systemName: "hand.raised").tag(CanvasTool.pan)
                }
                .pickerStyle(.segmented)
                .fixedSize()

                if selectedElementCount > 0 {
                    Button {
                        onGroupSelected()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.3.group")
                            Text("В подсистему")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .fixedSize()

                    Button {
                        onDeleteSelected()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(Color.red)
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }

                // Interactive WebStudio Mockup Button
                Button {
                    onOpenMockup()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "safari")
                        Text("Эскиз")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .fixedSize()
                .help("Открыть живой интерактивный макет в WebStudio")

                // Antigravity Cockpit Button
                Button {
                    onOpenAntigravityPack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.shield.fill")
                        Text("Antigravity")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .fixedSize()
                .help("Собрать токено-эффективный пакет волн (Waves) и спецификацию для Antigravity")

                // LAN Peers Discovery Popover Button
                Button {
                    showPeersPopover = true
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(lanPeers.isEmpty ? Color.secondary.opacity(0.4) : Color.green)
                            .frame(width: 8, height: 8)
                        Image(systemName: lanPeers.isEmpty ? "network.slash" : "network")
                        Text(lanPeers.isEmpty ? "LAN" : "Пиры: \(lanPeers.count)")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .fixedSize()
                .popover(isPresented: $showPeersPopover) {
                    CanvasLANPeersPopover(peers: lanPeers, onSync: onSyncPeer)
                }

                // Export Menu
                Menu {
                    Button {
                        onExportSVG()
                    } label: {
                        Label("Векторный SVG (.svg)", systemImage: "chevron.left.forwardslash.chevron.right")
                    }

                    Button {
                        onExportPNG()
                    } label: {
                        Label("Изображение PNG (.png)", systemImage: "photo")
                    }

                    Button {
                        onExportPDF()
                    } label: {
                        Label("Векторный PDF (.pdf)", systemImage: "doc.richtext")
                    }

                    Button {
                        onExportHTML()
                    } label: {
                        Label("Интерактивный HTML (.html)", systemImage: "safari")
                    }

                    Button {
                        onExportMermaid()
                    } label: {
                        Label("Диаграмма Mermaid (.mmd)", systemImage: "arrow.triangle.branch")
                    }

                    Button {
                        onCopyMermaid()
                    } label: {
                        Label("Скопировать Mermaid для Antigravity", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    }

                    Button {
                        onOpenAntigravityPack()
                    } label: {
                        Label("Пакет для Antigravity (волны)", systemImage: "bolt.shield.fill")
                    }

                    Divider()

                    Button {
                        onCopyPNG()
                    } label: {
                        Label("Скопировать в буфер (PNG)", systemImage: "doc.on.doc")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Экспорт")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)

                // Zoom Controls
                HStack(spacing: 4) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            zoomScale = max(0.4, zoomScale - 0.15)
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)

                    Text("\(Int(zoomScale * 100))%")
                        .font(.system(size: 11, design: .monospaced)) // grid: ok font
                        .frame(width: 44)

                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            zoomScale = min(2.0, zoomScale + 0.15)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)

                    Button("100%") {
                        onResetZoom()
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            // Connecting Helper Banner
            if isConnectingMode {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.orange)
                    Text(connectingSourceId == nil ? "Кликните на первую карточку, стикер или референс" : "Теперь выберите целевой узел для соединения стрелкой")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)

                    Spacer()

                    Button("Отмена") {
                        onCancelConnecting()
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Toast Notification
            if let toast = toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(toast)
                        .font(.caption.bold())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .padding(16)
    }
}
