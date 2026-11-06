import SwiftUI
import KiteKit

struct WorkstreamSplitterSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputFormat = .markdown
    @State private var isCopied: Bool = false

    enum OutputFormat: String, CaseIterable, Identifiable {
        case markdown = "Манифест (WORKSTREAMS.md)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var workstreams: [Workstream] {
        WorkstreamSplitter.defaultWorkstreams(title: title)
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return WorkstreamSplitter.generateWorkstreamsMarkdown(title: title, workstreams: workstreams)
        case .prompt:
            return WorkstreamSplitter.generateAntigravityPrompt(workstreams: workstreams)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.pull")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Матрица параллельных потоков (Workstream Splitter)")
                        .font(.headline)
                    Text("Разбиение проекта на изолированные зоны файлов для параллельных субагентов без конфликтов")
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

            HSplitView {
                // Left: Workstream Cards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Параллельные воркстримы (\(workstreams.count)):")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(workstreams) { ws in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(ws.name)
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.accentColor)
                                        Spacer()
                                    }

                                    Text("Роль: \(ws.subagentRole)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.primary)

                                    Text("Файлы: \(ws.targetFiles.joined(separator: ", "))")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)

                                    Text(ws.directive)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
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
                            ForEach(OutputFormat.allCases) { fmt in
                                Text(fmt.rawValue).tag(fmt)
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
                            .font(.system(size: 11, design: .monospaced)) // grid: ok
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
