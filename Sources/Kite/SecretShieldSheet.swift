import SwiftUI
import KiteKit

struct SecretShieldSheet: View {
    let onDismiss: () -> Void

    @State private var inputText: String = ""
    @State private var findings: [SecretFinding] = []
    @State private var isSanitized: Bool = false
    @State private var isCopied: Bool = false
    @State private var activeTab: ShieldTab = .scanner

    enum ShieldTab: String, CaseIterable, Identifiable {
        case scanner = "Сканер секретов"
        case envExample = ".env.example"

        var id: String { rawValue }
    }

    private var envExampleContent: String {
        SecretShield.generateEnvExample(title: "Antigravity Project")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Защита от утечки секретов (Secret Shield)")
                        .font(.headline)
                    Text("Обнаружение API-ключей, токенов и замена на переменные окружения")
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

            // Tab Bar
            HStack(spacing: 8) {
                Picker("", selection: $activeTab) {
                    ForEach(ShieldTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Main Content
            if activeTab == .scanner {
                scannerView
            } else {
                envExampleView
            }

            Divider()

            // Footer
            HStack {
                Text("Совет: никогда не коммитьте файлы .env в Git. Добавьте .env в .gitignore.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 840, idealWidth: 920, minHeight: 520, idealHeight: 640)
    }

    @ViewBuilder
    private var scannerView: some View {
        HSplitView {
            // Left: Input
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Текст промпта или код для проверки:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        if let str = NSPasteboard.general.string(forType: .string) {
                            inputText = str
                            scanText()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                            Text("Вставить")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }

                TextEditor(text: $inputText)
                    .font(.system(.body, design: .monospaced)) // grid: ok font
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: inputText) { _, _ in
                        scanText()
                    }

                // Sample Preset Button
                Button("Вставить пример с открытым ключом") {
                    inputText = "const apiKey = 'sk-proj_test123456789012345678901234567890';\nconst github = 'ghp_123456789012345678901234567890123456';"
                    scanText()
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(minWidth: 380, idealWidth: 440)

            // Right: Detected Findings & Action
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: findings.isEmpty ? "checkmark.circle.fill" : "exclamationmark.shield.fill")
                        .foregroundStyle(findings.isEmpty ? Color.green : Color.red)
                    Text(findings.isEmpty ? "Утечек ключей не обнаружено" : "Обнаружено утечек: \(findings.count)")
                        .font(.headline)
                        .foregroundStyle(findings.isEmpty ? Color.green : Color.red)
                }

                if !findings.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(findings) { f in
                                HStack(spacing: 8) {
                                    Image(systemName: "key.fill")
                                        .foregroundStyle(Color.red)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(f.kind.rawValue)
                                            .font(.caption.bold())
                                        Text(f.preview)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .frame(maxHeight: 200)

                    Button {
                        sanitizeText()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                            Text("Обезвредить (Заменить на process.env.KEY)")
                        }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 40)) // grid: ok icon size
                            .foregroundStyle(.tertiary)
                        Text("Текст безопасен для отправки в AI")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Kite автоматически обнаруживает API-ключи OpenAI, Google Gemini, GitHub, Stripe и токены доступа.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer()
            }
            .padding(16)
            .frame(minWidth: 380, idealWidth: 440)
        }
    }

    @ViewBuilder
    private var envExampleView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Шаблон файла .env.example:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    copyEnvExample()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Скопировано" : "Скопировать .env.example")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }

            ScrollView {
                Text(envExampleContent)
                    .font(.system(.body, design: .monospaced)) // grid: ok font
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(16)
    }

    private func scanText() {
        findings = SecretShield.scan(text: inputText)
    }

    private func sanitizeText() {
        inputText = SecretShield.sanitize(text: inputText)
        scanText()
        isSanitized = true
        NSSound.beep()
    }

    private func copyEnvExample() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(envExampleContent, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
