import SwiftUI
import KiteKit

struct VectorStoreSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (VECTOR_STORE.md)"
        case ddl = "Схема (pgvector.sql)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var configs: [VectorIndexConfig] {
        VectorStoreSpecifier.starterConfigs
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return VectorStoreSpecifier.generateVectorStoreMarkdown(title: title, configs: configs)
        case .ddl:
            return VectorStoreSpecifier.generatePgVectorDDL(configs: configs)
        case .prompt:
            return VectorStoreSpecifier.generatePromptDirective(configs: configs)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "point.3.filled.connected.triangle.path")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Спецификатор векторных БД и RAG (Vector Store Specifier)")
                        .font(.headline)
                    Text("Размер чанков, эмбеддинги text-embedding-004, HNSW-индексы pgvector и фильтрация тенантов")
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
                // Left: Collections List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Векторные коллекции (\(configs.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(configs) { c in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(c.collectionName)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text("\(c.dimensions)d")
                                            .font(.caption2.bold().monospaced())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Модель: \(c.embeddingModel)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 8) {
                                        Text("Чанк: \(c.chunkSizeTokens)т")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("Оверлап: \(c.chunkOverlapTokens)т")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(c.distanceMetric)
                                            .font(.caption2)
                                            .foregroundStyle(.primary)
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
                .frame(minWidth: 280, idealWidth: 300)

                // Right: Generated Spec
                VStack(spacing: 12) {
                    HStack {
                        Picker("", selection: $activeTab) {
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                isCopied = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано!" : "Копировать")
                            }
                            .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isCopied ? .green : .accentColor)
                    }

                    ScrollView {
                        Text(currentText)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 740, idealWidth: 800, minHeight: 520, idealHeight: 560)
    }
}
