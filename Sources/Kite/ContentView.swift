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
        } content: {
            if model.sidebar == .styles {
                StylesCatalogView()
                    .navigationSplitViewColumnWidth(min: 280, ideal: 340)
            } else {
                ItemList(page: model.sidebar ?? .all)
                    .navigationSplitViewColumnWidth(min: 280, ideal: 340)
            }
        } detail: {
            ItemDetail()
        }
        .task {
            SeedData.insertIfRequested(into: model)
            SelfTest.runIfRequested(model: model)
            Snapshot.runIfRequested(model: model, openSettings: openSettings)
        }
    }

    private var sidebar: some View {
        @Bindable var model = model
        return List(SidebarItem.allCases, selection: $model.sidebar) { page in
            Label(page.title, systemImage: page.symbol)
                .tag(page)
        }
        .navigationSplitViewColumnWidth(min: 190, ideal: 220)
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
        case .all, .styles:
            filtered = items
        }

        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return filtered
        }
        let q = searchText.lowercased()
        return filtered.filter {
            $0.title.lowercased().contains(q) ||
            $0.concept.lowercased().contains(q) ||
            $0.style.lowercased().contains(q)
        }
    }

    var body: some View {
        @Bindable var model = model
        List(visible, selection: $model.selection) { item in
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: item.status == "completed" ? "checkmark.circle.fill" : (item.status == "in_progress" ? "bolt.circle.fill" : "circle"))
                        .foregroundStyle(item.status == "completed" ? Color.green : (item.status == "in_progress" ? Color.blue : Color.secondary))
                        .font(.system(size: 13))

                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    if item.isStarred {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 11))
                    }
                }

                HStack(spacing: 6) {
                    Text(item.platform)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())

                    Text(item.style)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !item.concept.isEmpty {
                    Text(item.concept)
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
                            Text("📌 В планах").tag("backlog")
                            Text("🚀 В разработке").tag("in_progress")
                            Text("✅ Готово").tag("completed")
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
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Concept Input
                    VStack(alignment: .leading, spacing: 6) {
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

                    // Generator Action
                    HStack(spacing: 12) {
                        Button {
                            item.generatedPrompt = PromptCompiler.compileBlueprint(
                                title: item.title,
                                concept: item.concept,
                                platform: item.platform,
                                style: item.style
                            )
                        } label: {
                            Label("Сгенерировать Antigravity Blueprint 🪄", systemImage: "sparkles")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)

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
                                Label(isCopied ? "Скопировано!" : "Скопировать план 📋", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Generated Output
                    if !item.generatedPrompt.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
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
        } else {
            ContentUnavailableView("Выберите идею", systemImage: "lightbulb", description: Text("Выберите идею в списке слева или создайте новую."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            VStack(alignment: .leading, spacing: 6) {
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
            .padding(.vertical, 6)
        }
        .navigationTitle("Стили и токены")
    }
}
