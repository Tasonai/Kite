import SwiftUI
import KiteKit

struct DocStudioSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false
    @State private var selectedEndpointIndex: Int = 0

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (DOCUMENTATION.md)"
        case curl = "cURL Playground"
        case typescript = "TypeScript SDK"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var endpoints: [ApiDocEndpoint] {
        DocStudio.starterEndpoints
    }

    private var currentText: String {
        let ep = endpoints.indices.contains(selectedEndpointIndex) ? endpoints[selectedEndpointIndex] : endpoints[0]
        switch activeTab {
        case .markdown:
            return DocStudio.generateDocMarkdown(title: title, endpoints: endpoints)
        case .curl:
            return DocStudio.generateCurlSnippet(endpoint: ep)
        case .typescript:
            return DocStudio.generateTypeScriptSnippet(endpoint: ep)
        case .prompt:
            return DocStudio.generatePromptDirective(endpoints: endpoints)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Интерактивная студия документации API (Doc Studio)")
                        .font(.headline)
                    Text("Генератор документации (Mintlify/Fumadocs/Nextra), playground сниппеты запросов и TypeScript-типы")
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
                // Left: Endpoints List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Эндпоинты API (\(endpoints.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(endpoints.indices, id: \.self) { idx in
                                let ep = endpoints[idx]
                                let isSelected = selectedEndpointIndex == idx
                                Button {
                                    selectedEndpointIndex = idx
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(ep.method)
                                                .font(.caption2.bold().monospaced())
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(ep.method == "GET" ? Color.blue.opacity(0.12) : Color.green.opacity(0.12))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))

                                            Text(ep.path)
                                                .font(.caption.monospaced())
                                            Spacer()
                                        }

                                        Text(ep.summary)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
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
