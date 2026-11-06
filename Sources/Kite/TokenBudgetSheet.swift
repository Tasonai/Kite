import SwiftUI
import KiteKit

struct TokenBudgetSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (TOKEN_BUDGET.md)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var budgets: [FeatureTokenBudget] {
        TokenBudgeteer.starterBudgets
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return TokenBudgeteer.generateTokenBudgetMarkdown(title: title, budgets: budgets)
        case .prompt:
            return TokenBudgeteer.generatePromptDirective(budgets: budgets)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "creditcard.and.123")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Бюджетирование токенов, стоимости и задержек (Token Budgeteer)")
                        .font(.headline)
                    Text("Лимиты входных/выходных токенов Gemini, оценка стоимости запросов и пороги задержки")
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
                // Left: Budgets List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Лимиты фичей (\(budgets.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(budgets) { b in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(b.featureName)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text(b.costPerThousandCalls)
                                            .font(.caption2.bold().monospaced())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.12))
                                            .foregroundStyle(Color.green)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Модель: \(b.targetModel)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 8) {
                                        Text("In: \(b.maxInputTokens)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("Out: \(b.maxOutputTokens)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("<\(b.maxLatencyMs) ms")
                                            .font(.caption2.bold())
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
