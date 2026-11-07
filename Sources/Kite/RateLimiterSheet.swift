import SwiftUI
import KiteKit

struct RateLimiterSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (RATE_LIMITING.md)"
        case middleware = "Edge Middleware (rateLimiter.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var rules: [RateLimitRuleConfig] {
        RateLimiterStudio.starterRules
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return RateLimiterStudio.generateRateLimitMarkdown(title: title, rules: rules)
        case .middleware:
            return RateLimiterStudio.generateRateLimitMiddleware(rules: rules)
        case .prompt:
            return RateLimiterStudio.generatePromptDirective(rules: rules)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Студия защиты от DDoS и троттлинга (Rate Limiter Studio)")
                        .font(.headline)
                    Text("Алгоритмы Sliding Window, Token Bucket, квоты маршрутов и Upstash Redis")
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
                // Left: Rules List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Маршруты под защитой (\(rules.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(rules) { r in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(r.routePattern)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text("\(r.limit) req / \(r.windowSeconds)s")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Алгоритм: \(r.algorithm)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    HStack {
                                        Text(r.backend)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(r.actionOnExceed)
                                            .font(.caption2.bold())
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
