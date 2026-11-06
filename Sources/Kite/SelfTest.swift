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
        check("a retired Gemini model name falls back to the default", GeminiClient.modelChain(requested: "gemini-2.5-flash").first == GeminiClient.defaultModel)
        check("a chosen model is tried first", GeminiClient.modelChain(requested: "gemini-3.1-pro-preview").first == "gemini-3.1-pro-preview")
        let chain = GeminiClient.modelChain(requested: "gemini-3.5-flash")
        check("the model chain has fallbacks and no repeats", chain.count > 1 && Set(chain).count == chain.count)
        let sseLine = #"data: {"candidates":[{"content":{"parts":[{"text":"Привет"},{"thought":true,"text":"скрыто"},{"text":", мир"}]}}]}"#
        check("a streamed line yields its text and skips thoughts", GeminiClient.streamedText(fromLine: sseLine) == "Привет, мир")
        check("lines that carry no data yield nothing", GeminiClient.streamedText(fromLine: "") == nil && GeminiClient.streamedText(fromLine: ": keep-alive") == nil)
        let withThinking: [String: Any] = ["generationConfig": ["temperature": 0.8, "thinkingConfig": ["thinkingLevel": "low"]]]
        let stripped = GeminiClient.withoutThinking(withThinking)?["generationConfig"] as? [String: Any]
        check("the thinking setting can be removed for models that reject it", stripped != nil && stripped?["thinkingConfig"] == nil && stripped?["temperature"] != nil)
        check("a payload without a thinking setting has nothing to strip", GeminiClient.withoutThinking(["generationConfig": ["temperature": 0.8]]) == nil)
        check("short translator modes think briefly, the plan mode does not", AIGenerator.thinkingLevel(forMode: "action") == "low" && AIGenerator.thinkingLevel(forMode: "full") == nil)
        let fenced = "Вот вопросы:\n```json\n[{\"question\": \"Как узнать о списаниях?\", \"options\": [\"Ручной ввод\", \"Email\", \"Банк\", \"Лишний\"]}, {\"question\": \"  \", \"options\": [\"x\"]}]\n```"
        let parsed = AIPrompts.parseInterview(fenced)
        check("interview questions are read out of a fenced reply", parsed.count == 1 && parsed[0].text == "Как узнать о списаниях?")
        check("an interview question keeps at most three options", parsed.first?.options.count == 3)
        check("an unreadable interview reply gives no questions", AIPrompts.parseInterview("извините, не могу").isEmpty)
        check("at most three interview questions are kept", AIPrompts.parseInterview(#"[{"question":"a","options":[]},{"question":"b","options":[]},{"question":"c","options":[]},{"question":"d","options":[]}]"#).count == 3)
        let enriched = AIPrompts.enrich(idea: "Трекер", answers: [(question: "Где данные?", answer: "Только на Mac"), (question: "Кто?", answer: "  ")])
        check("answers are appended to the idea and blank ones are dropped", enriched.contains("Где данные? Только на Mac") && !enriched.contains("Кто?"))
        check("answers come with an order to restate them as decisions", enriched.contains("Принятые решения автора"))
        check("an idea without answers stays unchanged", AIPrompts.enrich(idea: "Трекер", answers: []) == "Трекер")
        let historyURL = FileManager.default.temporaryDirectory.appending(path: "kite-selftest-chat-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: historyURL) }
        ChatHistoryStore.save([ChatMessageItem(role: "user", content: "Привет"), ChatMessageItem(role: "assistant", content: "Здравствуйте")], to: historyURL)
        let restored = ChatHistoryStore.load(from: historyURL)
        check("the chat history survives a save and load", restored?.map(\.content) == ["Привет", "Здравствуйте"] && restored?.first?.role == "user")
        ChatHistoryStore.save((0..<250).map { ChatMessageItem(role: "user", content: "\($0)") }, to: historyURL)
        check("the chat history keeps only the latest messages", ChatHistoryStore.load(from: historyURL)?.count == ChatHistoryStore.limit)
        check("a missing chat history file gives nothing", ChatHistoryStore.load(from: historyURL.appendingPathExtension("none")) == nil)
        let withWorkspace = AIPrompts.chatSystem(context: .init(ideas: ["A"], selectedIdea: "Трекер подписок (Desktop)", canvas: "Фреймы: Архитектура"))
        check("the chat prompt includes the open idea", withWorkspace.contains("Трекер подписок (Desktop)"))
        check("the chat prompt includes the canvas", withWorkspace.contains("Фреймы: Архитектура"))
        check("the chat prompt omits the open idea and canvas when there are none", !AIPrompts.chatSystem(context: .init(ideas: ["A"])).contains("Сейчас у пользователя открыта идея"))
        let chat = AIPrompts.chatSystem(context: .init(ideas: ["Трекер подписок (Desktop)"]))
        check("the chat prompt knows the user's ideas", chat.contains("Трекер подписок"))
        check("the chat prompt states how Kite sync works", chat.contains("24242") && chat.contains("без сервера"))
        check("the chat prompt forbids contradicting the recommendation", chat.contains("не должны спорить"))
        check("the chat prompt tells the model to commit to one recommendation", chat.contains("Выбирай один вариант"))

        let testPeer = KitePeer(id: "test-peer-1", app: "Kite", platform: "macOS", hostname: "MacBook", ip: "127.0.0.1", port: 24242)
        let peerData = (try? JSONEncoder().encode(testPeer)) ?? Data()
        let decodedPeer = try? JSONDecoder().decode(KitePeer.self, from: peerData)
        check("LAN peer serialization preserves fields", decodedPeer?.id == testPeer.id && decodedPeer?.hostname == "MacBook")

        let exportJson = #"{"version":1,"exportedAt":"2026-11-06T12:00:00Z","frames":[],"stickies":[]}"#
        let decodedDoc = try? JSONDecoder().decode(CanvasExportModel.self, from: Data(exportJson.utf8))
        check("CanvasExportModel handles empty frames and connections", decodedDoc?.connections.isEmpty == true && decodedDoc?.frames.isEmpty == true)

        let testFrame = CanvasFrame(title: "Subsystem", x: 100, y: 100, width: 200, height: 200)
        check("CanvasFrame computes bounding box correctly", testFrame.rect.contains(CGPoint(x: 150, y: 150)) && !testFrame.rect.contains(CGPoint(x: 50, y: 50)))

        let localSticky = CanvasSticky(text: "Local Note", colorHex: "#FEF08A", position: CGPoint(x: 100, y: 100))
        let remoteSticky = CanvasSticky(text: "Remote Windows Note", colorHex: "#BBF7D0", position: CGPoint(x: 300, y: 100))
        let remoteDoc = CanvasExportModel(stickies: [remoteSticky])
        let mergedResult = CanvasConflictResolver.merge(
            localFrames: [],
            localStickies: [localSticky],
            localReferenceCards: [],
            localConnections: [],
            remote: remoteDoc
        )
        check("CanvasConflictResolver preserves local items and unions remote", mergedResult.stickies.count == 2 && mergedResult.addedNodesCount == 1)

        let pitfalls = AIPitfallProtector.analyze(concept: "Сервис с авторизацией и оплатой подписки", platform: "Web")
        check("AIPitfallProtector detects auth and payment traps", pitfalls.contains(where: { $0.id == "auth-complexity" }) && pitfalls.contains(where: { $0.id == "payment-setup" }))

        let starterPrompt = PromptCompiler.compileStarterPrompt(title: "Habit Tracker", concept: "Track habits", platform: "Web", style: "Minimal")
        check("PromptCompiler creates step-by-step starter prompt", starterPrompt.contains("ШАГ 1") && starterPrompt.contains("Habit Tracker"))

        check("EditorLauncher provides terminal and checks editor availability", EditorLauncher.isAvailable(.terminal))

        let mockupHTML = WebMockupGenerator.generateInteractiveHTML(title: "Test Mockup", concept: "Live test", platform: "Web", style: "Minimal")
        check("WebMockupGenerator generates valid interactive HTML", mockupHTML.contains("<!DOCTYPE html>") && mockupHTML.contains("Test Mockup"))

        check("CanvasBlueprintPacks provides pre-configured architecture templates", CanvasBlueprintPacks.all.count >= 4 && CanvasBlueprintPacks.microSaaS.frames.count == 2)

        let antigravityMD = AntigravityPackGenerator.generateAntigravityMD(title: "Habit Tracker", concept: "Track daily habits", platform: "Mobile", style: "Minimal")
        check("AntigravityPackGenerator compiles valid ANTIGRAVITY.md with token rules and negative scope", antigravityMD.contains("ANTIGRAVITY PROJECT SPECIFICATION") && antigravityMD.contains("Правила Экономии Токенов"))

        let waves = AntigravityPackGenerator.buildWaves(title: "Task App", concept: "Task management", platform: "Web", style: "Swiss")
        check("AntigravityPackGenerator builds 4 progressive execution waves", waves.count == 4 && waves.first?.id == 1 && waves.first?.negativeScope.isEmpty == false)

        let report = AntigravityReadinessLinter.evaluate(title: "Portfolio", concept: "Personal portfolio website with interactive projects", platform: "Web", style: "Editorial")
        check("AntigravityReadinessLinter accurately evaluates readiness and flight status", report.score >= 80 && report.isFlightReady && report.items.count == 5)

        let sampleFrame = CanvasFrame(id: UUID(), title: "Frontend Subsystem", colorHex: "#3B82F6", x: 0, y: 0, width: 400, height: 400)
        let sampleConn = CanvasConnection(fromId: "node_a", toId: "node_b", label: "HTTP/REST")
        let mmdExport = CanvasExporter.exportMermaid(items: [], connections: [sampleConn], frames: [sampleFrame], itemPositions: [:])
        check("CanvasExporter includes subgraphs and connection protocol badges in Mermaid", mmdExport.contains("subgraph") && mmdExport.contains("-->|HTTP/REST|"))

        let diag = VibeErrorDoctor.diagnose(rawLog: "Cannot find module '@supabase/supabase-js' from /src/api.ts:24")
        check("VibeErrorDoctor diagnoses missing dependency and produces surgical prompt", diag.category == .missingDependency && diag.targetFile == "api.ts" && diag.lineNumber == 24)

        let schemaSQL = DataSchemaDesigner.generateSQL(entities: DataSchemaDesigner.starterPack)
        let schemaPrisma = DataSchemaDesigner.generatePrisma(entities: DataSchemaDesigner.starterPack)
        check("DataSchemaDesigner generates valid SQL DDL and Prisma models", schemaSQL.contains("CREATE TABLE") && schemaPrisma.contains("model User"))

        let tempAuditDir = FileManager.default.temporaryDirectory.appendingPathComponent("kite_test_audit_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempAuditDir, withIntermediateDirectories: true)
        let dirtyFile = tempAuditDir.appendingPathComponent("Test.ts")
        try? "console.log('debug output');\n// TODO: finish this\n".write(to: dirtyFile, atomically: true, encoding: .utf8)
        let audit = CodebaseAuditor.audit(directory: tempAuditDir)
        try? FileManager.default.removeItem(at: tempAuditDir)
        check("CodebaseAuditor detects leftover logs and produces polish prompt", audit.findings.contains(where: { $0.issueType == .leftoverLog }) && audit.polishPrompt.contains("[ANTIGRAVITY CLEANUP"))

        check("InstantPreviewServer initializes with valid port", InstantPreviewServer.shared.localPort == 49495)

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
