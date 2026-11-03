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
    case all, inProgress, completed, starred, styles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Все идеи"
        case .inProgress: "В разработке"
        case .completed: "Готово"
        case .starred: "Избранное"
        case .styles: "Стили и токены"
        }
    }

    var symbol: String {
        switch self {
        case .all: "lightbulb"
        case .inProgress: "bolt.fill"
        case .completed: "checkmark.circle.fill"
        case .starred: "star.fill"
        case .styles: "paintpalette.fill"
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
}
