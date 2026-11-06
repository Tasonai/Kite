import SwiftUI
import KiteKit

struct IncidentCommanderSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (INCIDENTS.md)"
        case healthz = "Проба (healthz/route.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var actions: [RollbackAction] {
        IncidentCommander.starterActions
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return IncidentCommander.generateIncidentMarkdown(title: title, actions: actions)
        case .healthz:
            return IncidentCommander.generateHealthCheckRouteSnippet()
        case .prompt:
            return IncidentCommander.generatePromptDirective(actions: actions)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "cross.case.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("План реагирования на инциденты и откат (Incident Commander)")
                        .font(.headline)
                    Text("Проверки healthz, пошаговые сценарии отката DNS/БД/ENV и протокол аварийного восстановления")
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
                // Left: Actions List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Шаги аварийного отката (\(actions.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(actions) { a in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(a.phase)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text(a.subsystem)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.12))
                                            .foregroundStyle(Color.red)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Команда:")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text(a.rollbackCommand)
                                        .font(.caption2.monospaced())
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)

                                    Text("Проверка: \(a.verificationCheck)")
                                        .font(.caption2.monospaced())
                                        .lineLimit(1)
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
