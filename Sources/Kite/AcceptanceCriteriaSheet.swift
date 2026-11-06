import SwiftUI
import KiteKit

struct AcceptanceCriteriaSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: SpecFormat = .gherkin
    @State private var isCopied: Bool = false

    enum SpecFormat: String, CaseIterable, Identifiable {
        case gherkin = "Gherkin (acceptance.feature)"
        case playwright = "Playwright (acceptance.spec.ts)"

        var id: String { rawValue }
    }

    private var scenarios: [AcceptanceScenario] {
        AcceptanceCriteriaBuilder.starterScenarios
    }

    private var currentText: String {
        switch activeTab {
        case .gherkin:
            return AcceptanceCriteriaBuilder.generateGherkin(title: title, scenarios: scenarios)
        case .playwright:
            return AcceptanceCriteriaBuilder.generatePlaywrightSpec(title: title, scenarios: scenarios)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "checklist.checked")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Критерии приемки и E2E тесты (Acceptance Criteria)")
                        .font(.headline)
                    Text("Сценарии Given/When/Then и готовые тесты Playwright для самопроверки ИИ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            HSplitView {
                // Left: Scenarios List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Сценарии верификации (\(scenarios.count)):")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(scenarios) { sc in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sc.title)
                                        .font(.caption.bold())
                                        .foregroundStyle(Color.accentColor)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Given: \(sc.given)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("When: \(sc.when)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("Then: \(sc.then)")
                                            .font(.caption2)
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
                .frame(minWidth: 260, idealWidth: 280)

                // Right: Generated Spec
                VStack(spacing: 12) {
                    HStack {
                        Picker("", selection: $activeTab) {
                            ForEach(SpecFormat.allCases) { fmt in
                                Text(fmt.rawValue).tag(fmt)
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
                            .font(.system(size: 11, design: .monospaced)) // grid: ok
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
