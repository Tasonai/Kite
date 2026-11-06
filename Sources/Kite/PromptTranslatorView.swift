import AppKit
import SwiftData
import SwiftUI
import KiteKit

enum InputExperience: String, CaseIterable, Identifiable {
    case wizard = "Простой мастер"
    case expert = "Экспертный"
    var id: String { rawValue }
}

struct PromptTranslatorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context

    @State private var inputExperience: InputExperience = .wizard
    @State private var rawPrompt: String = ""
    @State private var generatedBlueprint: String = ""
    @State private var selectedMode: String = "full"
    @State private var selectedPlatform: String = "Web"
    @State private var selectedStyle: String = "Editorial & Swiss Modern"
    @State private var activeSkills: Set<String> = ["/site-md", "/design-md", "/taste-design", "/impeccable", "/emil-design-eng"]
    @State private var isCopied: Bool = false
    @State private var isStarterCopied: Bool = false
    @State private var isMockupPresented: Bool = false
    @State private var isAntigravityPackPresented: Bool = false
    @State private var isErrorDoctorPresented: Bool = false
    @State private var isDataDesignerPresented: Bool = false
    @State private var isTokenSandboxPresented: Bool = false
    @State private var isAuditorPresented: Bool = false
    @State private var isAPIContractPresented: Bool = false
    @State private var isStateFlowPresented: Bool = false
    @State private var isSitemapPresented: Bool = false
    @State private var isGitStoryPresented: Bool = false
    @State private var isSeedDataPresented: Bool = false
    @State private var isSecretShieldPresented: Bool = false
    @State private var isBloatGuardPresented: Bool = false
    @State private var isDeployBlueprintPresented: Bool = false
    @State private var isContextOptimizerPresented: Bool = false
    @State private var isComponentMatrixPresented: Bool = false
    @State private var isAcceptanceCriteriaPresented: Bool = false
    @State private var isScopeGuardPresented: Bool = false
    @State private var isWorkstreamSplitterPresented: Bool = false
    @State private var isPatchInspectorPresented: Bool = false
    @State private var isFallbackPlannerPresented: Bool = false
    @State private var isRunbookPresented: Bool = false
    @State private var lastScaffoldedDirectory: URL? = nil
    @State private var isSavedToIdeas: Bool = false
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @AppStorage("translator_interview") private var interviewEnabled = true
    @State private var interviewQuestions: [AIPrompts.InterviewQuestion] = []
    @State private var interviewAnswers: [UUID: String] = [:]
    @State private var isAskingQuestions = false

    @AppStorage("ai_provider") private var aiProvider = "Gemini API"
    @AppStorage("gemini_api_key") private var geminiApiKey = ""
    @AppStorage("gemini_model") private var geminiModel = GeminiClient.defaultModel
    @AppStorage("ollama_endpoint") private var ollamaEndpoint = "http://localhost:11434/api/generate"
    @AppStorage("ollama_model") private var ollamaModel = "llama3"

    private let modes = [
        ("full", "План"),
        ("stitch", "Stitch"),
        ("edit", "Точечный"),
        ("concise", "Бриф"),
        ("action", "Действия")
    ]

    private let platforms = ["Web", "Mobile", "Desktop"]
    private let styles = [
        "Editorial & Swiss Modern",
        "Claude Parchment",
        "Codex Minimal",
        "Terracotta Clay",
        "Risograph Two-Color",
        "Bento Contemporary",
        "Linear & DevTool Cockpit",
        "Neo-Brutalism & Tactical",
        "Voxel & 3D Isometric",
        "Glassmorphism & Spatial"
    ]

    private let availableSkills = [
        "/enhance-prompt", "/design-md", "/site-md", "/taste-design",
        "/impeccable", "/emil-design-eng", "/a11y-debugging",
        "/subagent-driven-development"
    ]

    // Quality Score (0-100)
    private var qualityScore: Int {
        var score = 20
        if !rawPrompt.trimmingCharacters(in: .whitespaces).isEmpty { score += 25 }
        if rawPrompt.count > 60 { score += 15 }
        if !activeSkills.isEmpty { score += 20 }
        if !selectedStyle.isEmpty { score += 10 }
        if !selectedPlatform.isEmpty { score += 10 }
        return min(score, 100)
    }

    private var pitfalls: [PitfallWarning] {
        guard !rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return AIPitfallProtector.analyze(concept: rawPrompt, platform: selectedPlatform)
    }

    var body: some View {
        HSplitView {
            // Left: Input & Controls
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header & Experience Mode Selector
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Промпт-переводчик Antigravity")
                                    .font(.title3.bold())
                                Text("Превращайте задумку в надежный инженерный план для AI.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()

                            Picker("", selection: $inputExperience) {
                                ForEach(InputExperience.allCases) { exp in
                                    Text(exp.rawValue).tag(exp)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .fixedSize()
                        }
                    }

                    // Quick Vibe Tools Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                isErrorDoctorPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "cross.case")
                                    Text("Доктор ошибок")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Диагностика сбоев терминала и генерация точечного Fix-промпта")

                            Button {
                                isDataDesignerPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "cylinder.split.1x2")
                                    Text("Схема данных")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Визуальное проектирование таблиц и генерация SQL/Prisma/SwiftData")

                            Button {
                                isAPIContractPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.swap")
                                    Text("API-контракты")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Спецификация эндпоинтов и локальный Mock-сервер (порт 49495)")

                            Button {
                                isStateFlowPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.branch")
                                    Text("Стейт-машина")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Моделирование состояний интерфейса (Idle/Loading/Success/Error)")

                            Button {
                                isSitemapPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "map")
                                    Text("Карта экранов")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Иерархия страниц и генерация Next.js / SwiftUI роутера")

                            Button {
                                isTokenSandboxPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "paintpalette")
                                    Text("Песочница токенов")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Интерактивная проверка стилей, кнопок и карточек")

                            Button {
                                isAuditorPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal")
                                    Text("Аудит кода")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Проверка готового проекта на чистоту кода, логи и эмодзи")

                            Button {
                                isGitStoryPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                                    Text("Git PR")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Генерация Conventional Commits и описания Pull Request для GitHub")

                            Button {
                                isSeedDataPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "tray.full")
                                    Text("Сид-данные")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Генерация реалистичных тестовых данных и JSON-фикстур")

                            Button {
                                isSecretShieldPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.shield")
                                    Text("Защита ключей")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Сканирование текста на утечки API-ключей и генератор .env.example")

                            Button {
                                isBloatGuardPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "scalemass")
                                    Text("Bloat Guard")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Инспектор легковесности зависимостей и директива чистоты бандла")

                            Button {
                                isDeployBlueprintPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "cloud")
                                    Text("Деплой")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Конфигурации деплоя для Vercel, Cloudflare, Docker и GitHub Actions")

                            Button {
                                isContextOptimizerPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "gauge.with.needle")
                                    Text("Сжатие токенов")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Сверхплотный дайджест архитектуры: экономия до 95% токенов")

                            Button {
                                isComponentMatrixPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.split.2x2")
                                    Text("UI-компоненты")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Матрица интерфейсов компонентов, состояний и доступности")

                            Button {
                                isAcceptanceCriteriaPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checklist.checked")
                                    Text("Критерии приемки")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Сценарии Given/When/Then и готовые тесты Playwright")

                            Button {
                                isScopeGuardPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "shield.slash")
                                    Text("Scope Guard")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Барьер от оверинжиниринга: жесткий список запретов для ИИ")

                            Button {
                                isWorkstreamSplitterPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.pull")
                                    Text("Воркстримы")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Разбиение задачи на параллельные независимые потоки субагентов")

                            Button {
                                isPatchInspectorPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "shield.lefthalf.filled")
                                    Text("Патч-инспектор")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Аудит diff-изменений: поиск удаленных типов, утечек и логов")

                            Button {
                                isFallbackPlannerPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "lifepreserver")
                                    Text("Отказоустойчивость")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Стратегии деградации: оффлайн-кэш, 429 backoff, Error Boundaries")

                            Button {
                                isRunbookPresented = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "terminal")
                                    Text("Ранбук")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Инженерный ранбук и команды терминала для Antigravity")
                        }
                        .padding(.vertical, 2)
                    }

                    // Raw Input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(inputExperience == .wizard ? "Опишите вашу идею своими словами" : "Ваша идея или черновик")
                                .font(.headline)

                            Spacer()

                            VoiceRecordButton { speech in
                                if rawPrompt.isEmpty {
                                    rawPrompt = speech
                                } else {
                                    rawPrompt += " " + speech
                                }
                            }

                            Text("\(rawPrompt.count) символов")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }

                        TextEditor(text: $rawPrompt)
                            .font(.body)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }

                    if inputExperience == .wizard {
                        // 1. Where does it run?
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Где будет работать проект?")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                wizardChip("В браузере (Веб)", isSelected: selectedPlatform == "Web") {
                                    selectedPlatform = "Web"
                                    selectedStyle = "Editorial & Swiss Modern"
                                }
                                wizardChip("На смартфоне (Мобильный)", isSelected: selectedPlatform == "Mobile") {
                                    selectedPlatform = "Mobile"
                                    selectedStyle = "Neo-Brutalism & Tactical"
                                }
                                wizardChip("На компьютере (Десктоп)", isSelected: selectedPlatform == "Desktop") {
                                    selectedPlatform = "Desktop"
                                    selectedStyle = "Linear & DevTool Cockpit"
                                }
                            }
                        }

                        // 2. How should it feel?
                        VStack(alignment: .leading, spacing: 8) {
                            Text("2. Как интерфейс должен ощущаться?")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                wizardChip("Современно и чисто", isSelected: selectedStyle == "Editorial & Swiss Modern") {
                                    selectedStyle = "Editorial & Swiss Modern"
                                }
                                wizardChip("Тёмный пульт (Linear)", isSelected: selectedStyle == "Linear & DevTool Cockpit") {
                                    selectedStyle = "Linear & DevTool Cockpit"
                                }
                                wizardChip("Теплый блокнот (Claude)", isSelected: selectedStyle == "Claude Parchment") {
                                    selectedStyle = "Claude Parchment"
                                }
                            }
                        }

                        // 3. What is the focus?
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3. Главная задача?")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                wizardChip("Быстрый ввод и списки", isSelected: activeSkills.contains("/impeccable")) {
                                    activeSkills = ["/site-md", "/design-md", "/impeccable", "/emil-design-eng"]
                                }
                                wizardChip("AI-Ассистент / Чат", isSelected: activeSkills.contains("/subagent-driven-development")) {
                                    activeSkills = ["/subagent-driven-development", "/site-md", "/design-md"]
                                }
                                wizardChip("Лендинг / Витрина", isSelected: activeSkills.contains("/taste-design")) {
                                    activeSkills = ["/enhance-prompt", "/taste-design", "/design-md"]
                                }
                            }
                        }
                    } else {
                        // Expert Mode: Mode Selector
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Режим вывода")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Picker("", selection: $selectedMode) {
                                ForEach(modes, id: \.0) { m in
                                    Text(m.1).tag(m.0)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                        }

                        // Presets Bar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Быстрые пресеты")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    presetButton("Stitch Landing", style: "Editorial & Swiss Modern", platform: "Web", prompt: "Лендинг цифрового сервиса с шапкой, карточками преимуществ, формой обратной связи и четкой дизайн-системой.")
                                    presetButton("Claude Paper", style: "Claude Parchment", platform: "Web", prompt: "Академический исследовательский интерфейс на теплом пергаменте со строгой типографикой, цитатами и минимальным шумом.")
                                    presetButton("Codex Minimal", style: "Codex Minimal", platform: "Web", prompt: "Радикально чистый монохромный интерфейс без теней, чистый белый холст и швейцарские шрифты.")
                                    presetButton("Terracotta Journal", style: "Terracotta Clay", platform: "Web", prompt: "Теплый глиняный журнал с мягкими тенями, тактильными пилюлями и кремовым фоном.")
                                    presetButton("Agent Cockpit", style: "Linear & DevTool Cockpit", platform: "Desktop", prompt: "Тёмный пульт разработчика для мониторинга фоновых агентов, очереди сборки и стриминга логов.")
                                    presetButton("Habit Radar", style: "Neo-Brutalism & Tactical", platform: "Mobile", prompt: "Тактический нео-бруталистический трекер привычек с жесткими тенями, тактильным звуковым кликом и бейджами.")
                                    presetButton("Voxel Studio", style: "Voxel & 3D Isometric", platform: "Web", prompt: "3D конструктор изометрических сцен с мягким светом Ambient Occlusion и воксельными карточками.")
                                }
                            }
                        }

                        // Platform & Style
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Платформа").font(.caption.bold()).foregroundStyle(.secondary)
                                Picker("", selection: $selectedPlatform) {
                                    ForEach(platforms, id: \.self) { p in Text(p).tag(p) }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Дизайн-система").font(.caption.bold()).foregroundStyle(.secondary)
                                Picker("", selection: $selectedStyle) {
                                    ForEach(styles, id: \.self) { s in Text(s).tag(s) }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                        }

                        // Skills Matrix
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Активные скиллы Antigravity")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            FlowLayout(spacing: 8) {
                                ForEach(availableSkills, id: \.self) { skill in
                                    Button {
                                        if activeSkills.contains(skill) {
                                            activeSkills.remove(skill)
                                        } else {
                                            activeSkills.insert(skill)
                                        }
                                    } label: {
                                        Text(skill)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(activeSkills.contains(skill) ? Color.accentColor : Color.secondary.opacity(0.12))
                                            .foregroundStyle(activeSkills.contains(skill) ? Color.white : Color.primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if !interviewQuestions.isEmpty {
                        TranslatorInterviewPanel(
                            questions: interviewQuestions,
                            answers: $interviewAnswers,
                            onSubmit: {
                                let answers = interviewQuestions.map { (question: $0.text, answer: interviewAnswers[$0.id] ?? "") }
                                Task { await runTranslate(answers: answers) }
                            },
                            onSkip: {
                                Task { await runTranslate() }
                            }
                        )
                    }

                    // Primary Generator Buttons
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await startTranslate()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isGenerating || isAskingQuestions {
                                    ProgressView().controlSize(.small)
                                    Text(isAskingQuestions ? "Формулирую вопросы..." : "Трансляция архитектуры...")
                                } else {
                                    Image(systemName: "wand.and.stars")
                                    Text("Скомпилировать /plan")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                        .disabled(isGenerating || isAskingQuestions)

                        Button {
                            saveAsNewIdea()
                        } label: {
                            Label(isSavedToIdeas ? "Сохранено" : "В идеи", systemImage: isSavedToIdeas ? "checkmark" : "plus.circle")
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(rawPrompt.trimmingCharacters(in: .whitespaces).isEmpty)

                        Button {
                            scaffoldProject()
                        } label: {
                            Label("Экспорт", systemImage: "folder.badge.plus")
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(rawPrompt.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if let err = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(20)
            }
            .frame(minWidth: 360, idealWidth: 420)

            // Right: Output & Quality Gauge
            TranslatorOutputView(
                generatedBlueprint: $generatedBlueprint,
                selectedMode: selectedMode,
                qualityScore: qualityScore,
                isCopied: isCopied,
                isStarterCopied: isStarterCopied,
                pitfalls: pitfalls,
                onCopy: { copyBlueprint() },
                onCopyStarterPrompt: { copyStarterPrompt() },
                onOpenMockup: { isMockupPresented = true },
                onOpenAntigravityPack: { isAntigravityPackPresented = true },
                onOpenEditor: { editor in openProjectInEditor(editor) }
            )
        }
        .sheet(isPresented: $isAntigravityPackPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            AntigravityPackSheet(
                title: title,
                concept: rawPrompt,
                platform: selectedPlatform,
                style: selectedStyle,
                architectureMermaid: nil,
                onDismiss: { isAntigravityPackPresented = false }
            )
        }
        .sheet(isPresented: $isMockupPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Интерактивный черновик" : String(effectiveTitle)
            InteractiveMockupSheet(
                title: title,
                concept: rawPrompt,
                platform: selectedPlatform,
                style: selectedStyle,
                onDismiss: { isMockupPresented = false }
            )
        }
        .sheet(isPresented: $isErrorDoctorPresented) {
            VibeErrorDoctorSheet(onDismiss: { isErrorDoctorPresented = false })
        }
        .sheet(isPresented: $isDataDesignerPresented) {
            DataSchemaDesignerSheet(onDismiss: { isDataDesignerPresented = false })
        }
        .sheet(isPresented: $isTokenSandboxPresented) {
            DesignTokenSandboxSheet(initialStyle: selectedStyle, onDismiss: { isTokenSandboxPresented = false })
        }
        .sheet(isPresented: $isAuditorPresented) {
            CodebaseAuditorSheet(onDismiss: { isAuditorPresented = false })
        }
        .sheet(isPresented: $isAPIContractPresented) {
            APIContractSheet(onDismiss: { isAPIContractPresented = false })
        }
        .sheet(isPresented: $isStateFlowPresented) {
            StateFlowSheet(onDismiss: { isStateFlowPresented = false })
        }
        .sheet(isPresented: $isSitemapPresented) {
            SitemapRouterSheet(onDismiss: { isSitemapPresented = false })
        }
        .sheet(isPresented: $isGitStoryPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            GitStorytellerSheet(
                title: title,
                concept: rawPrompt,
                platform: selectedPlatform,
                style: selectedStyle,
                onDismiss: { isGitStoryPresented = false }
            )
        }
        .sheet(isPresented: $isSeedDataPresented) {
            SeedDataSheet(onDismiss: { isSeedDataPresented = false })
        }
        .sheet(isPresented: $isSecretShieldPresented) {
            SecretShieldSheet(onDismiss: { isSecretShieldPresented = false })
        }
        .sheet(isPresented: $isBloatGuardPresented) {
            DependencyGuardSheet(onDismiss: { isBloatGuardPresented = false })
        }
        .sheet(isPresented: $isDeployBlueprintPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            DeployBlueprintSheet(
                title: title,
                platform: selectedPlatform,
                onDismiss: { isDeployBlueprintPresented = false }
            )
        }
        .sheet(isPresented: $isContextOptimizerPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            ContextOptimizerSheet(
                title: title,
                concept: rawPrompt,
                platform: selectedPlatform,
                style: selectedStyle,
                onDismiss: { isContextOptimizerPresented = false }
            )
        }
        .sheet(isPresented: $isComponentMatrixPresented) {
            ComponentContractSheet(onDismiss: { isComponentMatrixPresented = false })
        }
        .sheet(isPresented: $isAcceptanceCriteriaPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            AcceptanceCriteriaSheet(
                title: title,
                onDismiss: { isAcceptanceCriteriaPresented = false }
            )
        }
        .sheet(isPresented: $isScopeGuardPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            NegativeScopeSheet(
                title: title,
                onDismiss: { isScopeGuardPresented = false }
            )
        }
        .sheet(isPresented: $isWorkstreamSplitterPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            WorkstreamSplitterSheet(
                title: title,
                onDismiss: { isWorkstreamSplitterPresented = false }
            )
        }
        .sheet(isPresented: $isPatchInspectorPresented) {
            PatchInspectorSheet(onDismiss: { isPatchInspectorPresented = false })
        }
        .sheet(isPresented: $isFallbackPlannerPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            FallbackPlannerSheet(
                title: title,
                onDismiss: { isFallbackPlannerPresented = false }
            )
        }
        .sheet(isPresented: $isRunbookPresented) {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            RunbookSheet(
                title: title,
                onDismiss: { isRunbookPresented = false }
            )
        }
    }

    private func wizardChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func presetButton(_ title: String, style: String, platform: String, prompt: String) -> some View {
        Button {
            selectedStyle = style
            selectedPlatform = platform
            rawPrompt = prompt
        } label: {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Asks a few clarifying questions first when that makes sense; otherwise generates right away.
    private func startTranslate() async {
        let idea = rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let canAsk = interviewEnabled
            && ["full", "stitch"].contains(selectedMode)
            && aiProvider == "Gemini API"
            && !geminiApiKey.isEmpty
            && idea.count >= 8
        guard canAsk else {
            await runTranslate()
            return
        }
        isAskingQuestions = true
        errorMessage = nil
        defer { isAskingQuestions = false }
        let questions = (try? await AIGenerator.interviewQuestions(
            idea: idea,
            platform: selectedPlatform,
            style: selectedStyle,
            apiKey: geminiApiKey,
            modelName: geminiModel
        )) ?? []
        if questions.isEmpty {
            await runTranslate()
        } else {
            interviewAnswers = [:]
            interviewQuestions = questions
        }
    }

    private func runTranslate(answers: [(question: String, answer: String)] = []) async {
        interviewQuestions = []
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        let skillsArray = Array(activeSkills)
        let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
        let cleanTitle = effectiveTitle.isEmpty ? "Новый проект" : effectiveTitle

        let provider: AIProvider
        switch aiProvider {
        case "Local Ollama": provider = .localOllama
        case "Local Blueprint (Offline)": provider = .localCompiler
        default: provider = .gemini
        }

        func compileLocally() -> String {
            switch selectedMode {
            case "stitch":
                return PromptCompiler.compileStitchPrompt(
                    title: cleanTitle,
                    concept: rawPrompt,
                    platform: selectedPlatform,
                    style: selectedStyle,
                    skills: skillsArray
                )
            case "edit":
                return PromptCompiler.compileTargetedEditPrompt(
                    title: cleanTitle,
                    concept: rawPrompt,
                    platform: selectedPlatform,
                    style: selectedStyle,
                    skills: skillsArray
                )
            case "concise":
                return PromptCompiler.compileConcisePrompt(
                    title: cleanTitle,
                    concept: rawPrompt,
                    platform: selectedPlatform,
                    style: selectedStyle,
                    skills: skillsArray
                )
            case "action":
                return PromptCompiler.compileActionPrompt(
                    title: cleanTitle,
                    concept: rawPrompt,
                    platform: selectedPlatform,
                    style: selectedStyle,
                    skills: skillsArray
                )
            default:
                return PromptCompiler.compileBlueprint(
                    title: cleanTitle,
                    concept: rawPrompt,
                    platform: selectedPlatform,
                    style: selectedStyle,
                    skills: skillsArray
                )
            }
        }

        do {
            if aiProvider == "Local Blueprint (Offline)" || (aiProvider == "Gemini API" && geminiApiKey.isEmpty) {
                generatedBlueprint = compileLocally()
                if aiProvider == "Gemini API" { errorMessage = AIGenerator.offlineNotice }
            } else {
                generatedBlueprint = ""
                for try await piece in AIGenerator.generateSpecificationStream(
                    title: cleanTitle,
                    concept: AIPrompts.enrich(idea: rawPrompt, answers: answers),
                    platform: selectedPlatform,
                    style: selectedStyle,
                    apiKey: geminiApiKey,
                    provider: provider,
                    modelName: aiProvider == "Local Ollama" ? ollamaModel : geminiModel,
                    ollamaEndpoint: ollamaEndpoint,
                    mode: selectedMode,
                    skills: skillsArray.sorted()
                ) {
                    generatedBlueprint += piece
                }
            }
            NSSound.beep()
        } catch {
            if generatedBlueprint.isEmpty {
                errorMessage = "Модель не ответила, показан офлайн-шаблон, а не ответ ИИ. Причина: \(error.localizedDescription)"
                generatedBlueprint = compileLocally()
            } else {
                errorMessage = "Ответ оборван, ниже то, что успело прийти. Причина: \(error.localizedDescription)"
            }
        }
    }

    private func copyBlueprint() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedBlueprint, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }

    private func copyStarterPrompt() {
        let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
        let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
        let prompt = PromptCompiler.compileStarterPrompt(
            title: title,
            concept: rawPrompt,
            platform: selectedPlatform,
            style: selectedStyle
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        isStarterCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isStarterCopied = false
        }
    }

    private func saveAsNewIdea() {
        let title = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
        let item = Item(title: title.isEmpty ? "Идея из переводчика" : title)
        item.concept = rawPrompt
        item.platform = selectedPlatform
        item.style = selectedStyle
        item.status = "backlog"
        item.generatedPrompt = generatedBlueprint

        context.insert(item)
        try? context.save()
        model.selection = item.id
        isSavedToIdeas = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSavedToIdeas = false
        }
    }

    private func scaffoldProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Создать здесь"
        panel.message = "Выберите папку для создания проекта"

        let devDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Developer", isDirectory: true)
        if FileManager.default.fileExists(atPath: devDir.path) {
            panel.directoryURL = devDir
        }

        if panel.runModal() == .OK, let targetURL = panel.url {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            do {
                let result = try ProjectScaffolder.scaffold(
                    at: targetURL,
                    title: title,
                    concept: rawPrompt,
                    platform: selectedPlatform,
                    style: selectedStyle,
                    planPrompt: generatedBlueprint,
                    createGitBranch: true
                )
                lastScaffoldedDirectory = result.directory
                NSSound.beep()
                NSWorkspace.shared.selectFile(result.directory.path, inFileViewerRootedAtPath: "")
            } catch {
                errorMessage = "Ошибка экспорта: \(error.localizedDescription)"
            }
        }
    }

    private func openProjectInEditor(_ editor: EditorLauncher.Editor) {
        if let dir = lastScaffoldedDirectory, FileManager.default.fileExists(atPath: dir.path) {
            _ = EditorLauncher.open(directory: dir, in: editor)
        } else {
            let effectiveTitle = rawPrompt.split(separator: " ").prefix(4).joined(separator: " ")
            let title = effectiveTitle.isEmpty ? "Новый проект" : String(effectiveTitle)
            let devDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Developer", isDirectory: true)
            let targetURL = FileManager.default.fileExists(atPath: devDir.path) ? devDir : FileManager.default.temporaryDirectory
            if let result = try? ProjectScaffolder.scaffold(
                at: targetURL,
                title: title,
                concept: rawPrompt,
                platform: selectedPlatform,
                style: selectedStyle,
                planPrompt: generatedBlueprint,
                createGitBranch: true
            ) {
                lastScaffoldedDirectory = result.directory
                _ = EditorLauncher.open(directory: result.directory, in: editor)
            }
        }
    }
}

// FlowLayout for multi-tag wraps
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
        height = y + maxHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}
