import SwiftUI
import KiteKit

struct CodebaseAuditorSheet: View {
    let onDismiss: () -> Void

    @State private var selectedDirectory: URL? = nil
    @State private var auditReport: CodebaseAuditReport? = nil
    @State private var isCopied: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Аудит готового кода Antigravity")
                        .font(.headline)
                    Text("Проверка репозитория на чистоту кода, отсутствие эмодзи, забытых логов и соответствие стандартам")
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

            // Main Content
            VStack(alignment: .leading, spacing: 16) {
                // Folder Selector
                HStack(spacing: 12) {
                    Button {
                        chooseDirectory()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder")
                            Text("Выбрать папку проекта...")
                        }
                    }
                    .buttonStyle(.bordered)

                    if let dir = selectedDirectory {
                        Text(dir.path)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("Папка не выбрана")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    if selectedDirectory != nil {
                        Button("Пересканировать") {
                            runAudit()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let report = auditReport {
                    // Metrics Row
                    HStack(spacing: 12) {
                        metricCard(label: "Файлов кода", value: "\(report.totalFiles)", icon: "doc.text")
                        metricCard(label: "Строк кода", value: "\(report.totalLines)", icon: "text.alignleft")
                        metricCard(label: "Замечаний", value: "\(report.findings.count)", icon: "exclamationmark.triangle")

                        // Score Card
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Индекс чистоты")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(report.score) / 100")
                                    .font(.title2.bold())
                                    .foregroundStyle(report.score >= 80 ? Color.green : Color.orange)
                            }
                            Spacer()
                            Circle()
                                .fill(report.score >= 80 ? Color.green : Color.orange)
                                .frame(width: 12, height: 12)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Findings List
                    VStack(alignment: .leading, spacing: 8) {
                        Text(report.findings.isEmpty ? "Замечаний нет — код в идеальном состоянии!" : "Список замечаний (\(report.findings.count)):")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        if report.findings.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.green)
                                Text("Код чист: лишние логи, TODO и эмодзи не обнаружены.")
                                    .font(.body)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(report.findings) { finding in
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundStyle(Color.orange)

                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 4) {
                                                    Text(finding.file)
                                                        .font(.caption.monospaced().bold())
                                                    Text(":\(finding.line)")
                                                        .font(.caption.monospaced())
                                                        .foregroundStyle(.secondary)
                                                    Text("— \(finding.issueType.rawValue)")
                                                        .font(.caption2)
                                                        .foregroundStyle(Color.orange)
                                                }
                                                Text(finding.description)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()
                                        }
                                        .padding(8)
                                        .background(Color(nsColor: .controlBackgroundColor))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            .frame(maxHeight: 180)
                        }
                    }

                    // Antigravity Polish Prompt Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bolt.shield.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Промпт полировки для Antigravity:")
                                .font(.caption.bold())
                            Spacer()
                            Button {
                                copyPolishPrompt(report.polishPrompt)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    Text(isCopied ? "Скопировано" : "Скопировать промпт")
                                }
                                .font(.caption.weight(.medium))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.accentColor)
                        }

                        ScrollView {
                            Text(report.polishPrompt)
                                .font(.system(.body, design: .monospaced)) // grid: ok font
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 160)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "folder.badge.gearshape")
                            .font(.system(size: 40)) // grid: ok icon size
                            .foregroundStyle(.tertiary)
                        Text("Выберите папку проекта для проведения аудита")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Kite просканирует код, проверит отсутствие лишнего мусора, отладочных логов и эмодзи.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(16)

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 760, idealWidth: 840, minHeight: 520, idealHeight: 640)
    }

    private func metricCard(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.bold())
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedDirectory = url
            runAudit()
        }
    }

    private func runAudit() {
        guard let dir = selectedDirectory else { return }
        auditReport = CodebaseAuditor.audit(directory: dir)
    }

    private func copyPolishPrompt(_ prompt: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
