import SwiftUI
import KiteKit

struct MigrationStrategistSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (MIGRATIONS.md)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var steps: [MigrationStep] {
        MigrationStrategist.starterSteps
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return MigrationStrategist.generateMigrationsMarkdown(title: title, steps: steps)
        case .prompt:
            return MigrationStrategist.generatePromptDirective(steps: steps)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Стратег безопасных миграций данных (Migration Strategist)")
                        .font(.headline)
                    Text("Двухфазные миграции Expand & Contract: нулевой даунтайм, обратимые скрипты UP/DOWN и бэкфилл")
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
                // Left: Migration Phases List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Фазы миграции (\(steps.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(steps) { step in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(step.phaseName)
                                            .font(.caption.bold())
                                        Spacer()
                                        if step.isZeroDowntimeSafe {
                                            Text("Zero-Downtime")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.12))
                                                .foregroundStyle(Color.green)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                    }

                                    Text(step.description)
                                        .font(.caption2)
                                        .foregroundStyle(.primary)

                                    Text("UP: \(step.sqlUp)")
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

                // Right: Generated Output
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
