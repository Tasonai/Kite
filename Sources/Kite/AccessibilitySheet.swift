import SwiftUI
import KiteKit

struct AccessibilitySheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (ACCESSIBILITY.md)"
        case suite = "E2E сьют (accessibility.spec.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var requirements: [A11yRequirement] {
        AccessibilityAuditor.starterRequirements
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return AccessibilityAuditor.generateAccessibilityMarkdown(title: title, requirements: requirements)
        case .suite:
            return AccessibilityAuditor.generatePlaywrightA11ySuite(title: title)
        case .prompt:
            return AccessibilityAuditor.generatePromptDirective(requirements: requirements)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "figure.roll")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("WCAG 2.2 и Accessibility (a11y) Аудитор")
                        .font(.headline)
                    Text("Чеклист контрастности, доступности с клавиатуры, фокусных колец и тесты на базе Axe-Core")
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
                // Left: Requirements List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Правила доступности (\(requirements.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(requirements) { req in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(req.title)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text(req.standard)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text(req.ruleDescription)
                                        .font(.caption2)
                                        .foregroundStyle(.primary)

                                    Text(req.codePattern)
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
