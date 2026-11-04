import Foundation

/// Rules for item titles. Logic lives in this library so tests can run it
/// without the app. Put parsers, date rules, and data rules here too.
public enum ItemTitle {
    /// Trims spaces and line breaks, collapses inner runs of spaces, and
    /// falls back to "Новая идея" for an empty title.
    public static func clean(_ text: String) -> String {
        let words = text.split(whereSeparator: \.isWhitespace)
        return words.isEmpty ? "Новая идея" : words.joined(separator: " ")
    }
}

public struct DesignSystemTokens {
    public let background: String
    public let surface: String
    public let accent: String
    public let accentRole: String
    public let textPrimary: String
    public let textSecondary: String
    public let buttons: String
    public let cards: String
    public let typography: String
    public let theme: String

    public static func resolve(for style: String) -> DesignSystemTokens {
        switch style {
        case "Claude Parchment":
            return DesignSystemTokens(
                background: "Warm Ivory (#FAF5F0)",
                surface: "Card (#FFFFFF)",
                accent: "Terracotta (#C86446)",
                accentRole: "scholarly links, quotes, and primary submit action",
                textPrimary: "Slate Ink (#1E293B)",
                textSecondary: "Medium Gray (#64748B)",
                buttons: "Subtly rounded (8px), slate border or terracotta accent, 2px focus ring",
                cards: "Gently rounded (10px), 1px border (#E2D9CC), warm elevation",
                typography: "Serif Display + Plus Jakarta Sans + Monospace",
                theme: "Warm ivory parchment, authoritative research aesthetic"
            )
        case "Codex Minimal":
            return DesignSystemTokens(
                background: "Pure White (#FFFFFF)",
                surface: "Off-White (#FAFAFA)",
                accent: "Jet Black (#171717)",
                accentRole: "pure monochrome ink for all interactive controls",
                textPrimary: "Near Black (#0A0A0A)",
                textSecondary: "Muted Gray (#737373)",
                buttons: "Sharp corners (4px), solid black fill or hairline border",
                cards: "Flat (4px), 1px divider border (#E5E5E5), zero shadows",
                typography: "Inter / Geist + Geist Mono",
                theme: "Radically minimal blank canvas, pure typography"
            )
        case "Terracotta Clay":
            return DesignSystemTokens(
                background: "Warm Cream (#FAF7F2)",
                surface: "Card (#FFFFFF)",
                accent: "Sun-baked Clay (#C05621)",
                accentRole: "terracotta buttons, tags, and progress highlights",
                textPrimary: "Ink Brown (#2B231D)",
                textSecondary: "Clay Muted (#786C62)",
                buttons: "Pill-shaped (9999px), terracotta clay fill, tactile press",
                cards: "Rounded (16px), soft clay shadow, 1px warm border (#E7DFD5)",
                typography: "Fraunces Serif + Plus Jakarta Sans",
                theme: "Warm cream, sun-baked clay editorial"
            )
        case "Risograph Two-Color":
            return DesignSystemTokens(
                background: "Warm Off-White (#FBF9F5)",
                surface: "Paper (#FFFFFF)",
                accent: "Scarlet Red (#FF3B30)",
                accentRole: "scarlet red overlay for primary highlights and urgent callouts",
                textPrimary: "Teal Ink (#007788)",
                textSecondary: "Muted Teal (#558899)",
                buttons: "Sharp 0px edges, 2px solid teal border with red offset press",
                cards: "Sharp 0px, 2px solid #007788 border, tactile riso texture",
                typography: "Space Grotesk + JetBrains Mono",
                theme: "Two-color risograph print on warm off-white paper"
            )
        case "Bento Contemporary":
            return DesignSystemTokens(
                background: "Zinc Obsidian (#09090B)",
                surface: "Bento Surface (#141416)",
                accent: "Emerald Green (#10B981)",
                accentRole: "emerald for primary conversion and active indicators",
                textPrimary: "Crisp White (#F4F4F5)",
                textSecondary: "Muted Zinc (#A1A1AA)",
                buttons: "Rounded (8px), emerald fill or dark border with glow",
                cards: "Bento modular grid (16px radius), 1px border rgba(255,255,255,0.08)",
                typography: "Plus Jakarta Sans + Geist Mono",
                theme: "Dark bento grid, clean contemporary"
            )
        case "Linear & DevTool Cockpit":
            return DesignSystemTokens(
                background: "Obsidian Black (#090A0C)",
                surface: "Dark Card (#13151A)",
                accent: "Emerald Green (#10B981)",
                accentRole: "terminal highlights, active status pips, and primary execution triggers",
                textPrimary: "Clean White (#FAFAFA)",
                textSecondary: "Medium Gray (#888888)",
                buttons: "Precision rounded (6px), dark border (rgba(255,255,255,0.12))",
                cards: "Engineered 8px radius, 1px border (rgba(255,255,255,0.08))",
                typography: "Geist Sans / Space Grotesk + Geist Mono",
                theme: "Dark, modern, devtool-grade density"
            )
        case "Neo-Brutalism & Tactical":
            return DesignSystemTokens(
                background: "Stark Bone (#FAF9F5)",
                surface: "Stark Card (#FFFFFF)",
                accent: "Caution Yellow (#EAB308)",
                accentRole: "high-visibility caution amber for primary buttons",
                textPrimary: "Solid Black (#18181B)",
                textSecondary: "Muted Ink (#52525B)",
                buttons: "Sharp (0px), 2px solid black border, 3px offset drop shadow (#000000)",
                cards: "Sharp (0px), 2px solid black border, 4px offset shadow (#000000)",
                typography: "Space Grotesk (Bold) + JetBrains Mono",
                theme: "High-contrast neo-brutalist raw"
            )
        case "Voxel & 3D Isometric":
            return DesignSystemTokens(
                background: "Space Slate (#0F172A)",
                surface: "Dark Navy (#1E293B)",
                accent: "Warm Amber (#F59E0B)",
                accentRole: "isometric highlights and interactive 3D nodes",
                textPrimary: "Ice White (#F8FAFC)",
                textSecondary: "Slate Blue (#94A3B8)",
                buttons: "Rounded (12px), amber highlight, micro-spring press",
                cards: "20px rounded isometric cards with ambient occlusion shadow",
                typography: "Space Grotesk + JetBrains Mono",
                theme: "3D isometric voxel studio"
            )
        case "Glassmorphism & Spatial":
            return DesignSystemTokens(
                background: "Deep Void (#07080A)",
                surface: "Frosted Glass (rgba(255,255,255,0.05))",
                accent: "Cyan Neon (#06B6D4)",
                accentRole: "cyan neon glowing borders, active tabs, and primary action triggers",
                textPrimary: "Pure Ice (#F0F9FF)",
                textSecondary: "Frost Muted (#94A3B8)",
                buttons: "Pill-shaped (9999px), frosted glass with 1px border",
                cards: "Rounded (16px), backdrop-blur-xl, translucent border",
                typography: "Plus Jakarta Sans + JetBrains Mono",
                theme: "Dark spatial frosted glass & cyan glow"
            )
        default: // Editorial & Swiss Modern
            return DesignSystemTokens(
                background: "Page Canvas (#FAF9F5)",
                surface: "Card & Panels (#FFFFFF)",
                accent: "Terracotta (#D97757)",
                accentRole: "primary call-to-action buttons, active navigation indicators, and key focus rings",
                textPrimary: "Deep Ink (#232321)",
                textSecondary: "Muted Slate (#6B7280)",
                buttons: "Subtly rounded (8px), tactile micro-spring press (:active scale-[0.98])",
                cards: "Modular rounded (12px), 1px border (#DDD9D0), whisper-soft diffused shadow",
                typography: "Instrument Serif (Headlines) + Plus Jakarta Sans (Body) + JetBrains Mono (Figures)",
                theme: "Light, warm ivory, editorial craft"
            )
        }
    }
}

