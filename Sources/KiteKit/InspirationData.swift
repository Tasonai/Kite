import Foundation

public struct InspirationColor: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let name: String
    public let hex: String
    public let role: String

    public init(name: String, hex: String, role: String) {
        self.name = name
        self.hex = hex
        self.role = role
    }
}

public struct InspirationCard: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let category: String
    public let thumbnail: String
    public let creator: String
    public let description: String
    public let keywords: [String]
    public let colors: [InspirationColor]
    public let displayFont: String
    public let bodyFont: String
    public let promptBlueprint: String

    public init(
        id: String,
        title: String,
        category: String,
        thumbnail: String,
        creator: String,
        description: String,
        keywords: [String],
        colors: [InspirationColor],
        displayFont: String,
        bodyFont: String,
        promptBlueprint: String
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.thumbnail = thumbnail
        self.creator = creator
        self.description = description
        self.keywords = keywords
        self.colors = colors
        self.displayFont = displayFont
        self.bodyFont = bodyFont
        self.promptBlueprint = promptBlueprint
    }
}

public enum InspirationRepository {
    public static let curated: [InspirationCard] = [
        InspirationCard(
            id: "stillness-voxel",
            title: "Stillness Meditation",
            category: "Voxel & 3D Isometric",
            thumbnail: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80",
            creator: "Studio Reflex",
            description: "Медитативный воксельный ландшафт: река, сосновый лес, мягкие облачные структуры и рассеянный теплый свет на рассвете.",
            keywords: ["VOXEL 3D", "LOW-POLY LANDSCAPE", "OCTANE RENDER", "WARM RIM LIGHTING"],
            colors: [
                InspirationColor(name: "Warm Terracotta", hex: "#D97757", role: "Hillside Accent"),
                InspirationColor(name: "Pine Forest Green", hex: "#2A5A4A", role: "Low-Poly Foliage"),
                InspirationColor(name: "River Mineral Cyan", hex: "#68B0AB", role: "Flowing River"),
                InspirationColor(name: "Parchment Canvas", hex: "#FAF9F5", role: "Off-White Base"),
                InspirationColor(name: "Charcoal Ink", hex: "#232321", role: "Typography")
            ],
            displayFont: "Fraunces / Instrument Serif",
            bodyFont: "Plus Jakarta Sans",
            promptBlueprint: "3D воксельный ландшафт в изометрии с мягкими тенями Ambient Occlusion, низкополигональными объектами и природными текстурами."
        ),
        InspirationCard(
            id: "foldpage-editorial",
            title: "Foldpage AI Studio",
            category: "Editorial & Swiss Modern",
            thumbnail: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=1200&q=80",
            creator: "Atelier Swiss",
            description: "Швейцарская редакционная эстетика: строгая модульная сетка, крупная акцидентная антиква, бумажный теплый фон и воздушные отступы.",
            keywords: ["SWISS EDITORIAL", "SERIF TYPOGRAPHY", "WARM PARCHMENT", "MODULAR GRID"],
            colors: [
                InspirationColor(name: "Earth Umber", hex: "#8B5E3C", role: "Organic Centerpiece"),
                InspirationColor(name: "Pure Chalk", hex: "#FFFFFF", role: "Surface Card"),
                InspirationColor(name: "Sand Warm Base", hex: "#F5F4EE", role: "Background Canvas"),
                InspirationColor(name: "Stone Border", hex: "#E5E3DC", role: "Structural Line"),
                InspirationColor(name: "Ink Charcoal", hex: "#1C1B18", role: "Primary Text")
            ],
            displayFont: "Instrument Serif",
            bodyFont: "Plus Jakarta Sans",
            promptBlueprint: "Редакционный стиль с выверенной типографикой, крупными заголовками на антикве, теплыми бумажными тонами и контрастными цитатами."
        ),
        InspirationCard(
            id: "hyperion-cockpit",
            title: "Hyperion Agent Cockpit",
            category: "Linear & DevTool Cockpit",
            thumbnail: "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=1200&q=80",
            creator: "Kite Lab",
            description: "Тёмный кокпит для разработчиков: инженерная плотность, моноширинные бейджи, однопиксельные статусные индикаторы и фокус на шорткаты.",
            keywords: ["DEVTOOLS DENSE", "DARK GRAPHITE", "STATUS INDICATORS", "KEYBOARD-FIRST"],
            colors: [
                InspirationColor(name: "Obsidian Base", hex: "#0E1015", role: "Deep Canvas"),
                InspirationColor(name: "Graphite Panel", hex: "#181B22", role: "Floating Panel"),
                InspirationColor(name: "Linear Indigo", hex: "#5E6AD2", role: "Active Accent"),
                InspirationColor(name: "Signal Cyan", hex: "#00E5FF", role: "Live Pulse"),
                InspirationColor(name: "Muted Steel", hex: "#8B949E", role: "Secondary Details")
            ],
            displayFont: "JetBrains Mono",
            bodyFont: "Inter / Geist Sans",
            promptBlueprint: "Интерфейс инженерного кокпита в тёмной графитовой гамме с моноширинными шрифтами, высокой плотностью данных и клавиатурной навигацией."
        ),
        InspirationCard(
            id: "tactical-neobrutalism",
            title: "Tactical Habit Radar",
            category: "Neo-Brutalism & Tactical",
            thumbnail: "https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=1200&q=80",
            creator: "Brutal Ops",
            description: "Тактический нео-брутализм: жирные черные рамки 2-3px, жесткие тени со смещением, контрастные неоновые плашки и тактильный клик.",
            keywords: ["NEO-BRUTALISM", "HARD SHADOWS", "THICK BORDERS", "HIGH CONTRAST"],
            colors: [
                InspirationColor(name: "Acid Yellow", hex: "#FACC15", role: "Primary Callout"),
                InspirationColor(name: "Solid Pitch", hex: "#000000", role: "Border & Shadow"),
                InspirationColor(name: "Neon Mint", hex: "#10B981", role: "Success Pill"),
                InspirationColor(name: "Concrete Offwhite", hex: "#F4F4F5", role: "Surface Card"),
                InspirationColor(name: "Hot Coral", hex: "#F43F5E", role: "Urgent Badge")
            ],
            displayFont: "Space Grotesk",
            bodyFont: "DM Sans",
            promptBlueprint: "Нео-бруталистический интерфейс с черными контурами 2px, жесткими тенями без размытия, яркими акцентными плашками и крупными кнопками."
        ),
        InspirationCard(
            id: "lumina-glass",
            title: "Lumina Spatial OS",
            category: "Glassmorphism & Spatial",
            thumbnail: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80",
            creator: "Apple HIG Studio",
            description: "Эстетика Liquid Glass: многослойные полупрозрачные панели, реалистичные световые фаски, глубина размытия и плавные микро-интеракции.",
            keywords: ["LIQUID GLASS", "APPLE HIG", "BLUR TRANSLUCENT", "SPECULAR HIGHLIGHT"],
            colors: [
                InspirationColor(name: "Deep Midnight", hex: "#0B0E14", role: "Background Surface"),
                InspirationColor(name: "Frosted Glass", hex: "#FFFFFF1A", role: "Material Layer"),
                InspirationColor(name: "Electric Violet", hex: "#8B5CF6", role: "Glow Accent"),
                InspirationColor(name: "Pure White", hex: "#FFFFFF", role: "Text & Bevel"),
                InspirationColor(name: "Subtle Rim", hex: "#FFFFFF33", role: "Border Reflection")
            ],
            displayFont: "SF Pro Display",
            bodyFont: "SF Pro Text",
            promptBlueprint: "Стеклянный spatial-интерфейс в духе macOS Liquid Glass с размытием UltraThinMaterial, световыми фасками и объёмным освещением."
        )
    ]
}
