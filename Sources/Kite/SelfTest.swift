import AppKit
import SwiftData
import KiteKit

/// Self-test for agents: runs the app's real functions on a test store,
/// prints PASS or FAIL per check, and quits with exit code 0 or 1.
///   APP_STORE=/tmp/Kite-self.store ~/Applications/Kite.app/Contents/MacOS/Kite --selftest
/// (tools/selftest.sh does this.) Add a check for every story with logic.
@MainActor
enum SelfTest {
    static var requested: Bool { CommandLine.arguments.contains("--selftest") }
    static var exitCode: Int32 = 0
    private static var failures = 0
    private static var count = 0

    static func run(model: AppModel) {
        guard requested else { return }
        setvbuf(stdout, nil, _IONBF, 0)
        guard Store.isOverridden else {
            print("SELFTEST refused: set APP_STORE to a file in /tmp")
            finish(code: 1)
            return
        }

        let context = model.container.mainContext
        func items() -> [Item] { (try? context.fetch(FetchDescriptor<Item>())) ?? [] }

        let before = items().count
        model.addItem()
        check("New Item adds one item", items().count == before + 1)
        check("the new item is selected", model.selection != nil)

        if let item = items().first(where: { $0.id == model.selection }) {
            item.isStarred.toggle()
            check("starring an item marks it starred", item.isStarred)
            context.delete(item)
            try? context.save()
            check("deleting the item removes it", items().count == before)
        }
        check("titles are cleaned", ItemTitle.clean("  Buy   milk ") == "Buy milk")

        let titleHit = ItemSearch.score(query: "notes", fields: [.init("Notes app", weight: 5), .init("sync", weight: 1)])
        let bodyHit = ItemSearch.score(query: "notes", fields: [.init("Reader", weight: 5), .init("keeps notes", weight: 2)])
        check("search ranks a title hit above a concept hit", (titleHit ?? 0) > (bodyHit ?? 0))
        check("search needs every token to match", ItemSearch.score(query: "notes zzz", fields: [.init("Notes app", weight: 5)]) == nil)
        check("search folds case and diacritics", ItemSearch.score(query: "cafe", fields: [.init("Caf\u{E9} Menu", weight: 5)]) != nil)
        check("an empty query matches everything", ItemSearch.score(query: "  ", fields: [.init("Notes app", weight: 5)]) == 0)
        check("a repeated word still matches", ItemSearch.score(query: "notes notes", fields: [.init("Notes app", weight: 5)]) != nil)
        check("search matches Russian prefixes", ItemSearch.score(query: "тестов иде", fields: [.init("Тестовая идея P2P", weight: 5)]) != nil)
        let skillIndex = SkillsRepository.curated.compactMap { skill -> (String, Int)? in
            let doc = ItemSearch.Document(fields: [.init(skill.name, weight: 6), .init(skill.command, weight: 6), .init(skill.description, weight: 1)])
            return doc.score(queryTokens: ItemSearch.tokens("emil design")).map { (skill.name, $0) }
        }
        check("skills search ranks emil-design-eng first", skillIndex.max { $0.1 < $1.1 }?.0 == "emil-design-eng")

        let idea = "Трекер подписок с напоминанием за три дня до списания"
        func translator(_ mode: String) -> String {
            AIPrompts.translator(mode: mode, rawPrompt: idea, platform: "Desktop", style: "Claude Parchment", skills: ["/site-md", "/design-md"])
        }
        let modes = ["full", "stitch", "edit", "concise", "action"]
        check("every translator mode asks the model for a different artifact", Set(modes.map(translator)).count == modes.count)
        check("the translator prompt carries the idea verbatim", modes.allSatisfy { translator($0).contains(idea) })
        check("the translator prompt carries the style tokens", translator("full").contains(DesignSystemTokens.resolve(for: "Claude Parchment").accent))
        check("the translator prompt bans filler words", translator("full").contains("интуитивный интерфейс"))
        check("the translator prompt lists the chosen skills", translator("full").contains("/plan /site-md /design-md"))
        let chat = AIPrompts.chatSystem(context: .init(ideas: ["Трекер подписок (Desktop)"]))
        check("the chat prompt knows the user's ideas", chat.contains("Трекер подписок"))
        check("the chat prompt tells the model to commit to one recommendation", chat.contains("Выбирай один вариант"))

        print(failures == 0 ? "SELFTEST PASS \(count) checks" : "SELFTEST FAIL \(failures) of \(count) checks")
        finish(code: failures == 0 ? 0 : 1)
    }

    static func runIfRequested(model: AppModel) {
        run(model: model)
    }

    private static func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        count += 1
        if !ok { failures += 1 }
        print(ok ? "PASS \(name)" : "FAIL \(name)\(detail.isEmpty ? "" : ": \(detail)")")
    }

    /// Quits through exit, never hangs on background run loops
    static func finish(code: Int32) {
        exitCode = code
        fflush(stdout)
        exit(code)
    }
}