public enum PromptCompiler {
    public static func compileBlueprint(
        title: String,
        concept: String,
        platform: String,
        style: String,
        skills: [String] = ["@site-md", "@design-md", "@taste-design", "@impeccable", "@emil-design-eng"]
    ) -> String {
        let skillsLine = skills.joined(separator: " ")
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveConcept = cleanConcept.isEmpty ? "Реализация проекта без лишнего шума и шаблонов." : cleanConcept
        let tokens = DesignSystemTokens.resolve(for: style)

        return """
        /plan \(skillsLine)

        # ПОЛНЕЙШИЙ АРХИТЕКТУРНЫЙ ПЛАН И СПЕЦИФИКАЦИЯ ПРОЕКТА
        > **Концепция:** \(cleanTitle) — \(effectiveConcept)
        > **Целевая платформа:** \(platform)
        > **Визуальная система:** \(style)
        > **Подход:** Zero AI Slop Architecture // High Density & Polish

        ## РАЗДЕЛ 1. JTBD И ГРАНИЦЫ MVP
        - **Главная цель продукта:** Автоматизировать ключевой сценарий пользователя, устранить трение и предоставить результат за минимальное число действий.
        - **Ключевой сценарий:** Быстрый ввод, наглядная визуализация и локальное хранилище данных без блокировок интерфейса.

        ## РАЗДЕЛ 2. ТЕХНИЧЕСКИЙ СТЕК И ДИЗАЙН-СИСТЕМА (DESIGN.MD)
        - **Платформа:** \(platform)
        - **Стиль интерфейса:** \(style) (\(tokens.theme))
        - **Палитра:** Холст \(tokens.background), Карточки \(tokens.surface), Акцент \(tokens.accent), Чернила \(tokens.textPrimary)
        - **Типографика:** \(tokens.typography)
        - **Сетка и отступы:** Строгая 4pt/8pt модульная система, выверенная иерархия шрифтов.
        - **Принципы крафта:** Поддержка клавиатурных шорткатов, тактильная обратная связь, мгновенный поиск.

        ## РАЗДЕЛ 3. ПОШАГОВЫЙ ПЛАН РЕАЛИЗАЦИИ
        1. Создать локальную модель данных и персистентный слой.
        2. Скомпоновать трёхуровневую навигацию и списочные представления.
        3. Реализовать мгновенный экспорт и хоткеи (Cmd+K, Cmd+N, Escape).
        4. Провести аудит доступности (a11y) и состязательное код-ревью.
        """
    }

