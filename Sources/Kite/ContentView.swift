import SwiftData
import SwiftUI
import KiteKit
import AppKit

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            switch model.sidebar {
            case .aiChat:
                AIChatView()
            case .translator:
                PromptTranslatorView()
            case .skills:
                SkillsCatalogView()
            case .winSync:
                WindowsSyncView()
            case .canvas:
                InfiniteCanvasView()
            case .designLab:
                DesignLabView()
            case .inspirations:
                InspirationGalleryView()
            case .styles:
                HSplitView {
                    StylesCatalogView()
                        .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
                    ItemDetail()
                        .frame(minWidth: 400, maxWidth: .infinity)
                }
            default:
                HSplitView {
                    ItemList(page: model.sidebar ?? .all)
                        .frame(minWidth: 260, idealWidth: 300, maxWidth: 380)
                    ItemDetail()
                        .frame(minWidth: 400, maxWidth: .infinity)
                }
            }
        }
        .task {
            SeedData.insertIfRequested(into: model)
            SelfTest.runIfRequested(model: model)
            Snapshot.runIfRequested(model: model, openSettings: openSettings)
        }
    }

    private var sidebar: some View {
        @Bindable var model = model
        return List(selection: $model.sidebar) {
            Section("Идеи и проекты") {
                ForEach([SidebarItem.all, .inProgress, .completed, .starred]) { page in
                    sidebarRow(page)
                }
            }

            Section("Студия Antigravity") {
                ForEach([SidebarItem.aiChat, .translator, .skills, .winSync]) { page in
                    sidebarRow(page)
                }
            }

            Section("Дизайн и референсы") {
                ForEach([SidebarItem.canvas, .designLab, .inspirations, .styles]) { page in
                    sidebarRow(page)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
    }

    private func sidebarRow(_ page: SidebarItem) -> some View {
        Label {
            Text(page.title)
                .font(.body)
        } icon: {
            Image(systemName: page.symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(model.sidebar == page ? Color.accentColor : Color.secondary)
                .frame(width: 16, alignment: .center)
        }
        .tag(page)
    }
}

struct ItemList: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @State private var searchText = ""
    let page: SidebarItem

    private var visible: [Item] {
        let filtered: [Item]
        switch page {
        case .starred:
            filtered = items.filter(\.isStarred)
        case .inProgress:
            filtered = items.filter { $0.status == "in_progress" }
        case .completed:
            filtered = items.filter { $0.status == "completed" }
        default:
            filtered = items
        }

        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return filtered
        }
        let ranked: [(item: Item, score: Int)] = filtered.compactMap { item in
            let fields = [
                ItemSearch.Field(item.title, weight: 5),
                ItemSearch.Field(item.tags, weight: 3),
                ItemSearch.Field(item.concept, weight: 2),
                ItemSearch.Field(item.style, weight: 1),
                ItemSearch.Field(item.platform, weight: 1)
            ]
            guard let score = ItemSearch.score(query: searchText, fields: fields) else { return nil }
            return (item, score)
        }
        return ranked.sorted { $0.score > $1.score }.map(\.item)
    }

    var body: some View {
        @Bindable var model = model
        List(visible, selection: $model.selection) { item in
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: item.status == "completed" ? "checkmark.circle.fill" : (item.status == "in_progress" ? "bolt.circle.fill" : "circle"))
                        .foregroundStyle(item.status == "completed" ? Color.green : (item.status == "in_progress" ? Color.blue : Color.secondary))
                        .font(.system(size: 13))

                    Text(searchHighlighted(item.title, query: searchText))
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    if item.isStarred {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 11))
                    }
                }

                HStack(spacing: 8) {
                    Text(item.platform)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())

                    Text(item.style)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !item.concept.isEmpty {
                    Text(searchHighlighted(item.concept, query: searchText))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
            .tag(item.id)
            .contextMenu {
                Button(item.isStarred ? "Убрать из избранного" : "В избранное") {
                    item.isStarred.toggle()
                }
                Button("Статус: В планах") { item.status = "backlog" }
                Button("Статус: В разработке") { item.status = "in_progress" }
                Button("Статус: Готово") { item.status = "completed" }
                Divider()
                Button("Удалить", role: .destructive) { context.delete(item) }
            }
        }
        .searchable(text: $searchText, prompt: "Поиск идей...")
        .overlay {
            if visible.isEmpty {
                ContentUnavailableView(
                    "Нет идей",
                    systemImage: page.symbol,
                    description: Text("Нажмите ⌘N или кнопку «+», чтобы зафиксировать задумку.")
                )
            }
        }
        .navigationTitle(page.title)
        .toolbar {
            ToolbarItem {
                Button {
                    QuickCaptureManager.shared.show()
                } label: {
                    Label("Быстрый захват", systemImage: "sparkles")
                }
                .help("Быстрый захват идеи (Command-Shift-K)")
            }
            ToolbarItem {
                Button("Новая идея", systemImage: "plus") {
                    model.addItem(title: "Новый проект", concept: "Опишите здесь ключевой сценарий...")
                }
                .help("Создать идею (Command-N)")
            }
        }
    }
}

