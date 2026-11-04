import Foundation

public struct DesignTokenSet: Sendable {
    public let primaryColor: String
    public let secondaryColor: String
    public let surfaceColor: String
    public let backgroundColor: String
    public let headlineFont: String
    public let bodyFont: String
    public let roundness: String
    public let gutter: String
    public let margin: String
}

public enum DesignExporter {
    public static func tokens(for style: String) -> DesignTokenSet {
        let s = style.lowercased()
        if s.contains("linear") || s.contains("cockpit") || s.contains("dense") {
            return DesignTokenSet(
                primaryColor: "#5E6AD2",
                secondaryColor: "#8A99AD",
                surfaceColor: "#141517",
                backgroundColor: "#0D0E10",
                headlineFont: "Inter",
                bodyFont: "JetBrains Mono",
                roundness: "0.375rem",
                gutter: "1rem",
                margin: "1.5rem"
            )
        } else if s.contains("brutal") || s.contains("tactical") {
            return DesignTokenSet(
                primaryColor: "#D97757",
                secondaryColor: "#1C1B18",
                surfaceColor: "#FAF9F5",
                backgroundColor: "#F2EFE9",
                headlineFont: "Space Grotesk",
                bodyFont: "Work Sans",
                roundness: "0rem",
                gutter: "1.25rem",
                margin: "2rem"
            )
        } else if s.contains("voxel") || s.contains("isometric") || s.contains("3d") {
            return DesignTokenSet(
                primaryColor: "#10B981",
                secondaryColor: "#6EE7B7",
                surfaceColor: "#18221D",
                backgroundColor: "#0F1713",
                headlineFont: "Plus Jakarta Sans",
                bodyFont: "DM Sans",
                roundness: "1rem",
                gutter: "1.5rem",
                margin: "2rem"
            )
        } else {
            // Default: Swiss & Editorial Modern
            return DesignTokenSet(
                primaryColor: "#1C1B18",
                secondaryColor: "#D97757",
                surfaceColor: "#FFFFFF",
                backgroundColor: "#FAF9F5",
                headlineFont: "Instrument Serif",
                bodyFont: "Inter",
                roundness: "0.5rem",
                gutter: "1.25rem",
                margin: "2.5rem"
            )
        }
    }

    /// Generates standard Google Stitch DESIGN.md with YAML frontmatter
    public static func generateStitchDesignMd(
        title: String,
        style: String,
        platform: String,
        concept: String
    ) -> String {
        let tok = tokens(for: style)
        let cleanTitle = title.isEmpty ? "Antigravity Project" : title

        return """
        ---
        name: \(cleanTitle)
        colors:
          surface: '\(tok.surfaceColor)'
          surface-dim: '\(tok.backgroundColor)'
          surface-bright: '#FFFFFF'
          surface-container-lowest: '#FFFFFF'
          surface-container: '\(tok.surfaceColor)'
          surface-container-high: '#EAE7E1'
          on-surface: '#1B1B1B'
          outline: '#D4D0C5'
          primary: '\(tok.primaryColor)'
          on-primary: '#FFFFFF'
          primary-container: '\(tok.primaryColor)20'
          secondary: '\(tok.secondaryColor)'
          on-secondary: '#FFFFFF'
          background: '\(tok.backgroundColor)'
          on-background: '#1B1B1B'
        typography:
          headline-xl:
            fontFamily: \(tok.headlineFont)
            fontSize: 48px
            fontWeight: '800'
            lineHeight: 52px
            letterSpacing: -0.03em
          headline-lg:
            fontFamily: \(tok.headlineFont)
            fontSize: 32px
            fontWeight: '700'
            lineHeight: 36px
            letterSpacing: -0.02em
          body-md:
            fontFamily: \(tok.bodyFont)
            fontSize: 15px
            fontWeight: '400'
            lineHeight: 24px
          label-md:
            fontFamily: \(tok.bodyFont)
            fontSize: 12px
            fontWeight: '600'
            lineHeight: 16px
            letterSpacing: 0.04em
        rounded:
          sm: 0.25rem
          DEFAULT: \(tok.roundness)
          lg: 1rem
          full: 9999px
        spacing:
          gutter: \(tok.gutter)
          margin: \(tok.margin)
          space-xs: 0.25rem
          space-sm: 0.5rem
          space-md: 1rem
          space-lg: 1.5rem
          space-xl: 2.5rem
        ---

        # \(cleanTitle) — Design System

        ## 1. Brand & Aesthetic Statement
        Спроектировано для платформы **\(platform)** в стилистике **\(style)**.
        \(concept.isEmpty ? "Фокус на эргономике, высокой контрастности и тактильности взаимодействия." : concept)

        ## 2. Color Palette Strategy
        - **Primary (`\(tok.primaryColor)`):** Основной акцентный тон для ключевых действий (CTA) и активных состояний.
        - **Secondary (`\(tok.secondaryColor)`):** Вспомогательный цвет для разделителей, фокуса и значков.
        - **Canvas (`\(tok.backgroundColor)`):** Базовая подложка интерфейса.
        - **Surface (`\(tok.surfaceColor)`):** Карточки, модальные окна и всплывающие панели.

        ## 3. Typography & Hierarchy
        - Заголовки: **\(tok.headlineFont)** с оптическим трекингом `-0.02em`.
        - Основной текст: **\(tok.bodyFont)** с коэффициентом строки `1.5`.

        ## 4. Components Contract
        - **Buttons:** Скругление `\(tok.roundness)`, отступы `10px 18px`, микро-деформация `:active scale(0.98)`.
        - **Cards:** Подложка `\(tok.surfaceColor)`, граница `1px solid \(tok.primaryColor)20`.
        """
    }

    /// Generates W3C Design Tokens JSON format for Figma Tokens Studio / Code Connect
    public static func generateFigmaTokensJson(
        title: String,
        style: String
    ) -> String {
        let tok = tokens(for: style)
        let json: [String: Any] = [
            "name": title.isEmpty ? "Figma Token Spec" : title,
            "version": "1.0.0",
            "style": style,
            "global": [
                "color": [
                    "primary": ["value": tok.primaryColor, "type": "color"],
                    "secondary": ["value": tok.secondaryColor, "type": "color"],
                    "surface": ["value": tok.surfaceColor, "type": "color"],
                    "background": ["value": tok.backgroundColor, "type": "color"]
                ],
                "fontFamilies": [
                    "heading": ["value": tok.headlineFont, "type": "fontFamilies"],
                    "body": ["value": tok.bodyFont, "type": "fontFamilies"]
                ],
                "borderRadius": [
                    "default": ["value": tok.roundness, "type": "borderRadius"],
                    "full": ["value": "9999px", "type": "borderRadius"]
                ],
                "spacing": [
                    "gutter": ["value": tok.gutter, "type": "spacing"],
                    "margin": ["value": tok.margin, "type": "spacing"]
                ]
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    /// Generates FigJam Diagram Spec
    public static func generateFigJamDiagram(
        title: String,
        concept: String,
        style: String
    ) -> String {
        """
        flowchart TD
            User(["Пользователь"]) --> Client["Клиент (\(title))"]
            Client --> UI["Слой UI (\(style))"]
            UI --> State["Управление состоянием (Store)"]
            State --> Engine["Архитектурное ядро"]
            Engine --> Storage[("Локальная БД")]
            Engine --> AI["Интеллектуальные сервисы"]
            
            subgraph DesignSystem["Дизайн-система"]
                Tokens["Токены цветов & типографики"]
                Components["Компоненты (Buttons, Cards, HUD)"]
            end
            
            UI -.-> DesignSystem
        """
    }
}
