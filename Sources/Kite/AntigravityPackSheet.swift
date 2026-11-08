import SwiftUI
import KiteKit

struct AntigravityPackSheet: View {
    let title: String
    let concept: String
    let platform: String
    let style: String
    let architectureMermaid: String?
    let onDismiss: () -> Void

    @State private var selectedTabIndex: Int = 0
    @State private var isCopied: Bool = false
    @State private var copiedNotice: String? = nil
    @State private var completedTasks: Set<String> = []
    @State private var watchedDirectoryURL: URL? = nil
    @State private var autoDetectedCount: Int = 0

    private var waves: [AntigravityWave] {
        AntigravityPackGenerator.buildWaves(
            title: title,
            concept: concept,
            platform: platform,
            style: style,
            architectureMermaid: architectureMermaid
        )
    }

    private var readinessReport: AntigravityReadinessReport {
        AntigravityReadinessLinter.evaluate(
            title: title,
            concept: concept,
            platform: platform,
            style: style
        )
    }

    private var antigravityMDContent: String {
        AntigravityPackGenerator.generateAntigravityMD(
            title: title,
            concept: concept,
            platform: platform,
            style: style,
            architectureMermaid: architectureMermaid
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 12) {
                Image(systemName: "bolt.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Пакет для Antigravity")
                            .font(.headline)
                        
                        Text("\(readinessReport.score)% готовность")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(readinessReport.isFlightReady ? Color.green.opacity(0.16) : Color.orange.opacity(0.16))
                            .foregroundStyle(readinessReport.isFlightReady ? Color.green : Color.orange)
                            .clipShape(Capsule())
                    }

                    Text("Пошаговые волны (Waves) и токено-эффективный контекст для вайбкодинга")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Navigation tabs
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Button {
                        selectedTabIndex = index
                    } label: {
                        HStack(spacing: 4) {
                            Text("Волна \(index + 1)")
                                .font(.caption.weight(selectedTabIndex == index ? .semibold : .regular))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTabIndex == index ? Color.accentColor.opacity(0.14) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 16)

                Button {
                    selectedTabIndex = 4
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                        Text("ANTIGRAVITY.md")
                    }
                    .font(.caption.weight(selectedTabIndex == 4 ? .semibold : .regular))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedTabIndex == 4 ? Color.accentColor.opacity(0.14) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button {
                    selectedTabIndex = 5
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                        Text("Чек-лист готовности")
                    }
                    .font(.caption.weight(selectedTabIndex == 5 ? .semibold : .regular))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedTabIndex == 5 ? Color.accentColor.opacity(0.14) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Spacer()

                if let notice = copiedNotice {
                    Text(notice)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.green)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if let watchedURL = watchedDirectoryURL {
                HStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(Color.green)
                    Text("Live Watcher:")
                        .font(.caption.bold())
                    Text(watchedURL.lastPathComponent)
                        .font(.caption.monospaced())
                    Text("Обнаружено \(autoDetectedCount) задач")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        rescanDirectory()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Сканировать")
                        }
                        .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))

