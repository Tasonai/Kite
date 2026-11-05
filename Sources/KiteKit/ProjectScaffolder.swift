import Foundation

public struct IdeaExportModel: Codable {
    public var version: Int
    public var exportedAt: String
    public var ideas: [IdeaDTO]
    
    public init(ideas: [IdeaDTO]) {
        self.version = 1
        self.exportedAt = ISO8601DateFormatter().string(from: Date())
        self.ideas = ideas
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = (try? container.decode(Int.self, forKey: .version)) ?? 1
        self.exportedAt = (try? container.decode(String.self, forKey: .exportedAt)) ?? ISO8601DateFormatter().string(from: Date())
        self.ideas = (try? container.decode([IdeaDTO].self, forKey: .ideas)) ?? []
    }
}

public struct IdeaDTO: Codable, Identifiable {
    public var id: String
    public var title: String
    public var description: String
    public var platform: String
    public var preferredStyle: String
    public var status: String
    public var tags: [String]
    public var isStarred: Bool
    public var createdAt: String
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        platform: String = "web",
        preferredStyle: String = "Editorial & Swiss Modern",
        status: String = "backlog",
        tags: [String] = [],
        isStarred: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.platform = platform
        self.preferredStyle = preferredStyle
        self.status = status
        self.tags = tags
        self.isStarred = isStarred
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.title = (try? container.decode(String.self, forKey: .title)) ?? "Без названия"
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""
        self.platform = (try? container.decode(String.self, forKey: .platform)) ?? "web"
        self.preferredStyle = (try? container.decode(String.self, forKey: .preferredStyle)) ?? "Editorial & Swiss Modern"
        self.status = (try? container.decode(String.self, forKey: .status)) ?? "backlog"
        self.tags = (try? container.decode([String].self, forKey: .tags)) ?? []
        self.isStarred = (try? container.decode(Bool.self, forKey: .isStarred)) ?? false
        self.createdAt = (try? container.decode(String.self, forKey: .createdAt)) ?? ISO8601DateFormatter().string(from: Date())
    }
}

public enum ProjectScaffolder {
    public struct Result {
        public let directory: URL
        public let files: [String]
        public let gitMessage: String

        public init(directory: URL, files: [String], gitMessage: String = "") {
            self.directory = directory
            self.files = files
            self.gitMessage = gitMessage
        }
    }
    
    public static func slugify(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics
        var slug = text.lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        if slug.isEmpty { slug = "kite-project" }
        return slug
    }
    
