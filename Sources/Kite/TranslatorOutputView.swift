import SwiftUI
import KiteKit

struct TranslatorOutputView: View {
    @Binding var generatedBlueprint: String
    let selectedMode: String
    let qualityScore: Int
    let isCopied: Bool
    let isStarterCopied: Bool
    let pitfalls: [PitfallWarning]
    let onCopy: () -> Void
    let onCopyStarterPrompt: () -> Void
    let onOpenMockup: () -> Void
    let onOpenAntigravityPack: () -> Void
    let onOpenEditor: (EditorLauncher.Editor) -> Void

    @State private var showPitfalls = true

    private var qualityColor: Color {
        if qualityScore >= 80 { return .green }
        if qualityScore >= 50 { return .orange }
        return .red
    }

    private var qualityDescription: String {
        if qualityScore >= 80 { return "Высокая готовность: стек, дизайн-система и сценарий выверены." }
        if qualityScore >= 50 { return "Базовая спецификация: рекомендуется уточнить детали идеи." }
        return "Минимальный ввод: добавьте описание ключевого действия пользователя."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quality Gauge Banner
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(qualityColor)
                            .frame(width: 8, height: 8)
                        Text(selectedMode == "stitch" ? "Google Stitch Спецификация" : selectedMode == "edit" ? "Таргетированный эдит" : "Индекс готовности плана:")
                            .font(.caption.bold())
                        Text("\(qualityScore)%")
                            .font(.caption.monospaced().bold())
                            .foregroundStyle(qualityColor)
                    }
                    Text(selectedMode == "stitch" ? "Спецификация по стандарту enhance-prompt + design-md." : (selectedMode == "edit" ? "Хирургическое изменение узла без регрессий." : qualityDescription))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                HStack(spacing: 8) {
                    Button {
                        onOpenMockup()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                            Text("Эскиз")
                        }
                        .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .help("Открыть интерактивный прототип прямо в Kite (WebStudio)")

                    Button {
                        onOpenAntigravityPack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.shield.fill")
                            Text("Пакет Antigravity")
                        }
                        .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                    .help("Собрать токено-эффективный пакет волн (Waves) и спецификацию для Antigravity")

                    if !generatedBlueprint.isEmpty {
                        Button {
                            onCopyStarterPrompt()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isStarterCopied ? "checkmark" : "play.circle")
                                Text(isStarterCopied ? "Скопировано" : "Промпт 1-го шага")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .help("Скопировать стартовый диалоговый гайд для Cursor / Claude / Antigravity")

                        Menu {
                            Button {
                                onOpenEditor(.cursor)
                            } label: {
                                Label("Открыть в Cursor", systemImage: "chevron.left.forwardslash.chevron.right")
                            }

                            Button {
                                onOpenEditor(.vsCode)
                            } label: {
                                Label("Открыть в VS Code", systemImage: "curlybraces")
                            }

                            Button {
                                onOpenEditor(.terminal)
                            } label: {
                                Label("Открыть в Терминале", systemImage: "terminal")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.forward.app")
                                Text("В редактор")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            onCopy()
                        } label: {
                            Label(isCopied ? "Скопировано" : "Копировать", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Anti-Pitfall Guidance ("Анти-грабли")
            if !pitfalls.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundStyle(Color.orange)
                        Text("Анти-грабли: защита от типичных ошибок")
                            .font(.caption.bold())
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPitfalls.toggle()
                            }
                        } label: {
                            Image(systemName: showPitfalls ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if showPitfalls {
                        VStack(spacing: 8) {
                            ForEach(pitfalls) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.caption2)
                                        .foregroundStyle(Color.orange)
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text(item.title)
                                                .font(.caption.bold())
                                            Text("(\(item.category))")
                                                .font(.system(size: 9, design: .monospaced)) // grid: ok font
                                                .foregroundStyle(.secondary)
                                        }

                                        Text(item.recommendation)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Output Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Инженерный план Antigravity")
                    .font(.headline)

                if generatedBlueprint.isEmpty {
                    ContentUnavailableView(
                        "Готовый план появится здесь",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Опишите задумку слева и нажмите «Скомпилировать /plan».")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    TextEditor(text: $generatedBlueprint)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
            }
        }
        .padding(20)
        .frame(minWidth: 360, idealWidth: 440)
    }
}