                Divider()
            }

            // Main Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if selectedTabIndex >= 0 && selectedTabIndex < 4 {
                        waveDetailView(waves[selectedTabIndex])
                    } else if selectedTabIndex == 4 {
                        antigravityMDView
                    } else {
                        readinessChecklistView
                    }
                }
                .padding(16)
            }

            Divider()

            // Bottom Actions Bar
            HStack(spacing: 12) {
                Button {
                    copyCurrentContent()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Скопировано" : copyButtonLabel)
                    }
                    .font(.body.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)

                if let mmd = architectureMermaid, !mmd.isEmpty {
                    Button {
                        copyMermaid(mmd)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                            Text("Скопировать Mermaid граф")
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    copyAllWaves()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.stack.3d.up")
                        Text("Скопировать все 4 волны")
                    }
                }
                .buttonStyle(.bordered)

                Button {
                    exportToProjectFolder()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                        Text("Экспорт в проект...")
                    }
                }
                .buttonStyle(.bordered)

                Button {
                    selectFolderForWatching()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: watchedDirectoryURL != nil ? "gauge.with.needle.fill" : "folder.badge.gearshape")
                        Text(watchedDirectoryURL != nil ? "Live Watcher" : "Подключить Watcher...")
                    }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 720, idealWidth: 840, minHeight: 520, idealHeight: 640)
    }

    private var copyButtonLabel: String {
        switch selectedTabIndex {
        case 0...3:
            return "Скопировать промпт Волны \(selectedTabIndex + 1)"
        case 4:
            return "Скопировать ANTIGRAVITY.md"
        default:
            return "Скопировать рекомендации"
        }
    }

    @ViewBuilder
    private func waveDetailView(_ wave: AntigravityWave) -> some View {
        let waveTasks = wave.scope
        let completedInWave = waveTasks.filter { completedTasks.contains("\($0)_\(wave.id)") }.count

        VStack(alignment: .leading, spacing: 16) {
            // Header card
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(wave.title)
                            .font(.title3.bold())

                        if completedInWave == waveTasks.count && !waveTasks.isEmpty {
                            Text("Завершена")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.16))
                                .foregroundStyle(Color.green)
                                .clipShape(Capsule())
                        }
                    }

                    Text(wave.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Text("\(completedInWave)/\(waveTasks.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        Text(wave.estimatedTokens)
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Two-column Scope and Negative Constraints
            HStack(alignment: .top, spacing: 12) {
                // Allowed Scope with Interactive Checkboxes
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checklist")
                            .foregroundStyle(Color.accentColor)
                        Text("Критерии готовности (клик для отметки)")
                            .font(.caption.bold())
                    }

                    ForEach(wave.scope, id: \.self) { item in
                        let taskKey = "\(item)_\(wave.id)"
                        let isDone = completedTasks.contains(taskKey)

                        Button {
                            if isDone {
                                completedTasks.remove(taskKey)
                            } else {
                                completedTasks.insert(taskKey)
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                                    .font(.caption)

                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(isDone ? .secondary : .primary)
                                    .strikethrough(isDone, color: .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Negative Scope (Token Shields)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "nosign")
                            .foregroundStyle(Color.orange)
                        Text("Чего НЕ делать агенту (экономия)")
                            .font(.caption.bold())
                    }

                    ForEach(wave.negativeScope, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("-")
                                .foregroundStyle(Color.orange)
                            Text(item)
                                .font(.caption)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Generated Prompt Preview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Промпт для Antigravity:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Вставьте в чат Antigravity")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                ScrollView {
                    Text(wave.prompt)
                        .font(.system(.body, design: .monospaced)) // grid: ok font
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 240)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private var antigravityMDView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Файл ANTIGRAVITY.md")
                        .font(.headline)
                    Text("Помещается в корень проекта для мгновенного чтения агентом Antigravity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            ScrollView {
                Text(antigravityMDContent)
                    .font(.system(.body, design: .monospaced)) // grid: ok font
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 400)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var readinessChecklistView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Аудит готовности идеи к вайбкодингу")
                        .font(.headline)
                    Text("Чем точнее заполнены параметры, тем меньше токенов и итераций потратит Antigravity.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(readinessReport.score) / 100")
                    .font(.title2.bold())
                    .foregroundStyle(readinessReport.isFlightReady ? Color.green : Color.orange)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 8) {
                ForEach(readinessReport.items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.isPassed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(item.isPassed ? Color.green : Color.orange)
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.body.weight(.medium))
                            Text(item.suggestion)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func copyCurrentContent() {
        let textToCopy: String
        switch selectedTabIndex {
        case 0...3:
            textToCopy = waves[selectedTabIndex].prompt
        case 4:
            textToCopy = antigravityMDContent
        default:
            textToCopy = readinessReport.items.map { "- \($0.title): \($0.suggestion)" }.joined(separator: "\n")
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToCopy, forType: .string)
        notifyCopied("Скопировано в буфер")
    }

    private func copyMermaid(_ mmd: String) {
        let text = "```mermaid\n\(mmd)\n```"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        notifyCopied("Mermaid граф скопирован")
    }

    private func copyAllWaves() {
        let text = waves.map { "\($0.title)\n\($0.prompt)" }.joined(separator: "\n\n---\n\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        notifyCopied("Все 4 волны скопированы")
    }

    private func notifyCopied(_ msg: String) {
        isCopied = true
        copiedNotice = msg
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
            copiedNotice = nil
        }
    }

    private func selectFolderForWatching() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Подключить"
        panel.message = "Выберите корневую папку проекта для отслеживания прогресса"
        if panel.runModal() == .OK, let folder = panel.url {
            watchedDirectoryURL = folder
            rescanDirectory()
        }
    }

    private func rescanDirectory() {
        guard let folder = watchedDirectoryURL else { return }
        let snapshot = ProjectWatcherService.analyzeDirectory(at: folder, waves: waves)
        for key in snapshot.completedTaskKeys {
            completedTasks.insert(key)
        }
        autoDetectedCount = snapshot.completedTaskKeys.count
        notifyCopied("Обнаружено \(autoDetectedCount) готовых задач (\(snapshot.overallPercentage)% проекта)")
    }

    private func exportToProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Выбрать папку"
        panel.message = "Выберите корневую папку проекта для экспорта манифестов"
        if panel.runModal() == .OK, let folder = panel.url {
            do {
                try antigravityMDContent.write(to: folder.appendingPathComponent("ANTIGRAVITY.md"), atomically: true, encoding: .utf8)
                let indexing = IndexOptimizer.generateIndexMarkdown(title: title, indexes: IndexOptimizer.starterRecommendations)
                try indexing.write(to: folder.appendingPathComponent("INDEXING.md"), atomically: true, encoding: .utf8)
                let routing = ModelRouter.generateRoutingMarkdown(title: title, routes: ModelRouter.starterRoutes)
                try routing.write(to: folder.appendingPathComponent("MODEL_ROUTING.md"), atomically: true, encoding: .utf8)
                watchedDirectoryURL = folder
                rescanDirectory()
                notifyCopied("Манифесты сохранены и подключен Live Watcher")
            } catch {
                notifyCopied("Ошибка экспорта: \(error.localizedDescription)")
            }
        }
    }
}
