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
    case aiChat, translator, skills, winSync
    case canvas, designLab, inspirations, styles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Все идеи"
        case .inProgress: "В разработке"
        case .completed: "Готово"
        case .starred: "Избранное"
        case .aiChat: "AI-Архитектор"
        case .translator: "Промпт-переводчик"
        case .skills: "База скиллов"
        case .winSync: "Синхронизация P2P"
        case .canvas: "Холст идей"
        case .designLab: "Лаборатория дизайна"
        case .inspirations: "Вдохновение"
        case .styles: "Стили и токены"
        }
    }

    var symbol: String {
        switch self {
        case .all: "lightbulb"
        case .inProgress: "bolt.fill"
        case .completed: "checkmark.circle.fill"
        case .starred: "star.fill"
        case .aiChat: "sparkles"
        case .translator: "wand.and.stars"
        case .skills: "cpu"
        case .winSync: "arrow.triangle.2.circlepath"
        case .canvas: "rectangle.split.3x3"
        case .designLab: "slider.horizontal.3"
        case .inspirations: "photo.stack"
        case .styles: "paintpalette.fill"
        }
    }

    var sectionTitle: String {
        switch self {
        case .all, .inProgress, .completed, .starred: "Идеи и проекты"
        case .aiChat, .translator, .skills, .winSync: "Студия Antigravity"
        case .canvas, .designLab, .inspirations, .styles: "Дизайн и референсы"
        }
    }
}

/// App-wide state that menus, toolbars, and views share.
@Observable
final class AppModel {
    let container: ModelContainer
    var sidebar: SidebarItem? = .all
    var selection: PersistentIdentifier?
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
