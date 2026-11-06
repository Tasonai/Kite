import SwiftUI
import KiteKit

struct RunbookSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .runbook
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case runbook = "Инженерный ранбук (RUNBOOK.md)"
        case packageJson = "package.json scripts"
        case makefile = "Makefile"

        var id: String { rawValue }
    }

    private var commands: [RunbookCommand] {
        RunbookBuilder.starterCommands
    }

    private var currentText: String {
        switch activeTab {
        case .runbook:
            return RunbookBuilder.generateRunbookMarkdown(title: title, commands: commands)
        case .packageJson:
            return RunbookBuilder.generatePackageJsonScripts(commands: commands)
        case .makefile:
            return RunbookBuilder.generateMakefile(commands: commands)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "terminal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Инженерный ранбук (Dev Runbook & Commands)")
                        .font(.headline)
                    Text("Единый свод команд терминала для запуска, сидирования, сборки и тестов в Antigravity")
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
                // Left: Commands List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Команды жизненного цикла (\(commands.count)):")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(commands) { cmd in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(cmd.name)
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.accentColor)
                                        Spacer()
                                        Text(cmd.phase)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6) // grid: ok
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.12))
                                            .clipShape(Capsule())
                                    }

                                    Text(cmd.command)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.primary)

                                    Text(cmd.description)
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
