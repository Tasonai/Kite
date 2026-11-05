import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct AIChatView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]

    @AppStorage("gemini_api_key") private var apiKey: String = ""
    @AppStorage("ai_provider") private var providerRaw: String = AIProvider.gemini.rawValue
    @AppStorage("gemini_model") private var modelName: String = "gemini-2.5-flash"
    @AppStorage("ollama_endpoint") private var ollamaEndpoint: String = "http://localhost:11434/api/chat"
    @AppStorage("ollama_model") private var ollamaModel: String = "llama3"

    @State private var inputPrompt: String = ""
    @State private var isThinking: Bool = false
    @State private var errorMessage: String?
    @State private var copiedId: UUID?
    @State private var exportSheetContent: String?
    @State private var exportSheetTitle: String = ""

    @State private var messages: [ChatMessageItem] = [
        ChatMessageItem(
            role: "assistant",
            content: """
            Привет! Я **Kite AI-Архитектор**

            Я помогу спроектировать архитектуру вашего продукта, подобрать стек, выстроить дизайн-систему по канонам **Apple HIG / Vercel** и подготовить экспорт в **Google Stitch** и **Figma**.

            С чего начнем? Выберите быстрый сценарий ниже или опишите вашу задумку:
            """
        )
    ]

    private let suggestions = [
        "Спроектируй SaaS-дашборд на React 19",
        "Создай дизайн-систему для Stitch и Figma",
        "Подбери стек для macOS меню-бар утилиты",
        "Составь архитектурную спецификацию /plan"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI-Архитектор & Copilot")
                            .font(.headline)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isThinking ? Color.orange : Color.green)
                                .frame(width: 8, height: 8)
                            Text(providerRaw == AIProvider.gemini.rawValue ? (modelName.isEmpty ? "gemini-2.5-flash" : modelName) : "Local Ollama")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Button {
                    messages = [
                        ChatMessageItem(
                            role: "assistant",
                            content: "История диалога очищена. Чем могу помочь в проектировании следующей фичи?"
                        )
                    ]
                } label: {
                    Label("Очистить", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Chat Messages Scroll Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }

                        if isThinking {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("AI-Архитектор думает...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }

                        if let err = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.red)
                                Text(err)
                                    .font(.caption)
                                    .foregroundStyle(Color.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Suggestions Bar
            if messages.count <= 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { s in
                            Button {
                                inputPrompt = s
                                sendMessage()
                            } label: {
                                Text(s)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                Divider()
            }

            // Bottom Input Controls
            HStack(spacing: 12) {
                TextField("Спросите AI-Архитектора о дизайне, кодовой базе или скиллах...", text: $inputPrompt)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    .onSubmit {
                        sendMessage()
                    }

                VoiceRecordButton { spokenText in
                    inputPrompt = spokenText
                }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputPrompt.trimmingCharacters(in: .whitespaces).isEmpty || isThinking ? Color.secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(inputPrompt.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .sheet(isPresented: Binding(
            get: { exportSheetContent != nil },
            set: { if !$0 { exportSheetContent = nil } }
        )) {
            exportSheetView
        }
    }

    private func messageBubble(_ msg: ChatMessageItem) -> some View {
        let isUser = msg.role == "user"
        return HStack(alignment: .top, spacing: 12) {
            if isUser { Spacer(minLength: 48) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                Text(LocalizedStringKey(msg.content))
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(isUser ? Color.white : Color.primary)
                    .textSelection(.enabled)
                    .padding(16)
                    .background(
                        isUser
                            ? Color.accentColor
                            : Color(nsColor: .controlBackgroundColor).opacity(0.85)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(isUser ? 0 : 0.15), lineWidth: 1)
                    )

                if !isUser && msg.content.count > 50 {
                    HStack(spacing: 8) {
                        Button {
                            createIdeaFromMessage(msg.content)
                        } label: {
                            Label("В идею", systemImage: "lightbulb")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            exportToStitch(from: msg.content)
                        } label: {
                            Label("В Stitch", systemImage: "sparkles")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            exportToFigma(from: msg.content)
                        } label: {
                            Label("В Figma", systemImage: "paintpalette")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            model.sidebar = .translator
                        } label: {
                            Label("В переводчик", systemImage: "wand.and.stars")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            copyText(msg.content, id: msg.id)
                        } label: {
                            Image(systemName: copiedId == msg.id ? "checkmark" : "doc.on.doc")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
            }

            if !isUser { Spacer(minLength: 48) }
        }
    }

    private var exportSheetView: some View {
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
                    saveFileToDisk()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(minWidth: 540, minHeight: 460)
    }

    private func sendMessage() {
        let text = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMsg = ChatMessageItem(role: "user", content: text)
        messages.append(userMsg)
        inputPrompt = ""
        isThinking = true
        errorMessage = nil

        let currentProvider = AIProvider(rawValue: providerRaw) ?? .gemini
        let key = apiKey
        let model = modelName
        let endpoint = ollamaEndpoint
        let history = messages
        let workspace = AIPrompts.ChatContext(ideas: items.prefix(12).map { item in
            let concept = item.concept.trimmingCharacters(in: .whitespacesAndNewlines)
            let brief = concept.isEmpty ? "" : ": " + String(concept.prefix(120))
            return "\(item.title) (\(item.platform), \(item.style))\(brief)"
        })

        Task {
            do {
                let reply = try await AIGenerator.chat(
                    messages: history,
                    apiKey: key,
                    provider: currentProvider,
                    modelName: model,
                    ollamaEndpoint: endpoint,
                    context: workspace
                )
                await MainActor.run {
                    messages.append(ChatMessageItem(role: "assistant", content: reply))
                    isThinking = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isThinking = false
                }
            }
        }
    }

    private func createIdeaFromMessage(_ content: String) {
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var title = "Архитектурная идея"
        if let first = lines.first {
            title = first.replacingOccurrences(of: "#", with: "")
                .replacingOccurrences(of: "*", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        model.sidebar = .all
        model.addItem(title: title, concept: content, platform: "Web", style: "Linear & DevTool Cockpit")
    }

    private func exportToStitch(from content: String) {
        let stitchMd = DesignExporter.generateStitchDesignMd(
            title: "Экспорт из Kite AI",
            style: "Linear & DevTool Cockpit",
            platform: "Web",
            concept: content
        )
        exportSheetTitle = "Google Stitch — DESIGN.md"
        exportSheetContent = stitchMd
    }

    private func exportToFigma(from content: String) {
        let figmaJson = DesignExporter.generateFigmaTokensJson(
            title: "Figma Token Spec",
            style: "Linear & DevTool Cockpit"
        )
        exportSheetTitle = "Figma Design Tokens — W3C Spec"
        exportSheetContent = figmaJson
    }

    private func saveFileToDisk() {
        guard let content = exportSheetContent else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        if exportSheetTitle.contains("Stitch") {
            savePanel.nameFieldStringValue = "DESIGN.md"
        } else {
            savePanel.nameFieldStringValue = "tokens.json"
        }
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
            NSSound.beep()
            exportSheetContent = nil
        }
    }

    private func copyText(_ text: String, id: UUID) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copiedId = id
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedId == id {
                copiedId = nil
            }
        }
    }
}
