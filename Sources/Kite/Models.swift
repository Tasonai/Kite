import Foundation
import SwiftData
import KiteKit

@Model
final class Item {
    var title: String
    var notes: String = ""
    var concept: String = ""
    var platform: String = "Web"
    var style: String = "Editorial & Swiss Modern"
    var status: String = "backlog"
    var tags: String = ""
    var generatedPrompt: String = ""
    var isStarred: Bool = false
    var createdAt: Date = Date.now
    /// A stable id for links, sync, and the agent CLI.
    var uuid: UUID = UUID()

    init(title: String) {
        self.title = title
    }
}

/// The sidebar pages. Snapshot mode walks through every case.
enum SidebarItem: String, CaseIterable, Identifiable {
    case all, inProgress, completed, starred
    case canvas, translator, aiChat, skills
    case designLab, inspirations, styles, winSync

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Все идеи"
        case .inProgress: "В разработке"
        case .completed: "Готово"
        case .starred: "Избранное"
        case .canvas: "Холст топологии"
        case .translator: "Промпт-переводчик"
        case .aiChat: "AI-Советник"
        case .skills: "База скиллов"
        case .designLab: "Лаборатория дизайна"
        case .inspirations: "Вдохновение"
        case .styles: "Стили и токены"
        case .winSync: "Синхронизация P2P"
        }
    }

    var symbol: String {
        switch self {
        case .all: "lightbulb"
        case .inProgress: "bolt.fill"
        case .completed: "checkmark.circle.fill"
        case .starred: "star.fill"
        case .canvas: "rectangle.split.3x3"
        case .translator: "wand.and.stars"
        case .aiChat: "sparkles"
        case .skills: "cpu"
        case .designLab: "slider.horizontal.3"
        case .inspirations: "photo.stack"
        case .styles: "paintpalette.fill"
        case .winSync: "arrow.triangle.2.circlepath"
        }
    }

    var sectionTitle: String {
        switch self {
        case .all, .inProgress, .completed, .starred: "Проекты и бэклог"
        case .canvas, .translator, .aiChat, .skills: "Архитектура и синтез"
        case .designLab, .inspirations, .styles, .winSync: "Дизайн и интеграции"
        }
    }
}

public enum EngineeringStudioSheet: String, Identifiable, Sendable, CaseIterable {
    // Wave 1: Schema & Data
    case dataSchema
    case modelRouter
    case indexOptimizer
    case seedData
    case vectorStore
    case migrationStrategist

    // Wave 2: Services & API
    case apiContracts
    case rpcContracts
    case eventBus
    case jobQueue
    case rateLimiter
    case queryCache
    case realtime
    case webhook
    case webhookDispatcher

    // Wave 3: UI & Design
    case tokenSandbox
    case stateFlow
    case sitemap
    case accessibility
    case seoStudio
    case interactiveMockup

    // Wave 4: QA, Security & Ops
    case antigravityPack
    case topologyValidator
    case errorDoctor
    case threatModeler
    case secretShield
    case evalHarness
    case gitStory
    case deployBlueprint
    case incidentCommander
    case stressTest
    case runbook

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dataSchema: "Схема данных и БД"
        case .modelRouter: "Маршрутизатор моделей AI"
        case .indexOptimizer: "Оптимизатор индексов SQL"
        case .seedData: "Генератор тестовых данных"
        case .vectorStore: "Векторное хранилище RAG"
        case .migrationStrategist: "Миграции Expand & Contract"

        case .apiContracts: "API-контракты и Mock-сервер"
        case .rpcContracts: "Типизированный RPC / tRPC"
        case .eventBus: "Распределенная шина событий"
        case .jobQueue: "Очереди фоновых задач"
        case .rateLimiter: "Защита от DDoS и Rate Limiter"
        case .queryCache: "Двухуровневый кэш запросов"
        case .realtime: "Потоковый Realtime WebSockets"
        case .webhook: "Симулятор вебхуков"
        case .webhookDispatcher: "Диспетчер исходящих вебхуков"

