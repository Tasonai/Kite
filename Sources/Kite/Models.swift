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
    case translator, skills
    case inspirations, styles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Все идеи"
        case .inProgress: "В разработке"
        case .completed: "Готово"
        case .starred: "Избранное"
        case .translator: "Промпт-переводчик"
        case .skills: "База скиллов"
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
        case .translator: "wand.and.stars"
        case .skills: "cpu"
        case .inspirations: "photo.stack"
        case .styles: "paintpalette.fill"
        }
    }

    var sectionTitle: String {
        switch self {
        case .all, .inProgress, .completed, .starred: "Идеи и проекты"
        case .translator, .skills: "Студия Antigravity"
        case .inspirations, .styles: "Дизайн и референсы"
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
        var count = 0
        for dto in payload.ideas {
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
}
