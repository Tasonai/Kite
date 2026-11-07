import SwiftUI
import KiteKit

struct ExperimentSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (EXPERIMENTS.md)"
        case client = "Клиент (experiments.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var experiments: [ExperimentConfig] {
        ExperimentStudio.starterExperiments
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return ExperimentStudio.generateExperimentMarkdown(title: title, experiments: experiments)
        case .client:
            return ExperimentStudio.generateBucketingClientSnippet(experiments: experiments)
        case .prompt:
            return ExperimentStudio.generatePromptDirective(experiments: experiments)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.2.square")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Песочница A/B тестирования (Experiment Studio)")
                        .font(.headline)
                    Text("Детерминированное бакетирование (SHA-256), сплит трафика и предотвращение мерцания вариантов")
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
                // Left: Experiments List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Эксперименты (\(experiments.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(experiments) { exp in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(exp.experimentKey)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text(exp.trafficWeights.map { "\($0)%" }.joined(separator: " / "))
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text(exp.experimentDescription)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)

                                    Text("Цель: \(exp.primaryMetric)")
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
