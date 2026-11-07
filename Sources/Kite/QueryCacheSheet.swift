import SwiftUI
import KiteKit

struct QueryCacheSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (QUERY_CACHE.md)"
        case cacheWrapper = "Кэш-обертка (queryCache.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var caches: [QueryCacheConfig] {
        QueryCacheStudio.starterCaches
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return QueryCacheStudio.generateQueryCacheMarkdown(title: title, caches: caches)
        case .cacheWrapper:
            return QueryCacheStudio.generateCacheAsideSnippet(caches: caches)
        case .prompt:
            return QueryCacheStudio.generatePromptDirective(caches: caches)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "cylinder.split.1x2.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Студия двухуровневого кэширования запросов (Query Cache Studio)")
                        .font(.headline)
                    Text("L1 In-Memory LRU, L2 Distributed Redis, Cache-Aside и инвалидация тегов")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Закрыть", action: onDismiss)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            HSplitView {
                // Left: Caches List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Кэшируемые запросы (\(caches.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(caches) { c in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(c.queryKey)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text("L1: \(c.l1TtlSeconds)s / L2: \(c.l2TtlSeconds)s")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Паттерн: \(c.strategy)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text("Теги: \(c.invalidationTags.joined(separator: ", "))")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.primary)

                                    HStack {
                                        Text(c.stalenessTolerance)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 360)

                // Right: Generated Spec & Snippets
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("Режим просмотра", selection: $activeTab) {
                            ForEach(OutputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(currentText, forType: .string)
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isCopied = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано" : "Копировать")
                            }
                        }
                    }

                    TextEditor(text: .constant(currentText))
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(16)
                .frame(minWidth: 460, idealWidth: 500)
            }
        }
        .frame(minWidth: 760, idealWidth: 800, minHeight: 520, idealHeight: 560)
    }
}
