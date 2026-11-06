import SwiftUI
import KiteKit

struct WebhookSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (WEBHOOKS.md)"
        case handler = "Обработчик (route.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var webhooks: [WebhookDefinition] {
        WebhookSimulator.starterWebhooks
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return WebhookSimulator.generateWebhooksMarkdown(title: title, webhooks: webhooks)
        case .handler:
            return WebhookSimulator.generateVerificationHandlerSnippet(webhooks: webhooks)
        case .prompt:
            return WebhookSimulator.generatePromptDirective(webhooks: webhooks)
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
                    Text("Стенд интеграции и валидации вебхуков (Webhook Simulator)")
                        .font(.headline)
                    Text("Реестр входящих событий (Stripe, Clerk, GitHub), валидация HMAC-подписей и шаблоны роутеров")
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
                    Text("Входящие вебхуки (\(webhooks.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(webhooks) { w in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(w.eventName)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text(w.provider)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Заголовок: \(w.signatureHeader)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)

                                    Text("Алгоритм: \(w.verificationAlgorithm)")
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
