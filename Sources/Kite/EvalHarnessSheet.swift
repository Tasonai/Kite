import SwiftUI
import KiteKit

struct EvalHarnessSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (EVALS.md)"
        case runner = "Тест-раннер (prompt_bench.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var testCases: [EvalTestCase] {
        EvalHarness.starterCases
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return EvalHarness.generateEvalsMarkdown(title: title, testCases: testCases)
        case .runner:
            return EvalHarness.generateTypeScriptRunner(testCases: testCases)
        case .prompt:
            return EvalHarness.generatePromptDirective(testCases: testCases)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Eval Harness & Тест-бенч промптов")
                        .font(.headline)
                    Text("Регрессионные бенчмарки для LLM: валидация схемы JSON, проверка на инъекции и критерии LLM-as-a-judge")
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
                // Left: Test Cases List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Сценарии тестирования (\(testCases.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(testCases) { tc in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(tc.name)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text(tc.evaluationMethod.rawValue)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Входной запрос:")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text(tc.userPromptInput)
                                        .font(.caption.monospaced())
                                        .lineLimit(2)
                                        .foregroundStyle(.primary)

                                    Text("Проверки: \(tc.expectedAssertions.count)")
                                        .font(.caption2)
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
