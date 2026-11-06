import SwiftUI
import KiteKit

struct ThreatModelerSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (SECURITY.md)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var threats: [SecurityThreat] {
        ThreatModeler.starterThreats
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return ThreatModeler.generateSecurityMarkdown(title: title, threats: threats)
        case .prompt:
            return ThreatModeler.generatePromptDirective(threats: threats)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Моделирование угроз и OWASP Защитник (Threat Modeler)")
                        .font(.headline)
                    Text("Контроль авторизации IDOR, защита вебхуков, барьер от SSRF и лимиты запросов")
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
                // Left: Threats List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Идентифицированные угрозы (\(threats.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(threats) { t in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(t.threatName)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text(t.severity.uppercased())
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(t.severity == "Critical" ? Color.red.opacity(0.12) : Color.orange.opacity(0.12))
                                            .foregroundStyle(t.severity == "Critical" ? Color.red : Color.orange)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text(t.category)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text(t.mitigationPattern)
                                        .font(.caption2)
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