struct ItemDetail: View {
    @Environment(AppModel.self) private var model
    @Query private var items: [Item]
    @State private var isCopied = false
    @State private var scaffoldSuccessPath: String?
    @State private var isGeneratingAI = false
    @State private var aiError: String?
    @State private var exportSheetContent: String?
    @State private var exportSheetTitle: String = ""

    @AppStorage("ai_provider") private var aiProvider = "Gemini API"
    @AppStorage("gemini_api_key") private var geminiApiKey = ""
    @AppStorage("gemini_model") private var geminiModel = GeminiClient.defaultModel
    @AppStorage("ollama_endpoint") private var ollamaEndpoint = "http://localhost:11434/api/generate"
    @AppStorage("ollama_model") private var ollamaModel = "llama3"

    private let platforms = ["Web", "Mobile", "Desktop"]
    private let styles = [
        "Editorial & Swiss Modern",
        "Linear & DevTool Cockpit",
        "Neo-Brutalism & Tactical",
        "Voxel & 3D Isometric"
    ]

    var body: some View {
        if let item = items.first(where: { $0.id == model.selection }) {
            @Bindable var item = item
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Bar
                    HStack(alignment: .center, spacing: 12) {
                        TextField("Название идеи", text: $item.title)
                            .font(.title2.bold())
                            .textFieldStyle(.plain)

                        Spacer()

                        Button {
                            item.isStarred.toggle()
                        } label: {
                            Image(systemName: item.isStarred ? "star.fill" : "star")
                                .foregroundStyle(item.isStarred ? .yellow : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }

                    // Metadata Selectors
                    HStack(spacing: 16) {
                        Picker("Статус", selection: $item.status) {
                            Text("В планах").tag("backlog")
                            Text("В разработке").tag("in_progress")
                            Text("Готово").tag("completed")
                        }
                        .pickerStyle(.menu)

                        Picker("Платформа", selection: $item.platform) {
                            ForEach(platforms, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Стиль", selection: $item.style) {
                            ForEach(styles, id: \.self) { s in
                                Text(s).tag(s)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Concept Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Концепция и сценарий (JTBD)")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        TextEditor(text: $item.concept)
                            .font(.body)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }

                    // Generator Actions
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            Task {
                                await generateSpecification(for: item)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isGeneratingAI {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("AI генерирует архитектуру...")
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Сгенерировать AI-спецификацию")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                        .disabled(isGeneratingAI)

                        HStack(spacing: 8) {
                            if !item.generatedPrompt.isEmpty {
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(item.generatedPrompt, forType: .string)
                                    NSSound.beep()
                                    isCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        isCopied = false
                                    }
                                } label: {
                                    Label(isCopied ? "Скопировано" : "Скопировать план", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                            }

                            Button {
                                scaffoldProject(for: item)
                            } label: {
                                Label("Развернуть проект", systemImage: "folder.badge.plus")
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                            .help("Создать папку проекта с README, SPEC, PLAN и git init")

                            Menu {
                                Button {
                                    let md = DesignExporter.generateStitchDesignMd(
                                        title: item.title,
                                        style: item.style,
                                        platform: item.platform,
                                        concept: item.concept
                                    )
                                    exportSheetTitle = "Google Stitch — DESIGN.md"
                                    exportSheetContent = md
                                } label: {
                                    Label("Экспорт в Google Stitch (DESIGN.md)", systemImage: "sparkles")
                                }

                                Button {
                                    let json = DesignExporter.generateFigmaTokensJson(
                                        title: item.title,
                                        style: item.style
                                    )
                                    exportSheetTitle = "Figma Design Tokens (W3C JSON)"
                                    exportSheetContent = json
                                } label: {
                                    Label("Экспорт в Figma (Tokens JSON)", systemImage: "paintpalette")
                                }

                                Button {
                                    let diag = DesignExporter.generateFigJamDiagram(
                                        title: item.title,
                                        concept: item.concept,
                                        style: item.style
                                    )
                                    exportSheetTitle = "FigJam Architecture Diagram"
                                    exportSheetContent = diag
                                } label: {
                                    Label("Схема для FigJam (Mermaid / Flowchart)", systemImage: "arrow.triangle.branch")
                                }
                            } label: {
                                Label("Экспорт", systemImage: "square.and.arrow.up")
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                            .help("Экспорт дизайн-системы и токенов в Google Stitch или Figma")
                        }
                    }

                    if let err = aiError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.red)
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(Color.red)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if let path = scaffoldSuccessPath {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green)
                            Text("Проект создан: \(URL(fileURLWithPath: path).lastPathComponent)")
                                .font(.caption.weight(.medium))
                            Spacer()
                            Button("Показать в Finder") {
                                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Generated Output
                    if !item.generatedPrompt.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Инженерный план Antigravity (/plan)")
                                .font(.headline)

                            TextEditor(text: $item.generatedPrompt)
                                .font(.system(.caption, design: .monospaced))
                                .frame(minHeight: 260)
                                .padding(8)
                                .background(Color(nsColor: .textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
                .padding(24)
            }
            .sheet(isPresented: Binding(
                get: { exportSheetContent != nil },
                set: { if !$0 { exportSheetContent = nil } }
            )) {
                exportSheetModal
            }
        } else {
            ContentUnavailableView("Выберите идею", systemImage: "lightbulb", description: Text("Выберите идею в списке слева или создайте новую."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func scaffoldProject(for item: Item) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Создать здесь"
        panel.message = "Выберите папку для размещения проекта «\(item.title)»"

        let devDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Developer", isDirectory: true)
        if FileManager.default.fileExists(atPath: devDir.path) {
            panel.directoryURL = devDir
        }

        if panel.runModal() == .OK, let targetURL = panel.url {
            do {
                let result = try ProjectScaffolder.scaffold(
                    at: targetURL,
                    title: item.title,
                    concept: item.concept,
                    platform: item.platform,
                    style: item.style,
                    planPrompt: item.generatedPrompt,
                    createGitBranch: true
                )
                item.status = "in_progress"
                scaffoldSuccessPath = result.directory.path
                NSSound.beep()
                NSWorkspace.shared.selectFile(result.directory.path, inFileViewerRootedAtPath: "")
            } catch {
                KiteLog.app.error("Failed to scaffold project: \(error.localizedDescription)")
            }
        }
    }

    private func generateSpecification(for item: Item) async {
        isGeneratingAI = true
        aiError = nil
        defer { isGeneratingAI = false }

        let provider: AIProvider
        switch aiProvider {
        case "Local Ollama": provider = .localOllama
        case "Local Blueprint (Offline)": provider = .localCompiler
        default: provider = .gemini
        }

        do {
            let result = try await AIGenerator.generateSpecification(
                title: item.title,
                concept: item.concept,
                platform: item.platform,
                style: item.style,
                apiKey: geminiApiKey,
                provider: provider,
                modelName: aiProvider == "Local Ollama" ? ollamaModel : geminiModel,
                ollamaEndpoint: ollamaEndpoint
            )
            item.generatedPrompt = result
            NSSound.beep()
        } catch {
            aiError = error.localizedDescription
        }
    }

    private var exportSheetModal: some View {
        VStack(spacing: 16) {
            HStack {
                Text(exportSheetTitle)
                    .font(.title3.bold())
                Spacer()
                Button("Закрыть") {
                    exportSheetContent = nil
                }
                .buttonStyle(.bordered)
            }

            TextEditor(text: Binding(
                get: { exportSheetContent ?? "" },
                set: { exportSheetContent = $0 }
            ))
            .font(.system(.caption, design: .monospaced))
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Button("Скопировать в буфер") {
                    if let text = exportSheetContent {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                        NSSound.beep()
                    }
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button("Сохранить файл на диск") {
                    saveExportFile()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(minWidth: 540, minHeight: 460)
    }

    private func saveExportFile() {
        guard let content = exportSheetContent else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        if exportSheetTitle.contains("Stitch") {
            savePanel.nameFieldStringValue = "DESIGN.md"
        } else if exportSheetTitle.contains("Figma") {
            savePanel.nameFieldStringValue = "tokens.json"
        } else {
            savePanel.nameFieldStringValue = "architecture.mmd"
        }
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
            NSSound.beep()
            exportSheetContent = nil
        }
    }
}

struct StylesCatalogView: View {
    @Environment(AppModel.self) private var model

    struct DesignStyleItem: Identifiable {
        let id: String
        let title: String
        let description: String
        let accentHex: String
        let tags: [String]
    }

    let styles: [DesignStyleItem] = [
        .init(id: "swiss", title: "Editorial & Swiss Modern", description: "Строгая модульная сетка, крупная акцидентная антиква, книжные поля, теплый бумажный фон.", accentHex: "#1C1B18", tags: ["Editorial", "Books", "Minimalism"]),
        .init(id: "linear", title: "Linear & DevTool Cockpit", description: "Инженерная плотность, тёмный графит, моноширинный акцент, индикаторы статуса в 1 пиксель.", accentHex: "#5E6AD2", tags: ["DevTools", "Keyboard-first", "Dense"]),
        .init(id: "brutalism", title: "Neo-Brutalism & Tactical", description: "Черные границы 2-3px, смелые тени со смещением, контрастные бейджи, тактильные кнопки.", accentHex: "#D97757", tags: ["Raw", "Tactical", "High-contrast"]),
        .init(id: "voxel", title: "Voxel & 3D Isometric", description: "Изометрические воксельные сцены, мягкие тени Ambient Occlusion, игровая осязаемость.", accentHex: "#10B981", tags: ["3D", "Isometric", "Playful"])
    ]

    var body: some View {
        List(styles) { style in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)

                    Text(style.title)
                        .font(.headline)
                }

                Text(style.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 4) {
                    ForEach(style.tags, id: \.self) { t in
                        Text(t)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Button("Использовать") {
                        model.sidebar = .all
                        model.addItem(title: "Проект в стиле \(style.title)", concept: "Разработка экрана в эстетике \(style.title)", style: style.title)
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Стили и токены")
    }
}
