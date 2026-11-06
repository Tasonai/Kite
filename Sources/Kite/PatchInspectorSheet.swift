import SwiftUI
import KiteKit

struct PatchInspectorSheet: View {
    let onDismiss: () -> Void

    @State private var diffText: String = """
    --- a/src/types/schema.ts
    +++ b/src/types/schema.ts
    -export interface UserProfile {
    -  id: string;
    -  email: string;
    -}
    +console.log('fetching user with key:', 'sk-proj-12345678901234567890123456789012');
    """

    @State private var isCopied: Bool = false

    private var report: PatchReport {
        PatchInspector.inspect(patchText: diffText)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Инспектор патчей (Patch & Diff Inspector)")
                        .font(.headline)
                    Text("Анализ изменений кода от Antigravity: поиск удаленных типов, утечек и отладочных логов")
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

            // Risk Banner
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Text("Уровень риска регрессии:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(report.riskLevel.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(riskColor.opacity(0.14))
                        .foregroundStyle(riskColor)
                        .clipShape(Capsule())
                }

                Spacer()

                Text("Найдено замечаний: \(report.findings.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.04))

            Divider()

            HSplitView {
                // Left: Diff Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Вставьте git diff или измененный код:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    TextEditor(text: $diffText)
                        .font(.system(size: 11, design: .monospaced)) // grid: ok
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
                .padding(16)
                .frame(minWidth: 320, idealWidth: 360)

                // Right: Findings & Fix Prompt
                VStack(alignment: .leading, spacing: 12) {
                    Text("Результаты анализа:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            if report.findings.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.green)
                                    Text("Замечаний не обнаружено. Патч безопасен для слияния.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.green.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                ForEach(report.findings) { f in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: f.severity == .critical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                                            .foregroundStyle(f.severity == .critical ? Color.red : Color.orange)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text(f.severity.rawValue)
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(f.severity == .critical ? Color.red : Color.orange)

                                                if let lno = f.line {
                                                    Text("Строка \(lno)")
                                                        .font(.caption2.monospaced())
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                            }

                                            Text(f.message)
                                                .font(.caption)
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

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Хирургический промпт для Antigravity:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(report.fixPrompt, forType: .string)
                                isCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    isCopied = false
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    Text(isCopied ? "Скопировано!" : "Копировать Fix-промпт")
                                }
                                .font(.caption.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(isCopied ? .green : .accentColor)
                        }

                        ScrollView {
                            Text(report.fixPrompt)
                                .font(.system(size: 11, design: .monospaced)) // grid: ok
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                        .frame(height: 128)
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 740, idealWidth: 800, minHeight: 520, idealHeight: 560)
    }

    private var riskColor: Color {
        switch report.riskLevel {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .red
        }
    }
}
