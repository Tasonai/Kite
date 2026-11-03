import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct DesignLabView: View {
    @Environment(AppModel.self) private var model

    // Typography State
    @State private var headlineFontName: String = "Instrument Serif"
    @State private var bodyFontName: String = "Inter"
    @State private var headlineSize: CGFloat = 36
    @State private var headlineTracking: Double = -0.02
    @State private var roundnessRadius: CGFloat = 8

    // Palette State
    @State private var primaryColor: Color = Color(hex: "#1C1B18")
    @State private var accentColor: Color = Color(hex: "#D97757")
    @State private var surfaceColor: Color = Color(hex: "#FFFFFF")
    @State private var backgroundColor: Color = Color(hex: "#FAF9F5")

    @State private var selectedTab: Int = 0 // 0: Preview, 1: Code Tokens
    @State private var codeExportMode: String = "SwiftUI"
    @State private var copiedToken: Bool = false

    private let headlineFonts = [
        "Instrument Serif", "Space Grotesk", "Epilogue", "Inter", "Playfair Display", "JetBrains Mono"
    ]
    private let bodyFonts = [
        "Inter", "Work Sans", "DM Sans", "SF Pro", "Space Grotesk"
    ]

    private let presetPalettes: [(name: String, primary: String, accent: String, surface: String, bg: String)] = [
        ("Swiss Warm", "#1C1B18", "#D97757", "#FFFFFF", "#FAF9F5"),
        ("Obsidian Glass", "#F5F6F8", "#5E6AD2", "#17191E", "#0D0E11"),
        ("Neo-Brutalist", "#121212", "#FEE739", "#FAF9F5", "#F2EFE9"),
        ("Emerald Voxel", "#F0FDF4", "#10B981", "#18221D", "#0F1713"),
        ("Terracotta Atelier", "#2A1810", "#E0623B", "#FDFBF7", "#F5EFEB")
    ]

    var body: some View {
        HSplitView {
            // Left Controls Panel
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Лаборатория дизайна 🧪")
                            .font(.title2.bold())
                        Text("Интерактивный микшер типографики, палитр и дизайн-токенов.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пресеты эстетики")
                            .font(.subheadline.bold())

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(presetPalettes, id: \.name) { p in
                                    Button {
                                        applyPreset(p)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Circle().fill(Color(hex: p.accent)).frame(width: 8, height: 8)
                                            Text(p.name)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.12))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Divider()

                    // Typography Mixer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Типографика")
                            .font(.subheadline.bold())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Шрифт заголовка")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Picker("", selection: $headlineFontName) {
                                ForEach(headlineFonts, id: \.self) { f in
                                    Text(f).tag(f)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Шрифт текста (Body)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Picker("", selection: $bodyFontName) {
                                ForEach(bodyFonts, id: \.self) { f in
                                    Text(f).tag(f)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Размер заголовка: \(Int(headlineSize))pt")
                                    .font(.caption2)
                                Spacer()
                            }
                            Slider(value: $headlineSize, in: 24...56, step: 4)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Скругление углов: \(Int(roundnessRadius))pt")
                                    .font(.caption2)
                                Spacer()
                            }
                            Slider(value: $roundnessRadius, in: 0...24, step: 4)
                        }
                    }

                    Divider()

                    // Palette Mixer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Цветовая палитра")
                            .font(.subheadline.bold())

                        HStack(spacing: 12) {
                            ColorPicker("Основной текст", selection: $primaryColor)
                                .font(.caption)
                        }

                        HStack(spacing: 12) {
                            ColorPicker("Акцентный цвет", selection: $accentColor)
                                .font(.caption)
                        }

                        HStack(spacing: 12) {
                            ColorPicker("Цвет поверхности (Surface)", selection: $surfaceColor)
                                .font(.caption)
                        }

                        HStack(spacing: 12) {
                            ColorPicker("Цвет фона (Canvas)", selection: $backgroundColor)
                                .font(.caption)
                        }
                    }

                    Divider()

                    // Action Button
                    Button {
                        createProjectFromLab()
                    } label: {
                        Label("Создать проект с этими токенами 💡", systemImage: "sparkles")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(20)
            }
            .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)

            // Right Preview / Code Area
            VStack(spacing: 0) {
                // Top Segmented Bar
                HStack(spacing: 8) {
                    Picker("", selection: $selectedTab) {
                        Text("Интерактивное превью").tag(0)
                        Text("Экспорт токенов кода").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 320)

                    Spacer()

                    if selectedTab == 1 {
                        Picker("", selection: $codeExportMode) {
                            Text("SwiftUI").tag("SwiftUI")
                            Text("Tailwind").tag("Tailwind")
                            Text("CSS").tag("CSS")
                            Text("Stitch").tag("Stitch")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)

                        Button {
                            copyExportCode()
                        } label: {
                            Label(copiedToken ? "Скопировано!" : "Копировать код", systemImage: copiedToken ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                if selectedTab == 0 {
                    // LIVE PREVIEW SANDBOX
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Canvas preview container
                            VStack(alignment: .leading, spacing: 20) {
                                // Badge & Pill
                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Circle().fill(accentColor).frame(width: 8, height: 8)
                                        Text("LIVE TOKENS")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(accentColor.opacity(0.15))
                                    .foregroundStyle(accentColor)
                                    .clipShape(Capsule())

                                    Text("WCAG AAA (21:1)")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundStyle(Color.green)
                                        .clipShape(Capsule())
                                }

                                // Headline text
                                Text("Архитектура без шаблонов.")
                                    .font(previewHeadlineFont)
                                    .tracking(headlineTracking)
                                    .foregroundStyle(primaryColor)

                                // Body Text
                                Text("Интерфейс спроектирован с использованием оптических пропорций, тактильной пружинной физики и кастомной дизайн-системы, синхронизированной с токенами Stitch и Figma.")
                                    .font(previewBodyFont)
                                    .foregroundStyle(primaryColor.opacity(0.8))
                                    .lineSpacing(4)

                                // Interactive Card Grid
                                HStack(spacing: 16) {
                                    // Card 1
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Метрика активности")
                                            .font(.caption2)
                                            .foregroundStyle(primaryColor.opacity(0.6))
                                        Text("99.98%")
                                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                                            .foregroundStyle(accentColor)
                                        Text("0 просадок FPS • 60Hz")
                                            .font(.caption2)
                                            .foregroundStyle(primaryColor.opacity(0.7))
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(surfaceColor)
                                    .clipShape(RoundedRectangle(cornerRadius: roundnessRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: roundnessRadius)
                                            .stroke(primaryColor.opacity(0.12), lineWidth: 1)
                                    )

                                    // Card 2
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Синхронизация токенов")
                                            .font(.caption2)
                                            .foregroundStyle(primaryColor.opacity(0.6))
                                        Text("1-Click")
                                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                                            .foregroundStyle(primaryColor)
                                        Text("Figma + Google Stitch")
                                            .font(.caption2)
                                            .foregroundStyle(primaryColor.opacity(0.7))
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(surfaceColor)
                                    .clipShape(RoundedRectangle(cornerRadius: roundnessRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: roundnessRadius)
                                            .stroke(primaryColor.opacity(0.12), lineWidth: 1)
                                    )
                                }

                                // Interactive Action Buttons
                                HStack(spacing: 12) {
                                    Button {} label: {
                                        Text("Основное действие")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(accentColor)
                                            .clipShape(RoundedRectangle(cornerRadius: roundnessRadius))
                                    }
                                    .buttonStyle(.plain)

                                    Button {} label: {
                                        Text("Вторичная кнопка")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(primaryColor)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(surfaceColor)
                                            .clipShape(RoundedRectangle(cornerRadius: roundnessRadius))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: roundnessRadius)
                                                    .stroke(primaryColor.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(24)
                            .background(backgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(24)
                    }
                } else {
                    // CODE EXPORT VIEW
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: .constant(generatedExportCode))
                            .font(.system(.caption, design: .monospaced))
                            .padding(12)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(20)
                }
            }
        }
    }

    private var previewHeadlineFont: Font {
        if headlineFontName.contains("Serif") {
            return .system(size: headlineSize, weight: .bold, design: .serif)
        } else if headlineFontName.contains("Mono") {
            return .system(size: headlineSize, weight: .bold, design: .monospaced)
        } else {
            return .system(size: headlineSize, weight: .bold, design: .default)
        }
    }

    private var previewBodyFont: Font {
        return .system(size: 15, weight: .regular, design: .default)
    }

    private var generatedExportCode: String {
        switch codeExportMode {
        case "SwiftUI":
            return """
            // ThemeTokens.swift
            import SwiftUI

            public enum AppTheme {
                public static let primaryColor = Color(hex: "\(primaryColor.toHex())")
                public static let accentColor = Color(hex: "\(accentColor.toHex())")
                public static let surfaceColor = Color(hex: "\(surfaceColor.toHex())")
                public static let backgroundColor = Color(hex: "\(backgroundColor.toHex())")

                public static let cornerRadius: CGFloat = \(Int(roundnessRadius))
                public static let headlineFont = Font.custom("\(headlineFontName)", size: \(Int(headlineSize)))
                public static let bodyFont = Font.custom("\(bodyFontName)", size: 15)
            }
            """
        case "Tailwind":
            return """
            /* @theme tokens for Tailwind CSS v4 */
            @theme {
              --color-primary: \(primaryColor.toHex());
              --color-accent: \(accentColor.toHex());
              --color-surface: \(surfaceColor.toHex());
              --color-background: \(backgroundColor.toHex());

              --font-headline: '\(headlineFontName)', sans-serif;
              --font-body: '\(bodyFontName)', sans-serif;
              --radius-default: \(Int(roundnessRadius))px;
            }
            """
        case "CSS":
            return """
            :root {
              --primary: \(primaryColor.toHex());
              --accent: \(accentColor.toHex());
              --surface: \(surfaceColor.toHex());
              --background: \(backgroundColor.toHex());

              --font-headline: '\(headlineFontName)', serif;
              --font-body: '\(bodyFontName)', sans-serif;
              --radius: \(Int(roundnessRadius))px;
            }
            """
        default:
            return DesignExporter.generateStitchDesignMd(
                title: "Custom Lab Theme",
                style: headlineFontName,
                platform: "Web",
                concept: "Токены сгенерированы в Лаборатории дизайна Kite."
            )
        }
    }

    private func applyPreset(_ p: (name: String, primary: String, accent: String, surface: String, bg: String)) {
        primaryColor = Color(hex: p.primary)
        accentColor = Color(hex: p.accent)
        surfaceColor = Color(hex: p.surface)
        backgroundColor = Color(hex: p.bg)
    }

    private func createProjectFromLab() {
        model.sidebar = .all
        model.addItem(
            title: "Проект в стиле \(headlineFontName)",
            concept: "Дизайн-система создана в Лаборатории дизайна Kite. Акцент: \(accentColor.toHex()), фон: \(backgroundColor.toHex()).",
            style: "Editorial & Swiss Modern"
        )
    }

    private func copyExportCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedExportCode, forType: .string)
        NSSound.beep()
        copiedToken = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedToken = false
        }
    }
}
