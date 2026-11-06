import CoreGraphics
import Foundation

public struct CanvasBlueprintPack: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let icon: String
    public let colorHex: String
    public let frames: [CanvasFrame]
    public let stickies: [CanvasSticky]
    public let connections: [CanvasConnection]

    public init(
        id: String,
        title: String,
        summary: String,
        icon: String,
        colorHex: String,
        frames: [CanvasFrame],
        stickies: [CanvasSticky],
        connections: [CanvasConnection]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.icon = icon
        self.colorHex = colorHex
        self.frames = frames
        self.stickies = stickies
        self.connections = connections
    }
}

public enum CanvasBlueprintPacks {
    public static let all: [CanvasBlueprintPack] = [
        microSaaS,
        offlineTool,
        aiAgentStudio,
        mobileHabitTracker
    ]

    public static let microSaaS: CanvasBlueprintPack = {
        let f1 = CanvasFrame(
            title: "1. Публичный лендинг и конверсия",
            colorHex: "#10B981",
            x: 80,
            y: 80,
            width: 320,
            height: 440
        )
        let f2 = CanvasFrame(
            title: "2. Личный кабинет и биллинг",
            colorHex: "#3B82F6",
            x: 460,
            y: 80,
            width: 340,
            height: 440
        )

        let s1 = CanvasSticky(text: "Hero-секция с формой регистрации и кнопкой CTA", colorHex: "#BBF7D0", position: CGPoint(x: 240, y: 180))
        let s2 = CanvasSticky(text: "Таблица тарифов и интеграция Stripe Checkout", colorHex: "#FEF08A", position: CGPoint(x: 240, y: 380))
        let s3 = CanvasSticky(text: "Supabase Auth + Row Level Security (RLS)", colorHex: "#BAE6FD", position: CGPoint(x: 630, y: 180))
        let s4 = CanvasSticky(text: "Postgres таблицы: users, subscriptions, usage_events", colorHex: "#DDD6FE", position: CGPoint(x: 630, y: 380))

        let c1 = CanvasConnection(fromId: "sticky-\(s1.id.uuidString)", toId: "sticky-\(s3.id.uuidString)", label: "Регистрация", colorHex: "#10B981")
        let c2 = CanvasConnection(fromId: "sticky-\(s2.id.uuidString)", toId: "sticky-\(s4.id.uuidString)", label: "Stripe Webhook", colorHex: "#3B82F6")
        let c3 = CanvasConnection(fromId: "sticky-\(s3.id.uuidString)", toId: "sticky-\(s4.id.uuidString)", label: "WAL Query", colorHex: "#8B5CF6")

        return CanvasBlueprintPack(
            id: "micro-saas",
            title: "Micro-SaaS Hub",
            summary: "Лендинг, авторизация пользователей, тарифы и подписки Stripe",
            icon: "creditcard",
            colorHex: "#10B981",
            frames: [f1, f2],
            stickies: [s1, s2, s3, s4],
            connections: [c1, c2, c3]
        )
    }()

    public static let offlineTool: CanvasBlueprintPack = {
        let f1 = CanvasFrame(
            title: "1. Локальный интерфейс и горячие клавиши",
            colorHex: "#6366F1",
            x: 80,
            y: 80,
            width: 340,
            height: 440
        )
        let f2 = CanvasFrame(
            title: "2. Автономное хранилище (SQLite/SwiftData)",
            colorHex: "#F59E0B",
            x: 480,
            y: 80,
            width: 320,
            height: 440
        )

        let s1 = CanvasSticky(text: "Быстрый командный пульт (Cmd+K) и шорткаты", colorHex: "#E0E7FF", position: CGPoint(x: 250, y: 180))
        let s2 = CanvasSticky(text: "Трёхуровневая навигация: сайдбар, список, инспектор", colorHex: "#DDD6FE", position: CGPoint(x: 250, y: 380))
        let s3 = CanvasSticky(text: "Локальная база данных без необходимости серверов", colorHex: "#FED7AA", position: CGPoint(x: 640, y: 180))
        let s4 = CanvasSticky(text: "Экспорт данных в один клик: CSV, JSON, Markdown", colorHex: "#BBF7D0", position: CGPoint(x: 640, y: 380))

        let c1 = CanvasConnection(fromId: "sticky-\(s1.id.uuidString)", toId: "sticky-\(s3.id.uuidString)", label: "Локальный поиск", colorHex: "#6366F1")
        let c2 = CanvasConnection(fromId: "sticky-\(s2.id.uuidString)", toId: "sticky-\(s3.id.uuidString)", label: "Однонаправленный поток", colorHex: "#F59E0B")
        let c3 = CanvasConnection(fromId: "sticky-\(s3.id.uuidString)", toId: "sticky-\(s4.id.uuidString)", label: "Экспорт", colorHex: "#10B981")

        return CanvasBlueprintPack(
            id: "offline-tool",
            title: "Offline Local Tool",
            summary: "Автономное настольное приложение с мгновенным откликом и шорткатами",
            icon: "desktopcomputer",
            colorHex: "#6366F1",
            frames: [f1, f2],
            stickies: [s1, s2, s3, s4],
            connections: [c1, c2, c3]
        )
    }()

