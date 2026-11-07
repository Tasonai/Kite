import SwiftUI
import KiteKit

struct WebhookDispatcherSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (OUTGOING_WEBHOOKS.md)"
        case worker = "Диспетчер (webhookDispatcher.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var webhooks: [OutgoingWebhookConfig] {
        WebhookDispatcherStudio.starterWebhooks
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return WebhookDispatcherStudio.generateDispatcherMarkdown(title: title, webhooks: webhooks)
        case .worker:
            return WebhookDispatcherStudio.generateWorkerSnippet(webhooks: webhooks)
        case .prompt:
            return WebhookDispatcherStudio.generatePromptDirective(webhooks: webhooks)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Студия диспетчера исходящих вебхуков (Webhook Dispatcher)")
                        .font(.headline)
                    Text("Очередь доставки At-Least-Once, подпись HMAC-SHA256 и экспоненциальный бэкофф")
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
                // Left: Webhooks List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Исходящие хуки (\(webhooks.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(webhooks) { w in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(w.targetSystem)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text("\(w.timeoutMs)ms")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.teal.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("События: \(w.eventTriggers.joined(separator: ", "))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text(w.signingAlgorithm)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.primary)

                                    HStack {
                                        Text("Бэкофф: \(w.retrySchedule)")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
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
