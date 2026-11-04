import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct PromptTranslatorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context

    @State private var rawPrompt: String = ""
    @State private var generatedBlueprint: String = ""
    @State private var selectedMode: String = "full"
    @State private var selectedPlatform: String = "Web"
    @State private var selectedStyle: String = "Editorial & Swiss Modern"
    @State private var activeSkills: Set<String> = ["@site-md", "@design-md", "@taste-design", "@impeccable", "@emil-design-eng"]
    @State private var isCopied: Bool = false
    @State private var isSavedToIdeas: Bool = false
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?

    @AppStorage("ai_provider") private var aiProvider = "Gemini API"
    @AppStorage("gemini_api_key") private var geminiApiKey = ""
    @AppStorage("gemini_model") private var geminiModel = "gemini-2.5-flash"
    @AppStorage("ollama_endpoint") private var ollamaEndpoint = "http://localhost:11434/api/generate"
    @AppStorage("ollama_model") private var ollamaModel = "llama3"

    private let modes = [
        ("full", "📐 План"),
        ("stitch", "🧵 Stitch"),
        ("edit", "🎯 Точечный"),
        ("concise", "📄 Бриф"),
        ("action", "⚡️ Действия")
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
        "@enhance-prompt", "@design-md", "@site-md", "@taste-design",
        "@impeccable", "@emil-design-eng", "@a11y-debugging",
        "@subagent-driven-development"
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

    var body: some View {
        HSplitView {
            // Left: Input & Controls
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Промпт-переводчик Antigravity 🪄")
                            .font(.title2.bold())
                        Text("Превращайте идеи и эскизы в точную инженерную спецификацию /plan.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Mode Selector
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
                                presetButton("Stitch Landing 🧵", style: "Editorial & Swiss Modern", platform: "Web", prompt: "Лендинг цифрового сервиса с шапкой, карточками преимуществ, формой обратной связи и четкой дизайн-системой.")
                                presetButton("Claude Paper 📜", style: "Claude Parchment", platform: "Web", prompt: "Академический исследовательский интерфейс на теплом пергаменте со строгой типографикой, цитатами и минимальным шумом.")
                                presetButton("Codex Minimal ⚪️", style: "Codex Minimal", platform: "Web", prompt: "Радикально чистый монохромный интерфейс без теней, чистый белый холст и швейцарские шрифты.")
                                presetButton("Terracotta Journal 🏺", style: "Terracotta Clay", platform: "Web", prompt: "Теплый глиняный журнал с мягкими тенями, тактильными пилюлями и кремовым фоном.")
                                presetButton("Agent Cockpit ⚡️", style: "Linear & DevTool Cockpit", platform: "Desktop", prompt: "Тёмный пульт разработчика для мониторинга фоновых агентов, очереди сборки и стриминга логов.")
                                presetButton("Habit Radar 🎯", style: "Neo-Brutalism & Tactical", platform: "Mobile", prompt: "Тактический нео-бруталистический трекер привычек с жесткими тенями, тактильным звуковым кликом и бейджами.")
                                presetButton("Voxel Studio 🧊", style: "Voxel & 3D Isometric", platform: "Web", prompt: "3D конструктор изометрических сцен с мягким светом Ambient Occlusion и воксельными карточками.")
                            }
                        }
                    }

                    // Raw Input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Ваша идея или черновик")
                                .font(.headline)
                            Spacer()
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

                    // Primary Generator Buttons
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await runTranslate()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isGenerating {
                                    ProgressView().controlSize(.small)
                                    Text("Трансляция архитектуры...")
                                } else {
                                    Image(systemName: "wand.and.stars")
                                    Text("Скомпилировать /plan 🪄")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                        .disabled(isGenerating)

                        Button {
                            saveAsNewIdea()
                        } label: {
                            Label(isSavedToIdeas ? "Сохранено!" : "В идеи 💡", systemImage: isSavedToIdeas ? "checkmark" : "plus.circle")
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
            VStack(alignment: .leading, spacing: 16) {
                // Quality Gauge Banner
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(qualityColor)
                                .frame(width: 8, height: 8)
                            Text(selectedMode == "stitch" ? "Google Stitch Спецификация 🧵" : selectedMode == "edit" ? "Таргетированный эдит 🎯" : "Индекс плотности плана:")
                                .font(.caption.bold())
                            Text("\(qualityScore)%")
                                .font(.caption.monospaced().bold())
                                .foregroundStyle(qualityColor)
                        }
                        Text(selectedMode == "stitch" ? "Спецификация по стандарту enhance-prompt + design-md." : (selectedMode == "edit" ? "Хирургическое изменение конкретного узла без регрессий." : qualityDescription))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    if !generatedBlueprint.isEmpty {
                        Button {
                            copyBlueprint()
                        } label: {
                            Label(isCopied ? "Скопировано!" : (selectedMode == "stitch" ? "Копировать для Stitch 🧵" : "Скопировать план 📋"), systemImage: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Output Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Инженерный план Antigravity")
                        .font(.headline)

                    if generatedBlueprint.isEmpty {
                        ContentUnavailableView("Готовый план появится здесь", systemImage: "doc.text.magnifyingglass", description: Text("Введите идею слева и нажмите «Скомпилировать /plan»."))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        TextEditor(text: $generatedBlueprint)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            .padding(20)
            .frame(minWidth: 360, idealWidth: 440)
        }
    }

    private var qualityColor: Color {
        if qualityScore >= 80 { return .green }
        if qualityScore >= 50 { return .orange }
        return .red
    }

    private var qualityDescription: String {
        if qualityScore >= 80 { return "Высокая точность: стек, дизайн-система и скиллы сбалансированы." }
        if qualityScore >= 50 { return "Базовая спецификация: рекомендуется уточнить детали идеи." }
        return "Минимальный ввод: добавьте описание ключевого сценария."
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

    private func runTranslate() async {
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
            } else {
                generatedBlueprint = try await AIGenerator.generateSpecification(
                    title: cleanTitle,
                    concept: rawPrompt,
                    platform: selectedPlatform,
                    style: selectedStyle,
                    apiKey: geminiApiKey,
                    provider: provider,
                    modelName: aiProvider == "Local Ollama" ? ollamaModel : geminiModel,
                    ollamaEndpoint: ollamaEndpoint
                )
            }
            NSSound.beep()
        } catch {
            errorMessage = error.localizedDescription
            generatedBlueprint = compileLocally()
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