    public static let aiAgentStudio: CanvasBlueprintPack = {
        let f1 = CanvasFrame(
            title: "1. Диалог и стриминг ответов",
            colorHex: "#8B5CF6",
            x: 80,
            y: 80,
            width: 320,
            height: 440
        )
        let f2 = CanvasFrame(
            title: "2. Оркестратор агентов и инструменты",
            colorHex: "#3B82F6",
            x: 460,
            y: 80,
            width: 340,
            height: 440
        )

        let s1 = CanvasSticky(text: "Чат-интерфейс с поддержкой Markdown и подсветки кода", colorHex: "#DDD6FE", position: CGPoint(x: 240, y: 180))
        let s2 = CanvasSticky(text: "Боковая панель сохраненных диалогов и кэш промптов", colorHex: "#BAE6FD", position: CGPoint(x: 240, y: 380))
        let s3 = CanvasSticky(text: "Потоковый вывод SSE (Server-Sent Events) без задержек", colorHex: "#BBF7D0", position: CGPoint(x: 630, y: 180))
        let s4 = CanvasSticky(text: "Вызов внешних инструментов через MCP протокол", colorHex: "#FEF08A", position: CGPoint(x: 630, y: 380))

        let c1 = CanvasConnection(fromId: "sticky-\(s1.id.uuidString)", toId: "sticky-\(s3.id.uuidString)", label: "SSE Stream", colorHex: "#8B5CF6")
        let c2 = CanvasConnection(fromId: "sticky-\(s3.id.uuidString)", toId: "sticky-\(s4.id.uuidString)", label: "Tool Call", colorHex: "#3B82F6")
        let c3 = CanvasConnection(fromId: "sticky-\(s2.id.uuidString)", toId: "sticky-\(s1.id.uuidString)", label: "История контекста", colorHex: "#6366F1")

        return CanvasBlueprintPack(
            id: "ai-agent-studio",
            title: "AI Agent Studio",
            summary: "Чат-ассистент, потоковые ответы LLM и подключение MCP инструментов",
            icon: "cpu",
            colorHex: "#8B5CF6",
            frames: [f1, f2],
            stickies: [s1, s2, s3, s4],
            connections: [c1, c2, c3]
        )
    }()

    public static let mobileHabitTracker: CanvasBlueprintPack = {
        let f1 = CanvasFrame(
            title: "1. Экран Сегодня (Focus)",
            colorHex: "#EC4899",
            x: 80,
            y: 80,
            width: 320,
            height: 440
        )
        let f2 = CanvasFrame(
            title: "2. Аналитика и прогресс",
            colorHex: "#10B981",
            x: 460,
            y: 80,
            width: 340,
            height: 440
        )

        let s1 = CanvasSticky(text: "Чеклист ежедневных привычек с тактильным откликом", colorHex: "#FED7AA", position: CGPoint(x: 240, y: 180))
        let s2 = CanvasSticky(text: "Таймер фокуса и локальные пуш-уведомления", colorHex: "#FEF08A", position: CGPoint(x: 240, y: 380))
        let s3 = CanvasSticky(text: "Расчет непрерывных серий выполнения (Streaks)", colorHex: "#BBF7D0", position: CGPoint(x: 630, y: 180))
        let s4 = CanvasSticky(text: "Недельные графики и экспорт отчета о продуктивности", colorHex: "#BAE6FD", position: CGPoint(x: 630, y: 380))

        let c1 = CanvasConnection(fromId: "sticky-\(s1.id.uuidString)", toId: "sticky-\(s3.id.uuidString)", label: "Фиксация дня", colorHex: "#EC4899")
        let c2 = CanvasConnection(fromId: "sticky-\(s2.id.uuidString)", toId: "sticky-\(s1.id.uuidString)", label: "Напоминание", colorHex: "#F59E0B")
        let c3 = CanvasConnection(fromId: "sticky-\(s3.id.uuidString)", toId: "sticky-\(s4.id.uuidString)", label: "Агрегация", colorHex: "#10B981")

        return CanvasBlueprintPack(
            id: "mobile-habit",
            title: "Mobile Habit Tracker",
            summary: "Мобильный трекер с тач-таргетами 44px, сериями и пуш-напоминаниями",
            icon: "iphone",
            colorHex: "#EC4899",
            frames: [f1, f2],
            stickies: [s1, s2, s3, s4],
            connections: [c1, c2, c3]
        )
    }()
}