    /// Генерирует оптимизированный промпт по официальному стандарту Google Stitch (enhance-prompt + design-md)
    public static func compileStitchPrompt(
        title: String,
        concept: String,
        platform: String,
        style: String,
        skills: [String] = ["@enhance-prompt", "@design-md", "@taste-design", "@impeccable", "@emil-design-eng"]
    ) -> String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveConcept = cleanConcept.isEmpty ? cleanTitle : cleanConcept
        let tokens = DesignSystemTokens.resolve(for: style)
        let skillsLine = skills.joined(separator: " ")

        return """
        A high-craft, tactile \(platform) interface for "\(effectiveConcept)", rendered in \(style) aesthetic with rigorous typography, zero slop, and responsive layout.

        **DESIGN SYSTEM (REQUIRED):**
        - Platform: \(platform), \(platform == "Mobile" ? "Mobile-first (touch targets >= 44px, safe-area aware)" : "Desktop-first with fluid responsiveness")
        - Theme: \(tokens.theme)
        - Background: \(tokens.background)
        - Surface: \(tokens.surface)
        - Primary Accent: \(tokens.accent) for \(tokens.accentRole)
        - Text Primary: \(tokens.textPrimary)
        - Text Secondary: \(tokens.textSecondary)
        - Buttons: \(tokens.buttons)
        - Cards: \(tokens.cards)
        - Typography: \(tokens.typography)

        **Page Structure:**
        1. **Header / Navigation:** Navigation bar with logo, section links, quick search, and primary call-to-action button.
        2. **Hero / Status HUD:** Focal overview with high-contrast headline, key metric cards, and tactile state badges.
        3. **Main Content Area:** Structured card grid layout with real content, inline status tags, and smooth hover elevation.
        4. **Actions / Drawer:** Accessible modal dialog or slide-over inspector with backdrop blur and Escape dismiss.
        5. **Footer:** Status bar, subtle copyright, and instant theme toggle.

        **Antigravity Skills Active:** \(skillsLine)

        ---
        **Tip:** For consistent designs across multiple screens, create a DESIGN.md file using the `design-md` skill. This ensures all generated pages share the same visual language.
        """
    }

    /// Генерирует хирургический таргетированный эдит по enhance-prompt Step 4 Example 2
    public static func compileTargetedEditPrompt(
        title: String,
        concept: String,
        platform: String,
        style: String,
        skills: [String] = ["@enhance-prompt", "@emil-design-eng", "@impeccable"]
    ) -> String {
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveConcept = cleanConcept.isEmpty ? title : cleanConcept
        let skillsLine = skills.joined(separator: " ")

        return """
        \(skillsLine)

        Targeted edit for \(platform) (\(style)): \(effectiveConcept)

        **Specific changes:**
        - Location: Targeted module or header area of the active screen
        - Style & Geometry: Strictly adhering to existing \(style) tokens (4pt grid, consistent corner radius)
        - Icon & Controls: Crisp vector iconography with 16x16px footprint and 6px gap
        - Placeholder & Copy: Clear imperative labels and assistive helper text
        - Behavior & State: Immediate reactive feedback, disabled loading state on async action
        - Dimensions: Fluid responsive width respecting safe-area boundaries
        - Micro-interactions (Emil Kowalski): Sub-250ms damped spring (:active scale-[0.98]), visible focus-visible ring

        **Context:** This is a targeted edit. Make only this change while preserving all existing elements, typography tokens, and layout structure intact without side regressions.
        """
    }

    /// Генерирует краткий сжатый бриф
    public static func compileConcisePrompt(
        title: String,
        concept: String,
        platform: String,
        style: String,
        skills: [String]
    ) -> String {
        let skillsLine = skills.joined(separator: " ")
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveConcept = cleanConcept.isEmpty ? cleanTitle : cleanConcept

        return """
        \(skillsLine)

        Нужно реализовать задачу (\(platform)): **\(effectiveConcept)**
        Контекст: Стиль «\(style)». Требуется прямое, чистое решение без лишней абстракции и слопа.

        **Ключевые пункты:**
        - Реализовать чистый UI в соответствии с дизайн-системой.
        - Обеспечить тактильный отклик и поддержку клавиатуры (Cmd+K, Escape).
        - Сохранять стабильность существующего кода.
        """
    }

    /// Генерирует чеклист действий (Action-Only)
    public static func compileActionPrompt(
        title: String,
        concept: String,
        platform: String,
        style: String,
        skills: [String]
    ) -> String {
        let skillsLine = skills.joined(separator: " ")
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveConcept = cleanConcept.isEmpty ? title : cleanConcept

        return """
        \(skillsLine)

        > **Задача (\(platform), \(style)):** \(effectiveConcept)

        **Чек-лист изменений:**
        [ ] Создать / обновить целевой UI компонент с соблюдением 4pt-сетки
        [ ] Подключить состояния загрузки, ошибок и пустых списков (Empty State)
        [ ] Настроить микро-пружины :active и доступность :focus-visible
        [ ] Проверить отсутствие регрессий в смежных модулях
        """
    }
}
