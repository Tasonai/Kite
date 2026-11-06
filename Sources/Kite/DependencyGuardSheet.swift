import SwiftUI
import KiteKit

struct DependencyGuardSheet: View {
    let onDismiss: () -> Void

    @State private var isCopied: Bool = false

    private var replacements: [BloatReplacement] {
        DependencyGuard.knownReplacements
    }

    private var totalSavedKB: Int {
        replacements.map(\.savedKBytes).reduce(0, +)
    }

    private var directivePrompt: String {
        DependencyGuard.generateAntigravityBloatDirective()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Инспектор легковесности зависимостей (Bloat Guard)")
                        .font(.headline)
                    Text("Предотвращение раздувания бандла тяжелыми библиотеками в Antigravity")
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
            HSplitView {
                // Left: Replacements Catalog
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Легковесные альтернативы (Экономия ~\(totalSavedKB) КБ):")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(replacements) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.heavyPackage)
                                            .font(.caption.monospaced().bold())
                                            .foregroundStyle(Color.red)

                                        Image(systemName: "arrow.right")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)

                                        Text(item.modernAlternative)
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.green)

                                        Spacer()

                                        Text("-\(item.savedKBytes) КБ")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.14))
                                            .foregroundStyle(Color.green)
                                            .clipShape(Capsule())
                                    }

                                    Text(item.whyBetter)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 420, idealWidth: 460)

                // Right: Antigravity Zero-Bloat Directive
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Директива чистоты бандла для Antigravity:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            copyDirective()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано" : "Скопировать директиву")
                            }
                            .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                    }

                    ScrollView {
                        Text(directivePrompt)
                            .font(.system(.body, design: .monospaced)) // grid: ok font
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(16)
                .frame(minWidth: 380, idealWidth: 440)
            }

            Divider()

            // Footer
            HStack {
                Text("Совет: добавляйте эту директиву в промпт, чтобы ИИ не импортировал тяжелые пакеты ради пары функций.")
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
        .frame(minWidth: 840, idealWidth: 920, minHeight: 500, idealHeight: 600)
    }

    private func copyDirective() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(directivePrompt, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