        case .tokenSandbox: "Песочница дизайн-токенов"
        case .stateFlow: "Стейт-машина интерфейса"
        case .sitemap: "Карта экранов и роутер"
        case .accessibility: "Аудит доступности WCAG"
        case .seoStudio: "SEO и метаданные Next.js"
        case .interactiveMockup: "Интерактивный HTML-макет"

        case .antigravityPack: "Пакет Antigravity и Wave Runner"
        case .topologyValidator: "Валидатор топологии холста"
        case .errorDoctor: "Доктор сбоев терминала"
        case .threatModeler: "Моделирование угроз OWASP"
        case .secretShield: "Защита от утечки секретов"
        case .evalHarness: "Регрессионные тесты и эвалы"
        case .gitStory: "Conventional Commits и PR"
        case .deployBlueprint: "Blueprints деплоя Vercel/Docker"
        case .incidentCommander: "План аварийного восстановления"
        case .stressTest: "Нагрузочные тесты k6"
        case .runbook: "Runbook разработчика"
        }
    }
}

/// App-wide state that menus, toolbars, and views share.
@Observable
final class AppModel {
    let container: ModelContainer
    var sidebar: SidebarItem? = .all
    var selection: PersistentIdentifier?
    var activeStudioSheet: EngineeringStudioSheet? = nil
    /// Settings reopens on the last tab. Test and snapshot runs leave it alone.
    var settingsTab: SettingsTab = SettingsTab(rawValue: UserDefaults.standard.string(forKey: "settings.tab") ?? "") ?? .general {
        didSet { if !Store.isOverridden { UserDefaults.standard.set(settingsTab.rawValue, forKey: "settings.tab") } }
    }

    init(container: ModelContainer) {
        self.container = container
    }

    func addItem(title: String = "", concept: String = "", platform: String = "Web", style: String = "Editorial & Swiss Modern") {
        let item = Item(title: ItemTitle.clean(title))
        item.concept = concept
        item.platform = platform
        item.style = style
        if sidebar == .starred { item.isStarred = true }
        if sidebar == .inProgress { item.status = "in_progress" }
        if sidebar == .completed { item.status = "completed" }
        container.mainContext.insert(item)
        selection = item.id
    }

    func exportIdeas() -> Data? {
        let items = (try? container.mainContext.fetch(FetchDescriptor<Item>())) ?? []
        let dtos = items.map { item in
            IdeaDTO(
                id: item.uuid.uuidString,
                title: item.title,
                description: item.concept,
                platform: item.platform.lowercased(),
                preferredStyle: item.style,
                status: item.status,
                tags: item.tags.components(separatedBy: ",").filter { !$0.isEmpty },
                isStarred: item.isStarred,
                createdAt: ISO8601DateFormatter().string(from: item.createdAt)
            )
        }
        let payload = IdeaExportModel(ideas: dtos)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(payload)
    }

    @discardableResult
    func importIdeas(from data: Data) -> Int {
        guard let payload = try? JSONDecoder().decode(IdeaExportModel.self, from: data) else {
            return 0
        }
        let context = container.mainContext
        let existing = (try? context.fetch(FetchDescriptor<Item>())) ?? []
        var count = 0

        for dto in payload.ideas {
            let cleanTitle = dto.title.trimmingCharacters(in: .whitespaces).lowercased()
            if let match = existing.first(where: {
                $0.title.trimmingCharacters(in: .whitespaces).lowercased() == cleanTitle ||
                $0.uuid.uuidString.lowercased() == dto.id.lowercased()
            }) {
                // Update existing item in place
                if !dto.description.isEmpty && match.concept.isEmpty { match.concept = dto.description }
                if match.status != dto.status { match.status = dto.status }
                if match.isStarred != dto.isStarred { match.isStarred = dto.isStarred }
                if !dto.preferredStyle.isEmpty && match.style.isEmpty { match.style = dto.preferredStyle }
                continue
            }

            let item = Item(title: dto.title)
            item.concept = dto.description
            item.platform = dto.platform.capitalized
            item.style = dto.preferredStyle
            item.status = dto.status
            item.isStarred = dto.isStarred
            item.tags = dto.tags.joined(separator: ",")
            context.insert(item)
            count += 1
        }
        try? context.save()
        return count
    }

