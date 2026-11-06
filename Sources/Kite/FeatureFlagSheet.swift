import SwiftUI
import KiteKit

struct FeatureFlagSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (FEATURE_FLAGS.md)"
        case client = "Клиент флагов (flags.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var flags: [FeatureFlag] {
        FeatureFlagMatrix.starterFlags
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return FeatureFlagMatrix.generateFeatureFlagsMarkdown(title: title, flags: flags)
        case .client:
            return FeatureFlagMatrix.generateTypeScriptClient(flags: flags)
        case .prompt:
            return FeatureFlagMatrix.generatePromptDirective(flags: flags)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "flag.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Матрица фиче-флагов (Feature Flag & Rollout Matrix)")
                        .font(.headline)
                    Text("Контролируемый релиз: изоляция незавершенных фич, процентный rollout и типизированный клиент")
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
                // Left: Flags List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Активные флаги (\(flags.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(flags) { flag in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(flag.title)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text("\(flag.rolloutPercentage)%")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(flag.rolloutPercentage > 0 ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text(flag.key)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)

                                    Text(flag.description)
                                        .font(.caption2)
                                        .foregroundStyle(.primary)

                                    HStack {
                                        Image(systemName: "person.2")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(flag.targetAudience)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
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
