import SwiftUI
import KiteKit

struct DesignTokenSandboxSheet: View {
    let initialStyle: String
    let onDismiss: () -> Void

    @State private var selectedStyle: String
    @State private var cornerRadius: CGFloat = 8
    @State private var sampleInputText: String = "Текст для проверки инпута"
    @State private var isToggleActive: Bool = true
    @State private var isButtonPressed: Bool = false
    @State private var isCopied: Bool = false

    private let availableStyles = [
        "Editorial & Swiss Modern",
        "Claude Parchment",
        "Codex Minimal",
        "Terracotta Clay",
        "Risograph Two-Color",
        "Bento Contemporary",
        "Linear & DevTool Cockpit",
        "Neo-Brutalism & Tactical",
        "Voxel & 3D Isometric",
        "Glassmorphism & Spatial"
    ]

    init(initialStyle: String, onDismiss: @escaping () -> Void) {
        self.initialStyle = initialStyle
        self._selectedStyle = State(initialValue: initialStyle)
        self.onDismiss = onDismiss
    }

    private var tokens: DesignSystemTokens {
        DesignSystemTokens.resolve(for: selectedStyle)
    }

    private var accentColor: Color {
        Color(hex: tokens.accent)
    }

    private var surfaceColor: Color {
        Color(hex: tokens.surface)
    }

    private var backgroundColor: Color {
        Color(hex: tokens.background)
    }

    private var textPrimaryColor: Color {
        Color(hex: tokens.textPrimary)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "paintpalette.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Песочница дизайн-токенов (Design Sandbox)")
                        .font(.headline)
                    Text("Интерактивная проверка кнопок, форм и карточек с физикой Emil Kowalski")
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

            // Main Content: Controls + Live Canvas
            HSplitView {
                // Left: Style & Token Controls
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Визуальный стиль:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Picker("", selection: $selectedStyle) {
                            ForEach(availableStyles, id: \.self) { s in
                                Text(s).tag(s)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Divider()

                    // Token Inspector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Токены палитры (DESIGN.md):")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        tokenRow(label: "Холст (Background)", hex: tokens.background)
                        tokenRow(label: "Поверхность (Surface)", hex: tokens.surface)
                        tokenRow(label: "Акцент (Accent)", hex: tokens.accent)
                        tokenRow(label: "Чернила (Text)", hex: tokens.textPrimary)
                    }

                    Divider()

                    // Geometry
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Скругление углов (Radius): \(Int(cornerRadius))px")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Slider(value: $cornerRadius, in: 0...16, step: 4)
                    }

                    Spacer()

                    Button {
                        copyTokens()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Скопировано" : "Скопировать токены для Antigravity")
                        }
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                }
                .padding(16)
                .frame(minWidth: 320, idealWidth: 360)

                // Right: Interactive Preview Canvas
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Section 1: Buttons
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Интерактивные кнопки (Emil Spring Micro-interactions):")
                                .font(.caption.bold())
                                .foregroundStyle(textPrimaryColor)

                            HStack(spacing: 12) {
                                // Primary Button with spring scale
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                        isButtonPressed.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                        Text("Основное действие")
                                    }
                                    .font(.body.weight(.medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(accentColor)
                                    .foregroundStyle(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                    .scaleEffect(isButtonPressed ? 0.96 : 1.0)
                                }
                                .buttonStyle(.plain)

                                // Secondary Button
                                Button {
                                } label: {
                                    Text("Вторичная кнопка")
                                        .font(.body)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(surfaceColor)
                                        .foregroundStyle(textPrimaryColor)
                                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: cornerRadius)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)

                                // Destructive Button
                                Button {
                                } label: {
                                    Text("Опасно")
                                        .font(.body)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.12))
                                        .foregroundStyle(Color.red)
                                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Section 2: Form Controls
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Формы и ввод данных (4pt Grid Focus-Ring):")
                                .font(.caption.bold())
                                .foregroundStyle(textPrimaryColor)

                            VStack(spacing: 12) {
                                TextField("Текстовое поле ввода...", text: $sampleInputText)
                                    .padding(8)
                                    .background(surfaceColor)
                                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .stroke(accentColor, lineWidth: 1)
                                    )

                                HStack {
                                    Toggle("Активный статус переключателя", isOn: $isToggleActive)
                                        .toggleStyle(.switch)
                                        .tint(accentColor)

                                    Spacer()

                                    Text(isToggleActive ? "Включено" : "Выключено")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(isToggleActive ? Color.green.opacity(0.16) : Color.secondary.opacity(0.16))
                                        .foregroundStyle(isToggleActive ? Color.green : Color.secondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        // Section 3: High-Density Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Композитная карточка (Card Elevation):")
                                .font(.caption.bold())
                                .foregroundStyle(textPrimaryColor)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 8, height: 8)
                                    Text("Фокальный блок модуля")
                                        .font(.headline)
                                        .foregroundStyle(textPrimaryColor)
                                    Spacer()
                                    Text("v1.0.0")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }

                                Text("Карточка демонстрирует соотношение контраста фона, текста и акцентного цвета в реальном интерфейсе.")
                                    .font(.subheadline)
                                    .foregroundStyle(textPrimaryColor.opacity(0.8))

                                HStack(spacing: 8) {
                                    badge(label: "4pt Сетка", icon: "ruler")
                                    badge(label: "Zero Slop", icon: "shield")
                                    badge(label: "A11y AA", icon: "eye")
                                }
                            }
                            .padding(16)
                            .background(surfaceColor)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(backgroundColor)
                }
                .frame(minWidth: 440, idealWidth: 520)
            }

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
        .frame(minWidth: 840, idealWidth: 920, minHeight: 540, idealHeight: 660)
    }

    private func tokenRow(label: String, hex: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: hex))
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            Text(label)
                .font(.caption)
            Spacer()
            Text(hex)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    private func badge(label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }

    private func copyTokens() {
        let text = """
        [DESIGN.MD TOKENS — \(selectedStyle)]
        - Background: \(tokens.background)
        - Surface: \(tokens.surface)
        - Accent: \(tokens.accent) (\(tokens.accentRole))
        - Text Primary: \(tokens.textPrimary)
        - Corner Radius: \(Int(cornerRadius))px
        - Grid: Strict 4pt/8pt modular scale
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