    // MARK: - Canvas State & Sync
    var canvasFrames: [CanvasFrame] = [
        CanvasFrame(
            title: "Архитектурные принципы и UI/UX",
            colorHex: "#3B82F6",
            x: 480,
            y: 40,
            width: 440,
            height: 520
        )
    ]
    var canvasStickies: [CanvasSticky] = [
        CanvasSticky(text: "Архитектурный контраст: отказ от серого слопа", colorHex: "#FEF08A", position: CGPoint(x: 600, y: 140)),
        CanvasSticky(text: "44px Touch Targets & Apple HIG 4pt Grid", colorHex: "#BBF7D0", position: CGPoint(x: 600, y: 380)),
        CanvasSticky(text: "Zero-latency нативный отклик SwiftData", colorHex: "#DDD6FE", position: CGPoint(x: 200, y: 440))
    ]
    var canvasReferenceCards: [CanvasReferenceCard] = [
        CanvasReferenceCard(
            title: "Linear Navigation & Command HUD",
            source: "Mobbin",
            url: "https://mobbin.com",
            colorHex: "#10B981",
            position: CGPoint(x: 200, y: 180),
            tags: ["Shortcuts", "Ergonomics", "Dark Mode"],
            description: "Референс компактной навигации и быстрого доступа через клавиши."
        )
    ]
    var canvasConnections: [CanvasConnection] = []

    func exportCanvas() -> Data? {
        let payload = CanvasExportModel(
            frames: canvasFrames,
            stickies: canvasStickies,
            referenceCards: canvasReferenceCards,
            connections: canvasConnections
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(payload)
    }

    @discardableResult
    func importCanvas(from data: Data) -> Bool {
        guard let payload = try? JSONDecoder().decode(CanvasExportModel.self, from: data) else {
            return false
        }
        if payload.replace == true {
            canvasFrames = payload.frames
            canvasStickies = payload.stickies
            canvasReferenceCards = payload.referenceCards
            canvasConnections = payload.connections
            return true
        }
        for frame in payload.frames {
            if !canvasFrames.contains(where: { $0.title == frame.title || $0.id == frame.id }) {
                canvasFrames.append(frame)
            }
        }
        for sticky in payload.stickies {
            if !canvasStickies.contains(where: { $0.text == sticky.text || $0.id == sticky.id }) {
                canvasStickies.append(sticky)
            }
        }
        for refCard in payload.referenceCards {
            if !canvasReferenceCards.contains(where: { $0.title == refCard.title || $0.id == refCard.id }) {
                canvasReferenceCards.append(refCard)
            }
        }
        for conn in payload.connections {
            if !canvasConnections.contains(where: { $0.fromId == conn.fromId && $0.toId == conn.toId }) {
                canvasConnections.append(conn)
            }
        }
        return true
    }

    func addCapturedReferenceCard(title: String, imageURL: URL, recognizedText: String) {
        let card = CanvasReferenceCard(
            title: title.isEmpty ? "Снимок экрана" : title,
            source: "Screen Snip",
            url: imageURL.path,
            colorHex: "#3B82F6",
            position: CGPoint(x: 200 + CGFloat(canvasReferenceCards.count * 20), y: 220 + CGFloat(canvasReferenceCards.count * 20)),
            tags: ["Capture", "Vision OCR", "Reference"],
            description: recognizedText.isEmpty ? "Фрагмент интерфейса, захваченный с экрана." : recognizedText
        )
        canvasReferenceCards.append(card)
    }
}
