import SwiftUI
import KiteKit

struct PerformanceBudgetSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (PERFORMANCE.md)"
        case nextConfig = "Конфиг (next.config.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var budgets: [BudgetMetric] {
        PerformanceBudget.starterBudgets
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return PerformanceBudget.generatePerformanceMarkdown(title: title, budgets: budgets)
        case .nextConfig:
            return PerformanceBudget.generateNextConfigSnippet(budgets: budgets)
        case .prompt:
            return PerformanceBudget.generatePromptDirective(budgets: budgets)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "gauge.with.needle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Бюджет производительности (Performance & Web Vitals)")
                        .font(.headline)
                    Text("Пороги Core Web Vitals (LCP, CLS, INP), лимиты размера JS-бандла и правила оптимизации")
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
                    Text("Метрики и лимиты (\(budgets.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(budgets) { metric in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(metric.name)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text(metric.targetThreshold)
                                            .font(.caption2.bold().monospaced())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text(metric.category)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text(metric.optimizationRule)
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
