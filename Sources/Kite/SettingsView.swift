import SwiftUI

/// The Settings window (Command-Comma). One tab per topic, at most about
/// six. Each tab is a grouped Form that sizes to its content, so the
/// window grows to fit and shows no scroll bar it does not need.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.settingsTab) {
            ForEach(SettingsTab.allCases) { tab in
                page(tab)
                    .tabItem { Label(tab.title, systemImage: tab.symbol) }
                    .tag(tab)
            }
        }
        .noInitialFocus()
    }

    @ViewBuilder
    private func page(_ tab: SettingsTab) -> some View {
        Form {
            switch tab {
            case .general: GeneralSettings()
            case .appearance: AppearanceSettings()
            case .ai: AISettingsView()
            case .sync: SyncSettingsView()
            }
        }
        .formStyle(.grouped)
        .fitsContent()
        .frame(width: 520)
    }
}

/// The Settings tabs. Snapshot mode walks through every case.
enum SettingsTab: String, CaseIterable, Identifiable {
    case general, appearance, ai, sync

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .ai: "AI & Models"
        case .sync: "Sync & Data"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .ai: "sparkles"
        case .sync: "arrow.triangle.2.circlepath"
        }
    }
}

struct AISettingsView: View {
    @AppStorage("ai_provider") private var aiProvider = "Gemini API"
    @AppStorage("gemini_api_key") private var geminiApiKey = ""
    @AppStorage("gemini_model") private var geminiModel = "gemini-2.5-flash"
    @AppStorage("ollama_endpoint") private var ollamaEndpoint = "http://localhost:11434/api/generate"
    @AppStorage("ollama_model") private var ollamaModel = "llama3"

    var body: some View {
        Section("Провайдер AI") {
            Picker("Движок генерации", selection: $aiProvider) {
                Text("Google Gemini API").tag("Gemini API")
                Text("Локальный Ollama").tag("Local Ollama")
                Text("Локальный компилятор (Офлайн)").tag("Local Blueprint (Offline)")
            }
            .pickerStyle(.radioGroup)
        }

        if aiProvider == "Gemini API" {
            Section("Настройки Gemini") {
                SecureField("Gemini API Key", text: $geminiApiKey)
                    .textFieldStyle(.roundedBorder)

                Picker("Модель", selection: $geminiModel) {
                    Text("gemini-2.5-flash (Быстрая, рекомендуемая)").tag("gemini-2.5-flash")
                    Text("gemini-2.5-pro (Глубокая архитектура)").tag("gemini-2.5-pro")
                }

                Text("Ключ сохраняется локально и используется только для прямой генерации спецификаций.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if aiProvider == "Local Ollama" {
            Section("Настройки Ollama") {
                TextField("Эндпоинт", text: $ollamaEndpoint)
                    .textFieldStyle(.roundedBorder)
                TextField("Имя модели (например, llama3 или qwen)", text: $ollamaModel)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct GeneralSettings: View {
    @AppStorage("confirmDelete") private var confirmDelete = true

    var body: some View {
        Section("Items") {
            Toggle("Ask before deleting items", isOn: $confirmDelete)
        }
    }
}

struct SyncSettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var syncStatus: String?

    var body: some View {
        Section("Экспорт и Импорт (JSON)") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Экспорт базы идей")
                        .font(.body)
                    Text("Сохранить все идеи в файл kite-ideas.json")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Экспорт JSON...") {
                    exportJSON()
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Импорт идей")
                        .font(.body)
                    Text("Загрузить идеи из kite-ideas.json")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Импорт JSON...") {
                    importJSON()
                }
            }

            if let status = syncStatus {
                Text(status)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
        }

        Section("P2P-Синхронизация с Windows (KiteWin)") {
            @AppStorage("windows_sync_endpoint") var winEndpoint = "http://127.0.0.1:24243"
            TextField("Адрес KiteWin (порт 24243)", text: $winEndpoint)
                .textFieldStyle(.roundedBorder)

            Text("Порт локального сервера Kite macOS: 24242. KiteWin слушает порт 24243.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("Локальное хранилище") {
            LabeledContent("SwiftData Store") {
                Text(Store.url.path)
                    .font(.system(.caption2, design: .monospaced))
                    .textSelection(.enabled)
            }
            Button("Показать хранилище в Finder") {
                NSWorkspace.shared.selectFile(Store.url.path, inFileViewerRootedAtPath: "")
            }
        }
    }

    private func exportJSON() {
        guard let data = model.exportIdeas() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "kite-ideas.json"
        panel.prompt = "Экспортировать"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
            syncStatus = "Экспортировано в \(url.lastPathComponent)"
            NSSound.beep()
        }
    }

    private func importJSON() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Импортировать"
        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url) {
                let count = model.importIdeas(from: data)
                syncStatus = "Импортировано идей: \(count)"
                NSSound.beep()
            }
        }
    }
}
