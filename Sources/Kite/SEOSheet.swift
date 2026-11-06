import SwiftUI
import KiteKit

struct SEOSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (SEO.md)"
        case nextMetadata = "Метаданные (layout.tsx)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var configs: [SEOTagConfig] {
        SEOStudio.starterConfigs
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return SEOStudio.generateSEOMarkdown(title: title, configs: configs)
        case .nextMetadata:
            return SEOStudio.generateNextMetadataSnippet(
                title: "\(title) - AI Architecture Cockpit",
                description: "Native macOS architecture canvas and pre-flight cockpit for Antigravity vibe coding."
            )
        case .prompt:
            return SEOStudio.generatePromptDirective(configs: configs)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "globe.desk.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Студия SEO, OpenGraph и микроразметки (SEO Studio)")
                        .font(.headline)
                    Text("Динамические метаданные Next.js 15, карточки OpenGraph/Twitter и JSON-LD Schema.org")
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
                // Left: SEO Tags List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Конфигурация тегов (\(configs.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(configs) { cfg in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(cfg.tagType)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                    }

                                    Text(cfg.targetPurpose)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text(cfg.tagValue)
                                        .font(.caption2.monospaced())
                                        .lineLimit(2)
                                        .foregroundStyle(.primary)
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
