import SwiftUI
import KiteKit

struct MonorepoSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (MONOREPO.md)"
        case turbo = "Конфиг (turbo.json)"
        case pnpm = "Воркспейс (pnpm-workspace.yaml)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var packages: [MonorepoPackage] {
        MonorepoArchitect.starterPackages
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return MonorepoArchitect.generateMonorepoMarkdown(title: title, packages: packages)
        case .turbo:
            return MonorepoArchitect.generateTurboJson()
        case .pnpm:
            return MonorepoArchitect.generatePnpmWorkspaceYaml()
        case .prompt:
            return MonorepoArchitect.generatePromptDirective(packages: packages)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "square.split.diagonal.2x2")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Архитектор монорепозиториев и воркспейсов (Monorepo Architect)")
                        .font(.headline)
                    Text("Границы пакетов, конфигурация Turborepo/pnpm и правила межархитектурных импортов")
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
                // Left: Packages List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Пакеты воркспейса (\(packages.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(packages) { pkg in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(pkg.name)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text(pkg.packagePath)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text(pkg.packageType)
                                        .font(.caption2)
                                        .foregroundStyle(.primary)

                                    if !pkg.dependsOn.isEmpty {
                                        Text("Зависит от: \(pkg.dependsOn.joined(separator: ", "))")
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