    public static func scaffold(
        at parentFolder: URL,
        title: String,
        concept: String,
        platform: String,
        style: String,
        planPrompt: String,
        createGitBranch: Bool = false
    ) throws -> Result {
        let folderName = slugify(title)
        let projectDir = parentFolder.appendingPathComponent(folderName, isDirectory: true)
        
        let fm = FileManager.default
        try fm.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        var createdFiles: [String] = []
        
        // 1. README.md
        let readme = """
        # \(title)
        
        > **Platform:** \(platform)  
        > **Visual System:** \(style)  
        > **Scaffolded by:** [Kite for macOS](https://github.com/chase/kite)  
        
        ## Концепция
        \(concept.isEmpty ? "Описание концепции и сценария использования." : concept)
        
        ## Быстрый старт
        Ознакомьтесь с [SPEC.md](./SPEC.md) и [PLAN.md](./PLAN.md) для реализации через Antigravity / Cursor.
        
        ## Чек-лист разработки
        - [ ] Первичная инициализация компонентов
        - [ ] Локальное хранилище данных
        - [ ] Реализация основного пользовательского сценария
        - [ ] Аудит дизайна и доступности
        """
        try readme.write(to: projectDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        createdFiles.append("README.md")
        
        // 2. SPEC.md & PRD.md
        let spec = """
        # Product Requirements Document (PRD): \(title)
        
        ## 1. Problem & JTBD
        - **Target:** \(platform)
        - **Style Aesthetic:** \(style)
        - **Core Value:** Решение ключевой задачи пользователя с наивысшей скоростью отклика и нулевым визуальным шумом.
        
        ## 2. Functional Requirements
        - Быстродействие и отсутствие сетевых блокировок UI.
        - Локальное сохранение состояния.
        - Поддержка клавиатурных шорткатов.
        
        ## 3. Architecture & Tech Stack
        - **UI/Layout:** Модульная сетка 4pt/8pt, типографика в духе \(style).
        - **State:** Однонаправленный поток данных.
        """
        try spec.write(to: projectDir.appendingPathComponent("SPEC.md"), atomically: true, encoding: .utf8)
        try spec.write(to: projectDir.appendingPathComponent("PRD.md"), atomically: true, encoding: .utf8)
        createdFiles.append("SPEC.md")
        createdFiles.append("PRD.md")
        
        // 3. PLAN.md
        let plan = planPrompt.isEmpty ? PromptCompiler.compileBlueprint(
            title: title,
            concept: concept,
            platform: platform,
            style: style
        ) : planPrompt
        try plan.write(to: projectDir.appendingPathComponent("PLAN.md"), atomically: true, encoding: .utf8)
        createdFiles.append("PLAN.md")
        
        // 4. DESIGN.md
        let tokens = DesignSystemTokens.resolve(for: style)
        let designMd = """
        # Design System Specification — DESIGN.md
        > **Project:** \(title)
        > **Aesthetic:** \(style) (\(tokens.theme))
        
        ## Color Tokens
        - **Background:** \(tokens.background)
        - **Surface:** \(tokens.surface)
        - **Primary Accent:** \(tokens.accent) (\(tokens.accentRole))
        - **Text Primary:** \(tokens.textPrimary)
        - **Text Secondary:** \(tokens.textSecondary)
        
        ## Components & Elevation
        - **Buttons:** \(tokens.buttons)
        - **Cards & Panels:** \(tokens.cards)
        - **Typography:** \(tokens.typography)
        - **Layout Grid:** Strict 4pt/8pt modular grid (touch targets >= 44px).
        """
        try designMd.write(to: projectDir.appendingPathComponent("DESIGN.md"), atomically: true, encoding: .utf8)
        createdFiles.append("DESIGN.md")

        // 5. .planning/ directory for Antigravity GSD agents
        let planningDir = projectDir.appendingPathComponent(".planning", isDirectory: true)
        let phasesDir = planningDir.appendingPathComponent("phases/01-foundation", isDirectory: true)
        try fm.createDirectory(at: phasesDir, withIntermediateDirectories: true)

        let projectMd = """
        # Project Charter: \(title)

        ## Vision & JTBD
        \(concept.isEmpty ? "Реализация высокопроизводительного нативного решения." : concept)

        ## Platform & Visual System
        - **Platform:** \(platform)
        - **Design System:** \(style) (\(tokens.theme))
        - **Grid Standard:** 4pt/8pt modular grid, sub-250ms feedback, zero emojis

        ## Required Antigravity Skills
        - `/site-md` — Architecture mapping and screen catalog
        - `/design-md` — Visual system and DESIGN.md token sync
        - `/emil-design-eng` — Micro-interactions and spring physics
        - `/gsd-execute-phase` — Wave-based execution with atomic commits
        """
        try projectMd.write(to: planningDir.appendingPathComponent("PROJECT.md"), atomically: true, encoding: .utf8)
        createdFiles.append(".planning/PROJECT.md")

        let roadmapMd = """
        # Roadmap: \(title)

        ## Milestone 1: MVP Core
        - [ ] Phase 1: Foundation & Data Schema
        - [ ] Phase 2: Core Domain Logic & State Management
        - [ ] Phase 3: High-Fidelity UI & Token Alignment
        - [ ] Phase 4: Verification, A11y & Packaging
        """
        try roadmapMd.write(to: planningDir.appendingPathComponent("ROADMAP.md"), atomically: true, encoding: .utf8)
        createdFiles.append(".planning/ROADMAP.md")

        let stateMd = """
        # Project State: \(title)

        - **Current Milestone:** 1.0.0
        - **Current Phase:** Phase 1 (Foundation & Data Schema)
        - **Status:** Initialized and ready for agent execution
        """
        try stateMd.write(to: planningDir.appendingPathComponent("STATE.md"), atomically: true, encoding: .utf8)
        createdFiles.append(".planning/STATE.md")

        let phase1Plan = """
        # Phase 1 Plan: Foundation & Data Schema

        ## Goal
        Establish data models, storage layer, and baseline project structure.

        ## Tasks
        1. Initialize repository and configuration.
        2. Setup data models and schema validation.
        3. Verify local read/write persistence.
        """
        try phase1Plan.write(to: phasesDir.appendingPathComponent("PLAN.md"), atomically: true, encoding: .utf8)
        createdFiles.append(".planning/phases/01-foundation/PLAN.md")

        // 6. CLAUDE.md (Agent Guidelines)
        let claudeMd = """
        # Engineering Constitution for \(title)
        
        ## Core Rules
        - **Zero AI Slop:** No generic template filler, no unstyled placeholders, no emojis.
        - **Craftsmanship:** Strict 4pt/8pt modular grid. Every touch target >= 44px.
        - **Architecture:** Local-first, sub-250ms spring transitions, offline resilience.
        
        ## Antigravity Skills
        Execute work with slash syntax:
        - `/site-md` — Architecture mapping and project constitution
        - `/design-md` — Visual system and design token sync
        - `/taste-design` — Typography curation and visual hierarchy
        - `/impeccable` — Interface polish and high-density details
        - `/emil-design-eng` — Physical spring micro-interactions
        - `/a11y-debugging` — WCAG AA compliance and keyboard accessibility
        - `/gsd-execute-phase` — Wave-based execution with atomic commits
        """
        try claudeMd.write(to: projectDir.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)
        createdFiles.append("CLAUDE.md")

        // 6. Platform Scaffold
        let effectiveFolderName = folderName.isEmpty ? "App" : folderName
        if platform.lowercased() == "web" {
            let pkgJson = """
            {
              "name": "\(effectiveFolderName.lowercased())",
              "private": true,
              "version": "1.0.0",
              "type": "module",
              "scripts": {
                "dev": "vite",
                "build": "tsc -b && vite build",
                "preview": "vite preview"
              },
              "dependencies": {
                "react": "^19.0.0",
                "react-dom": "^19.0.0",
                "lucide-react": "^1.16.0"
              },
              "devDependencies": {
                "@vitejs/plugin-react": "^4.3.4",
                "typescript": "^5.7.2",
                "vite": "^6.2.0"
              }
            }
            """
            try pkgJson.write(to: projectDir.appendingPathComponent("package.json"), atomically: true, encoding: .utf8)
            createdFiles.append("package.json")
        } else if platform.lowercased() == "desktop" {
            let safeTargetName = effectiveFolderName.replacingOccurrences(of: "-", with: "_")
            let swiftPkg = """
            // swift-tools-version: 6.0
            import PackageDescription

            let package = Package(
                name: "\(safeTargetName)",
                platforms: [.macOS(.v14)],
                products: [
                    .executable(name: "\(safeTargetName)", targets: ["\(safeTargetName)"])
                ],
                targets: [
                    .executableTarget(
                        name: "\(safeTargetName)",
                        path: "Sources"
                    )
                ]
            )
            """
            try swiftPkg.write(to: projectDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
            createdFiles.append("Package.swift")
            
            let srcDir = projectDir.appendingPathComponent("Sources")
            try? FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
            let mainSwift = """
            import SwiftUI

            @main
            struct \(safeTargetName)App: App {
                var body: some Scene {
                    WindowGroup {
                        ContentView()
                    }
                }
            }

            struct ContentView: View {
                var body: some View {
                    VStack(spacing: 16) {
                        Text("\(swiftLiteral(title))")
                            .font(.title)
                        Text("\(swiftLiteral(concept.isEmpty ? title : concept))")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .frame(minWidth: 600, minHeight: 400)
                }
            }
            """
            try mainSwift.write(to: srcDir.appendingPathComponent("App.swift"), atomically: true, encoding: .utf8)
            createdFiles.append("Sources/App.swift")
        }

        // 7. .gitignore
        let gitignore = """
        .DS_Store
        node_modules/
        .build/
        dist/
        *.log
        .env.local
        """
        try gitignore.write(to: projectDir.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)
        createdFiles.append(".gitignore")
        
        // 8. Initialize git repository, feature branch, and commit
        var gitMsg = ""
        if createGitBranch {
            let res = initializeGitFeature(at: projectDir, branchName: "feature/kite-\(folderName)", commitMessage: "feat: scaffold planning specs for \(title)")
            gitMsg = res.message
        } else {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.currentDirectoryURL = projectDir
            process.arguments = ["init"]
            try? process.run()
            process.waitUntilExit()
        }
        
        return Result(directory: projectDir, files: createdFiles, gitMessage: gitMsg)
    }

    @discardableResult
    public static func initializeGitFeature(
        at projectDir: URL,
        branchName: String? = nil,
        commitMessage: String? = nil
    ) -> (success: Bool, message: String) {
        let folderName = projectDir.lastPathComponent
        let branch = branchName ?? "feature/kite-\(folderName)"
        let commitMsg = commitMessage ?? "feat: scaffold planning specs for \(folderName)"

        func runGit(_ args: [String]) -> (code: Int32, out: String) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            proc.currentDirectoryURL = projectDir
            proc.arguments = args
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return (proc.terminationStatus, String(data: data, encoding: .utf8) ?? "")
            } catch {
                return (-1, error.localizedDescription)
            }
        }

        _ = runGit(["init"])
        _ = runGit(["checkout", "-B", branch])
        _ = runGit(["add", "."])
        _ = runGit(["commit", "-m", commitMsg])
        return (true, "Git branch '\(branch)' ready with initial planning specs")
    }

    /// Escapes text so it can sit inside a generated Swift string literal.
    private static func swiftLiteral(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
