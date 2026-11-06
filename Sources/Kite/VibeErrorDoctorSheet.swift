import SwiftUI
import KiteKit

struct VibeErrorDoctorSheet: View {
    let onDismiss: () -> Void

    @State private var rawErrorText: String = ""
    @State private var diagnosedError: DiagnosedError? = nil
    @State private var isCopied: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "cross.case.fill")
                    .font(.title2)
                    .foregroundStyle(Color.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Доктор ошибок Antigravity")
                        .font(.headline)
                    Text("Мгновенная диагностика сбоев терминала и генерация точечного Fix-промпта")
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

            // Main layout
            HSplitView {
                // Left: Raw Input
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Лог ошибки или терминала:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            pasteFromClipboard()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.clipboard")
                                Text("Вставить из буфера")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        if !rawErrorText.isEmpty {
                            Button("Очистить") {
                                rawErrorText = ""
                                diagnosedError = nil
                            }
                            .font(.caption)
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                    }

                    TextEditor(text: $rawErrorText)
                        .font(.system(.body, design: .monospaced)) // grid: ok font
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: rawErrorText) { _, newValue in
                            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                diagnosedError = VibeErrorDoctor.diagnose(rawLog: newValue)
                            } else {
                                diagnosedError = nil
                            }
                        }

                    // Sample Error Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Примеры частых ошибок:")
                            .font(.caption2.bold())
                            .foregroundStyle(.tertiary)

                        HStack(spacing: 8) {
                            presetButton("Missing Module", sample: "Error: Cannot find module '@supabase/supabase-js'\nRequire stack:\n- /app/src/db.ts:4:1")
                            presetButton("CORS Error", sample: "Access to fetch at 'http://api.local' from origin 'http://localhost:3000' blocked by CORS policy")
                            presetButton("Nil Crash", sample: "Fatal error: Unexpectedly found nil while unwrapping an Optional value\nFile: ContentView.swift, line: 42")
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 360, idealWidth: 420)

                // Right: Diagnosis & Surgical Fix
                VStack(alignment: .leading, spacing: 16) {
                    if let diag = diagnosedError {
                        // Diagnosis Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "stethoscope")
                                    .foregroundStyle(Color.red)
                                Text("Диагноз: \(diag.category.rawValue)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.red)
                                Spacer()
                                if let file = diag.targetFile {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.text")
                                        Text("\(file)\(diag.lineNumber.map { ":\($0)" } ?? "")")
                                    }
                                    .font(.caption2.monospaced())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                            }

                            Text(diag.title)
                                .font(.headline)

                            Text(diag.rootCause)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Surgical Fix Prompt Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bolt.shield.fill")
                                    .foregroundStyle(Color.accentColor)
                                Text("Точечный Fix-промпт для Antigravity:")
                                    .font(.caption.bold())
                                Spacer()
                                Text("Экономит кредиты")
                                    .font(.caption2)
                                    .foregroundStyle(Color.green)
                            }

                            ScrollView {
                                Text(diag.surgicalFixPrompt)
                                    .font(.system(.body, design: .monospaced)) // grid: ok font
                                    .lineSpacing(4)
                                    .textSelection(.enabled)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 260)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }

                        Button {
                            copyFixPrompt(diag.surgicalFixPrompt)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано в буфер" : "Скопировать Fix-промпт для Antigravity")
                            }
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)

                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "cross.case")
                                .font(.system(size: 40)) // grid: ok icon size
                                .foregroundStyle(.tertiary)
                            Text("Вставьте текст ошибки слева")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Kite определит файл, строку, первопричину и сформирует точный запрос на исправление без лишних переписываний.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(16)
                .frame(minWidth: 400, idealWidth: 480)
            }

            Divider()

            // Footer
            HStack {
                Text("Совет: прикрепляйте к промпту только вывод одной команды, не копируйте весь буфер терминала.")
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
        .frame(minWidth: 800, idealWidth: 920, minHeight: 520, idealHeight: 640)
    }

    private func presetButton(_ label: String, sample: String) -> some View {
        Button {
            rawErrorText = sample
        } label: {
            Text(label)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func pasteFromClipboard() {
        if let str = NSPasteboard.general.string(forType: .string) {
            rawErrorText = str
        }
    }

    private func copyFixPrompt(_ prompt: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
