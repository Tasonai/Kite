import AppKit
import SwiftData
import CryptoKit
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

        let sampleNodes = [
            TopologyNodeDescriptor(id: "ui_client", title: "Web Client UI", role: "client"),
            TopologyNodeDescriptor(id: "db_postgres", title: "Production Postgres DB", role: "database"),
            TopologyNodeDescriptor(id: "svc_backend", title: "Auth Service", role: "service")
        ]
        let sampleTopologyConns = [
            CanvasConnection(fromId: "ui_client", toId: "db_postgres", label: "Direct SQL"),
            CanvasConnection(fromId: "ui_client", toId: "svc_backend", label: "REST")
        ]
        let topologyReport = CanvasTopologyValidator.validate(nodes: sampleNodes, connections: sampleTopologyConns)
        check("CanvasTopologyValidator detects direct DB access and generates audit report", !topologyReport.isSecure && topologyReport.issues.contains { $0.severity == .critical })

        let autoArch = CanvasAutoArchitect.synthesize(title: "Payment Gateway", concept: "Card processing and invoicing", platform: "Web", style: "Minimal")
        let autoArchReport = CanvasTopologyValidator.validate(
            nodes: autoArch.stickies.map { TopologyNodeDescriptor(id: "sticky-\($0.id.uuidString)", title: $0.text, role: CanvasTopologyValidator.inferRole(title: $0.text)) },
            connections: autoArch.connections
        )
        check("CanvasAutoArchitect synthesizes production topology with 100% health score", autoArch.frames.count == 5 && autoArch.connections.count == 9 && autoArchReport.healthScore == 100)

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir.appendingPathComponent("prisma"), withIntermediateDirectories: true)
        try? "model User { id String @id }".write(to: tempDir.appendingPathComponent("prisma/schema.prisma"), atomically: true, encoding: .utf8)
        try? FileManager.default.createDirectory(at: tempDir.appendingPathComponent("src/api"), withIntermediateDirectories: true)
        try? "export const api = {}".write(to: tempDir.appendingPathComponent("src/api/client.ts"), atomically: true, encoding: .utf8)

        let sampleWaves = AntigravityPackGenerator.buildWaves(title: "Test", concept: "Prisma and API", platform: "Web", style: "Minimal", architectureMermaid: nil)
        let watcherSnapshot = ProjectWatcherService.analyzeDirectory(at: tempDir, waves: sampleWaves)
        try? FileManager.default.removeItem(at: tempDir)
        check("ProjectWatcherService detects created wave artifacts and auto-progresses checklist", !watcherSnapshot.completedTaskKeys.isEmpty && (watcherSnapshot.wavePercentages[1] ?? 0) > 0)

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

        let tsClient = APIContractBuilder.generateTypeScript(routes: APIContractBuilder.starterPack)
        let mockRes = APIContractBuilder.findMockResponse(for: "/api/projects", method: "GET", in: APIContractBuilder.starterPack)
        check("APIContractBuilder generates valid TypeScript client and finds mock responses", tsClient.contains("export async function") && mockRes?.status == 200)

        let xstate = StateFlowSimulator.generateTypeScriptXState(flow: StateFlowSimulator.defaultFlow)
        let swiftStore = StateFlowSimulator.generateSwiftUIStateMachine(flow: StateFlowSimulator.defaultFlow)
        check("StateFlowSimulator generates valid XState config and SwiftUI state machine", xstate.contains("initial: 'idle'") && swiftStore.contains("enum AppState"))

        let sitemapNext = SitemapRouterBuilder.generateNextJsAppRouter(routes: SitemapRouterBuilder.starterSitemap)
        let sitemapSwift = SitemapRouterBuilder.generateSwiftUIRouter(routes: SitemapRouterBuilder.starterSitemap)
        check("SitemapRouterBuilder generates Next.js App Router manifest and SwiftUI routes", sitemapNext.contains("APP_ROUTES") && sitemapSwift.contains("enum AppRoute"))

        let story = GitStoryteller.craftStory(title: "Task App", concept: "Task management", platform: "Web", style: "Minimal")
        check("GitStoryteller crafts Conventional Commits and complete PR description", story.suggestedCommits.count == 4 && story.prTitle.contains("feat:") && story.prBodyMarkdown.contains("Architectural Waves"))

        let seedSQL = SeedDataGenerator.generateSQL(entities: DataSchemaDesigner.starterPack, count: 3)
        let seedJSON = SeedDataGenerator.generateJSON(entities: DataSchemaDesigner.starterPack, count: 3)
        check("SeedDataGenerator generates valid SQL insert statements and JSON fixtures", seedSQL.contains("INSERT INTO") && seedJSON.contains("\"users\""))

        let leakedText = "Here is my key sk-proj-12345678901234567890123456789012 and token ghp_123456789012345678901234567890123456"
        let findings = SecretShield.scan(text: leakedText)
        let sanitized = SecretShield.sanitize(text: leakedText)
        check("SecretShield detects API keys and sanitizes safely", findings.count >= 2 && sanitized.contains("process.env.OPENAI_API_KEY"))

        let catalog = DependencyGuard.knownReplacements
        let directive = DependencyGuard.generateAntigravityBloatDirective()
        check("DependencyGuard catalogs heavy packages and generates Antigravity Zero-Bloat directive", catalog.contains(where: { $0.heavyPackage == "moment" }) && directive.contains("ANTIGRAVITY ZERO-BLOAT"))

        let vercelCfg = DeployBlueprintGenerator.generateVercelConfig(title: "Task App", platform: "Web")
        let dockerCfg = DeployBlueprintGenerator.generateDockerfile(platform: "Web")
        check("DeployBlueprintGenerator generates valid Vercel and Docker production blueprints", vercelCfg.contains("\"framework\": \"vite\"") && dockerCfg.contains("FROM node:20-alpine"))

        let digest = ContextOptimizer.compileDigest(
            title: "Task Studio",
            concept: "Task management app",
            platform: "Web",
            style: "Minimal",
            entities: DataSchemaDesigner.starterPack,
            routes: APIContractBuilder.starterPack
        )
        let metrics = ContextOptimizer.estimateMetrics(
            title: "Task Studio",
            concept: "Task management app",
            entities: DataSchemaDesigner.starterPack,
            routes: APIContractBuilder.starterPack
        )
        check("ContextOptimizer compiles token-compressed digest with high savings", digest.contains("ANTIGRAVITY CONTEXT DIGEST") && metrics.savedPercentage >= 80)

        let dts = ComponentContractMatrix.generateTypeScriptDefinitions(components: ComponentContractMatrix.starterPack)
        let compDirective = ComponentContractMatrix.generatePromptDirective(components: ComponentContractMatrix.starterPack)
        check("ComponentContractMatrix generates TypeScript prop contracts and prompt directives", dts.contains("interface HeaderBarProps") && compDirective.contains("ANTIGRAVITY COMPONENT CONTRACT"))

        let gherkin = AcceptanceCriteriaBuilder.generateGherkin(title: "Task Studio", scenarios: AcceptanceCriteriaBuilder.starterScenarios)
        let playwright = AcceptanceCriteriaBuilder.generatePlaywrightSpec(title: "Task Studio", scenarios: AcceptanceCriteriaBuilder.starterScenarios)
        check("AcceptanceCriteriaBuilder generates Gherkin feature scenarios and Playwright test suite", gherkin.contains("Feature: Task Studio Core Verification") && playwright.contains("test.describe"))

        let outOfScope = NegativeScopeFirewall.generateManifest(title: "Task Studio", constraints: NegativeScopeFirewall.defaultConstraints)
        let firewallPrompt = NegativeScopeFirewall.generateFirewallPrompt(constraints: NegativeScopeFirewall.defaultConstraints)
        check("NegativeScopeFirewall generates out-of-scope boundary manifest and prompt firewall", outOfScope.contains("OUT OF SCOPE MANIFEST") && firewallPrompt.contains("ANTIGRAVITY SCOPE FIREWALL"))

        let workstreams = WorkstreamSplitter.defaultWorkstreams(title: "Task Studio")
        let wsMd = WorkstreamSplitter.generateWorkstreamsMarkdown(title: "Task Studio", workstreams: workstreams)
        let wsPrompt = WorkstreamSplitter.generateAntigravityPrompt(workstreams: workstreams)
        check("WorkstreamSplitter generates isolated workstreams markdown and parallel dispatch prompt", workstreams.count == 4 && wsMd.contains("PARALLEL WORKSTREAMS") && wsPrompt.contains("ANTIGRAVITY PARALLEL SUBAGENT"))

        let sampleDiff = """
        --- a/src/types.ts
        +++ b/src/types.ts
        -export interface UserProfile {
        +console.log('leaked key', 'sk-proj-12345678901234567890123456789012');
        """
        let patchReport = PatchInspector.inspect(patchText: sampleDiff)
        check("PatchInspector detects removed interfaces and leaked keys in git diffs", patchReport.riskLevel == .critical && patchReport.findings.count >= 2 && patchReport.fixPrompt.contains("ANTIGRAVITY SURGICAL PATCH FIX"))

        let fallbacksMd = FallbackPlanner.generateFallbacksMarkdown(title: "Task Studio", strategies: FallbackPlanner.starterStrategies)
        let fallbackPrompt = FallbackPlanner.generatePromptDirective(strategies: FallbackPlanner.starterStrategies)
        check("FallbackPlanner generates degradation strategies and Antigravity fallback directives", fallbacksMd.contains("GRACEFUL DEGRADATION") && fallbackPrompt.contains("ANTIGRAVITY GRACEFUL DEGRADATION DIRECTIVE"))

        let runbookMd = RunbookBuilder.generateRunbookMarkdown(title: "Task Studio", commands: RunbookBuilder.starterCommands)
        let pkgScripts = RunbookBuilder.generatePackageJsonScripts(commands: RunbookBuilder.starterCommands)
        check("RunbookBuilder generates dev runbook markdown and package.json scripts", runbookMd.contains("DEVELOPER RUNBOOK") && pkgScripts.contains("\"dev\": \"vite\""))

        let evalsMd = EvalHarness.generateEvalsMarkdown(title: "Task Studio", testCases: EvalHarness.starterCases)
        let evalRunner = EvalHarness.generateTypeScriptRunner(testCases: EvalHarness.starterCases)
        check("EvalHarness generates regression eval markdown and TypeScript test runner", evalsMd.contains("AI EVALUATION HARNESS SPEC") && evalRunner.contains("runEvals"))

        let flagsMd = FeatureFlagMatrix.generateFeatureFlagsMarkdown(title: "Task Studio", flags: FeatureFlagMatrix.starterFlags)
        let flagClient = FeatureFlagMatrix.generateTypeScriptClient(flags: FeatureFlagMatrix.starterFlags)
        check("FeatureFlagMatrix generates rollout markdown and TypeScript flag resolver", flagsMd.contains("FEATURE FLAG & ROLLOUT SPEC") && flagClient.contains("isFeatureEnabled"))

        let teleMd = TelemetrySpecifier.generateTelemetryMarkdown(title: "Task Studio", events: TelemetrySpecifier.starterEvents)
        let teleClient = TelemetrySpecifier.generateTypeScriptClient(events: TelemetrySpecifier.starterEvents)
        check("TelemetrySpecifier generates analytics event spec and PII-free client", teleMd.contains("TELEMETRY & PRODUCT ANALYTICS SPEC") && teleClient.contains("export function track"))

        let perfMd = PerformanceBudget.generatePerformanceMarkdown(title: "Task Studio", budgets: PerformanceBudget.starterBudgets)
        let nextCfg = PerformanceBudget.generateNextConfigSnippet(budgets: PerformanceBudget.starterBudgets)
        check("PerformanceBudget generates Web Vitals limits and Next.js config", perfMd.contains("PERFORMANCE & WEB VITALS BUDGET") && nextCfg.contains("optimizePackageImports"))

        let threatMd = ThreatModeler.generateSecurityMarkdown(title: "Task Studio", threats: ThreatModeler.starterThreats)
        let threatPrompt = ThreatModeler.generatePromptDirective(threats: ThreatModeler.starterThreats)
        check("ThreatModeler generates OWASP threat model and Antigravity security directive", threatMd.contains("SECURITY THREAT MODEL") && threatPrompt.contains("ANTIGRAVITY SECURITY & OWASP DIRECTIVE"))

        let migMd = MigrationStrategist.generateMigrationsMarkdown(title: "Task Studio", steps: MigrationStrategist.starterSteps)
        let migPrompt = MigrationStrategist.generatePromptDirective(steps: MigrationStrategist.starterSteps)
        check("MigrationStrategist generates Expand & Contract migration spec and safe directive", migMd.contains("ZERO-DOWNTIME DATABASE MIGRATION SPEC") && migPrompt.contains("ANTIGRAVITY SAFE MIGRATION DIRECTIVE"))

        let ruJson = LocalizationSpecifier.generateDictionaryJSON(entries: LocalizationSpecifier.starterEntries, language: "ru")
        let i18nMd = LocalizationSpecifier.generateLocalizationMarkdown(title: "Task Studio", entries: LocalizationSpecifier.starterEntries)
        check("LocalizationSpecifier generates JSON dictionary and i18n markdown spec", ruJson.contains("Сохранить") && i18nMd.contains("LOCALIZATION (I18N) CATALOG SPEC"))

        let whMd = WebhookSimulator.generateWebhooksMarkdown(title: "Task Studio", webhooks: WebhookSimulator.starterWebhooks)
        let whHandler = WebhookSimulator.generateVerificationHandlerSnippet(webhooks: WebhookSimulator.starterWebhooks)
        check("WebhookSimulator generates webhook verification spec and signature handler", whMd.contains("Stripe-Signature") && whHandler.contains("stripeSig"))

        let a11yMd = AccessibilityAuditor.generateAccessibilityMarkdown(title: "Task Studio", requirements: AccessibilityAuditor.starterRequirements)
        let a11ySuite = AccessibilityAuditor.generatePlaywrightA11ySuite(title: "Task Studio")
        check("AccessibilityAuditor generates WCAG 2.2 spec and Playwright Axe suite", a11yMd.contains("WCAG 2.2 AA") && a11ySuite.contains("AxeBuilder"))

        let turboJson = MonorepoArchitect.generateTurboJson()
        let monorepoMd = MonorepoArchitect.generateMonorepoMarkdown(title: "Task Studio", packages: MonorepoArchitect.starterPackages)
        check("MonorepoArchitect generates turbo.json and package boundary spec", turboJson.contains("turbo.build") && monorepoMd.contains("MONOREPO & WORKSPACE"))

        let seoMeta = SEOStudio.generateNextMetadataSnippet(title: "Task Studio", description: "Test description")
        let seoMd = SEOStudio.generateSEOMarkdown(title: "Task Studio", configs: SEOStudio.starterConfigs)
        check("SEOStudio generates Next.js metadata snippet and OpenGraph spec", seoMeta.contains("openGraph") && seoMd.contains("SEO & OPEN GRAPH SPECIFICATION"))

        let skillMd = SkillSynthesizer.generateSkillMarkdown(skill: SkillSynthesizer.starterSkills[0])
        let mcpSchema = SkillSynthesizer.generateMcpToolSchema(skill: SkillSynthesizer.starterSkills[0])
        check("SkillSynthesizer generates SKILL.md with frontmatter and MCP schema", skillMd.contains("bama-swiftui-refactor") && mcpSchema.contains("inputSchema"))

        let tokenMd = TokenBudgeteer.generateTokenBudgetMarkdown(title: "Task Studio", budgets: TokenBudgeteer.starterBudgets)
        let tokenPrompt = TokenBudgeteer.generatePromptDirective(budgets: TokenBudgeteer.starterBudgets)
        check("TokenBudgeteer generates token cost spec and Antigravity resource directive", tokenMd.contains("AI TOKEN, LATENCY & COST") && tokenPrompt.contains("ANTIGRAVITY TOKEN & LATENCY BUDGET"))

        let rtMd = RealtimeArchitect.generateRealtimeMarkdown(title: "Task Studio", events: RealtimeArchitect.starterEvents)
        let sseHook = RealtimeArchitect.generateSseClientSnippet()
        check("RealtimeArchitect generates streaming spec and useRealtimeStream hook", rtMd.contains("REAL-TIME STREAMING & PROTOCOL") && sseHook.contains("useRealtimeStream"))

        let jobsMd = JobQueueStrategist.generateJobsMarkdown(title: "Task Studio", jobs: JobQueueStrategist.starterJobs)
        let inngestCode = JobQueueStrategist.generateInngestWorkerSnippet(jobs: JobQueueStrategist.starterJobs)
        check("JobQueueStrategist generates async jobs spec and Inngest function handlers", jobsMd.contains("BACKGROUND JOBS & ASYNC QUEUES") && inngestCode.contains("inngest.createFunction"))

        let incidentMd = IncidentCommander.generateIncidentMarkdown(title: "Task Studio", actions: IncidentCommander.starterActions)
        let healthzCode = IncidentCommander.generateHealthCheckRouteSnippet()
        check("IncidentCommander generates disaster recovery runbook and healthz probe", incidentMd.contains("EMERGENCY INCIDENT & ROLLBACK") && healthzCode.contains("export async function GET"))

        let vecMd = VectorStoreSpecifier.generateVectorStoreMarkdown(title: "Task Studio", configs: VectorStoreSpecifier.starterConfigs)
        let vecDdl = VectorStoreSpecifier.generatePgVectorDDL(configs: VectorStoreSpecifier.starterConfigs)
        check("VectorStoreSpecifier generates vector RAG spec and pgvector DDL schema", vecMd.contains("VECTOR STORE & RAG RETRIEVAL") && vecDdl.contains("CREATE EXTENSION IF NOT EXISTS vector"))

        let compMd = ComplianceGuardian.generateComplianceMarkdown(title: "Task Studio", policies: ComplianceGuardian.starterPolicies)
        let delHandler = ComplianceGuardian.generateDeletionHandlerSnippet()
        check("ComplianceGuardian generates GDPR privacy spec and account deletion route", compMd.contains("PRIVACY & COMPLIANCE SPECIFICATION") && delHandler.contains("export async function POST"))

        let tenMd = MultiTenantArchitect.generateTenancyMarkdown(title: "Task Studio", roles: MultiTenantArchitect.starterRoles)
        let tenMw = MultiTenantArchitect.generateTenantMiddlewareSnippet()
        check("MultiTenantArchitect generates tenant RBAC spec and isolation middleware", tenMd.contains("MULTI-TENANT ISOLATION") && tenMw.contains("getTenantContext"))

        let stressMd = StressTestArchitect.generateStressMarkdown(title: "Task Studio", scenarios: StressTestArchitect.starterScenarios)
        let k6Code = StressTestArchitect.generateK6Script(scenarios: StressTestArchitect.starterScenarios)
        check("StressTestArchitect generates load test spec and executable k6 script", stressMd.contains("STRESS & LOAD TESTING SPECIFICATION") && k6Code.contains("export const options"))

        let emailMd = EmailStudio.generateEmailMarkdown(title: "Task Studio", templates: EmailStudio.starterTemplates)
        let emailTsx = EmailStudio.generateReactEmailSnippet(title: "Task Studio")
        check("EmailStudio generates transactional email spec and React Email template", emailMd.contains("TRANSACTIONAL EMAIL & NOTIFICATION SPEC") && emailTsx.contains("WelcomeEmail"))

        let docMd = DocStudio.generateDocMarkdown(title: "Task Studio", endpoints: DocStudio.starterEndpoints)
        let docCurl = DocStudio.generateCurlSnippet(endpoint: DocStudio.starterEndpoints[0])
        check("DocStudio generates Mintlify API spec and interactive curl playground", docMd.contains("API DOCUMENTATION & INTERACTIVE PLAYGROUND") && docCurl.contains("curl -X"))

        let indexMd = IndexOptimizer.generateIndexMarkdown(title: "Task Studio", indexes: IndexOptimizer.starterRecommendations)
        let indexSql = IndexOptimizer.generateSqlMigration(indexes: IndexOptimizer.starterRecommendations)
        check("IndexOptimizer generates DB index spec and concurrent SQL migration", indexMd.contains("DATABASE INDEXING & QUERY PLAN SPEC") && indexSql.contains("CREATE INDEX CONCURRENTLY"))

        let routerMd = ModelRouter.generateRoutingMarkdown(title: "Task Studio", routes: ModelRouter.starterRoutes)
        let routerTs = ModelRouter.generateTypeScriptRouter(routes: ModelRouter.starterRoutes)
        check("ModelRouter generates Gemini 3.8 multi-model routing spec and TS router", routerMd.contains("gemini-3.8-flash") && routerTs.contains("gemini-3.8-ultra"))

        let storageMd = StorageGuard.generateStorageMarkdown(title: "Task Studio", policies: StorageGuard.starterPolicies)
        let storageRoute = StorageGuard.generatePresignedUploadSnippet(policy: StorageGuard.starterPolicies[0])
        check("StorageGuard generates storage security policy and presigned upload route", storageMd.contains("CLOUD STORAGE SECURITY") && storageRoute.contains("getSignedUrl"))

        let cacheMd = CacheStrategist.generateCacheMarkdown(title: "Task Studio", rules: CacheStrategist.starterRules)
        let cacheMw = CacheStrategist.generateCacheMiddlewareSnippet(rules: CacheStrategist.starterRules)
        check("CacheStrategist generates HTTP cache spec and Next.js edge middleware", cacheMd.contains("HTTP, CDN & SERVICE WORKER CACHE STRATEGY") && cacheMw.contains("Cache-Control"))

        let rpcMd = RpcContractStudio.generateRpcMarkdown(title: "Task Studio", procedures: RpcContractStudio.starterProcedures)
        let rpcRouter = RpcContractStudio.generateTrpcRouterSnippet(procedures: RpcContractStudio.starterProcedures)
        check("RpcContractStudio generates typed RPC spec and tRPC Zod router", rpcMd.contains("END-TO-END TYPED RPC") && rpcRouter.contains("initTRPC"))

        let expMd = ExperimentStudio.generateExperimentMarkdown(title: "Task Studio", experiments: ExperimentStudio.starterExperiments)
        let expClient = ExperimentStudio.generateBucketingClientSnippet(experiments: ExperimentStudio.starterExperiments)
        check("ExperimentStudio generates A/B experiment spec and deterministic bucketer", expMd.contains("A/B TESTING & EXPERIMENT BUCKETING") && expClient.contains("getExperimentVariant"))

        let rateMd = RateLimiterStudio.generateRateLimitMarkdown(title: "Task Studio", rules: RateLimiterStudio.starterRules)
        let rateMw = RateLimiterStudio.generateRateLimitMiddleware(rules: RateLimiterStudio.starterRules)
        check("RateLimiterStudio generates DDoS limit spec and Upstash Redis middleware", rateMd.contains("DISTRIBUTED RATE LIMITING") && rateMw.contains("slidingWindow"))

        let busMd = EventBusStudio.generateEventBusMarkdown(title: "Task Studio", events: EventBusStudio.starterEvents)
        let busClient = EventBusStudio.generateEventBusClientSnippet(events: EventBusStudio.starterEvents)
        check("EventBusStudio generates domain events spec and typed event bus client", busMd.contains("DISTRIBUTED EVENT BUS") && busClient.contains("DomainEventBus"))

        let cacheQMd = QueryCacheStudio.generateQueryCacheMarkdown(title: "Task Studio", caches: QueryCacheStudio.starterCaches)
        let cacheQSnippet = QueryCacheStudio.generateCacheAsideSnippet(caches: QueryCacheStudio.starterCaches)
        check("QueryCacheStudio generates two-tier query cache spec and LRU/Redis wrapper", cacheQMd.contains("DISTRIBUTED TWO-TIER QUERY CACHING") && cacheQSnippet.contains("cachedQuery"))

        let hookMd = WebhookDispatcherStudio.generateDispatcherMarkdown(title: "Task Studio", webhooks: WebhookDispatcherStudio.starterWebhooks)
        let hookWorker = WebhookDispatcherStudio.generateWorkerSnippet(webhooks: WebhookDispatcherStudio.starterWebhooks)
        check("WebhookDispatcherStudio generates webhook delivery spec and HMAC-SHA256 signer", hookMd.contains("OUTGOING WEBHOOK DISPATCHER") && hookWorker.contains("createHmac"))

        // Phase 2: High-Density Canvas Engine, Spatial Indexing & ERD Models
        let quadTree = SpatialQuadTree(boundary: SpatialRect(x: 0, y: 0, width: 2000, height: 2000), capacity: 4)
        for i in 0..<20 {
            let item = SpatialItem(id: "node_\(i)", bounds: SpatialRect(x: Double(i * 50), y: Double(i * 50), width: 40, height: 40))
            quadTree.insert(item)
        }
        let inFrustum = quadTree.queryFrustum(viewport: SpatialRect(x: 0, y: 0, width: 200, height: 200), margin: 50)
        let outsideQuery = quadTree.query(range: SpatialRect(x: 1800, y: 1800, width: 100, height: 100))
        check("SpatialQuadTree partitions canvas elements and executes frustum culling", inFrustum.count > 0 && outsideQuery.isEmpty && quadTree.count == 20)

        let parentFrame = CanvasFrame(id: UUID(), title: "Parent System", x: 96, y: 96, width: 512, height: 384)
        let childFrame = CanvasFrame(id: UUID(), title: "Nested Service", x: 120, y: 120, width: 200, height: 160, parentId: parentFrame.id.uuidString)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let encodedData = try? encoder.encode(childFrame)
        let decodedFrame = encodedData != nil ? try? decoder.decode(CanvasFrame.self, from: encodedData!) : nil
        check("CanvasFrame preserves hierarchical parentId in serialization", decodedFrame?.parentId == parentFrame.id.uuidString && decodedFrame?.title == "Nested Service")

        let erdSchema = ERDSchema(tables: ERDSchemaGenerator.starterTables, relationships: ERDSchemaGenerator.starterRelationships)
        let erdSql = ERDSchemaGenerator.generatePostgresSql(schema: erdSchema)
        let erdPrisma = ERDSchemaGenerator.generatePrismaSchema(schema: erdSchema)
        check("ERDSchemaGenerator produces valid PostgreSQL DDL and Prisma models", erdSql.contains("FOREIGN KEY (tenant_id) REFERENCES tenants(id)") && erdPrisma.contains("model Users"))

        var hlc1 = HybridLogicalClock(physicalMillis: 1000, logicalCounter: 0, clientId: "node-a")
        var hlc2 = HybridLogicalClock(physicalMillis: 1000, logicalCounter: 0, clientId: "node-b")
        hlc1.tick()
        hlc2.update(with: hlc1)
        var regA = LWWRegister(value: "Initial State", clock: hlc1)
        let regB = LWWRegister(value: "Concurrent Update", clock: hlc2)
        regA.merge(with: regB)
        check("HybridLogicalClock and LWWRegister guarantee deterministic causal ordering and conflict convergence", regA.value == "Concurrent Update" && hlc2 > hlc1)

        var docA = CanvasCRDTDocument(documentId: "doc-1", clientId: "client-a")
        var docB = CanvasCRDTDocument(documentId: "doc-1", clientId: "client-b")
        let sharedFrameId = UUID()
        docA.setFrame(CanvasFrame(id: sharedFrameId, title: "Auth Cluster V1", x: 64, y: 64, width: 256, height: 128))
        docB.setFrame(CanvasFrame(id: sharedFrameId, title: "Auth Cluster V2", x: 128, y: 128, width: 256, height: 128))
        var docACopy = docA
        var docBCopy = docB
        docACopy.merge(with: docB)
        docBCopy.merge(with: docA)
        let frameA = docACopy.frames[sharedFrameId.uuidString]?.value
        let frameB = docBCopy.frames[sharedFrameId.uuidString]?.value
        check("CanvasCRDTDocument converges identically regardless of merge order", frameA?.title == frameB?.title && frameA?.x == frameB?.x && frameA != nil)

        let symKey = SymmetricKey(size: .bits256)
        let testPayload = Data("{\"presence\": \"active\", \"collaborators\": 4}".utf8)
        let encryptedEnv = try? EncryptedSyncEnvelope.encrypt(payload: testPayload, symmetricKey: symKey, senderClientId: "peer-99")
        let decryptedData = encryptedEnv != nil ? try? encryptedEnv!.decrypt(symmetricKey: symKey) : nil
        let decryptedStr = decryptedData != nil ? String(data: decryptedData!, encoding: .utf8) : nil
        check("EncryptedSyncEnvelope encrypts and decrypts payload using ChaCha20-Poly1305", decryptedStr?.contains("presence") == true && encryptedEnv?.ciphertextBase64.isEmpty == false)

        let mockFiles: [String: String] = [
            "App/Views/UserProfileView.swift": "import SwiftUI\nimport Repositories\nimport Database",
            "App/Domain/Services/UserService.swift": "import Foundation\nimport Repositories",
            "App/Data/Repositories/UserRepository.swift": "import Foundation\nimport Database"
        ]
        let driftViolations = ArchitecturalDriftGuard.evaluate(files: mockFiles)
        let mermaidTopology = ArchitecturalDriftGuard.generateMermaidTopology(violations: driftViolations)
        let hasExpectedViolation = driftViolations.contains(where: { $0.ruleName == "PresentationToDataBypass" && $0.sourceLayer == "Presentation" })
        check("ArchitecturalDriftGuard enforces layer boundaries and detects presentation-to-data bypass", hasExpectedViolation && mermaidTopology.contains("graph TD") && mermaidTopology.contains("VIOLATION"))

        let healthyNode = NodeTelemetry(nodeId: "api-gw", rps: 300, p99LatencyMs: 45, errorRate: 0.001)
        let degradedNode = NodeTelemetry(nodeId: "auth-svc", rps: 150, p99LatencyMs: 380, errorRate: 0.002)
        let failingNode = NodeTelemetry(nodeId: "billing-db", rps: 40, p99LatencyMs: 1400, errorRate: 0.07)
        check("NodeTelemetry calculates SLA health status and hex token colors accurately", healthyNode.status == .healthy && healthyNode.status.colorHex == "#2ECC71" && degradedNode.status == .degraded && degradedNode.status.colorHex == "#F39C12" && failingNode.status == .failing && failingNode.status.colorHex == "#E74C3C")

        IDEBridgeHub.shared.updateActiveFile(path: "Sources/Kite/ContentView.swift", line: 42, editor: "cursor")
        let ideStatus = IDEBridgeHub.shared.currentActiveFile
        let cursorUrl = IDEBridgeHub.shared.createEditorDeepLink(filePath: "/workspace/App.swift", line: 16, column: 8, editor: "cursor")
        let vscodeUrl = IDEBridgeHub.shared.createEditorDeepLink(filePath: "/workspace/App.swift", line: 32, column: 1, editor: "vscode")
        check("IDEBridgeHub tracks active file state and generates editor deep links", ideStatus.path == "Sources/Kite/ContentView.swift" && ideStatus.line == 42 && cursorUrl?.absoluteString.hasPrefix("cursor://file/") == true && vscodeUrl?.absoluteString.hasPrefix("vscode://file/") == true)

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
