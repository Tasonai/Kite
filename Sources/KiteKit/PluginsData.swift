import Foundation

public struct AntigravityPluginInfo: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let author: String
    public let version: String
    public let summary: String
    public let skillsCount: Int
    public let skills: [String]
    public let mcpServer: String?
    public let cliCommand: String?
    public let icon: String

    public init(
        id: String,
        name: String,
        category: String,
        author: String,
        version: String,
        summary: String,
        skillsCount: Int,
        skills: [String],
        mcpServer: String? = nil,
        cliCommand: String? = nil,
        icon: String = "🧩"
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.author = author
        self.version = version
        self.summary = summary
        self.skillsCount = skillsCount
        self.skills = skills
        self.mcpServer = mcpServer
        self.cliCommand = cliCommand
        self.icon = icon
    }
}

public enum PluginsRepository {
    public static let installed: [AntigravityPluginInfo] = [
        AntigravityPluginInfo(
            id: "bama",
            name: "Build Any Mac App (BAMA)",
            category: "Apple & macOS",
            author: "bama",
            version: "1.2.0",
            summary: "Комплексный плагин для проектирования, архитектуры, UI/UX и сборки нативных macOS приложений на SwiftUI, SwiftData и AppKit.",
            skillsCount: 5,
            skills: ["bama", "mac-design", "new-mac-app", "swift-swiftui", "test-mac-app"],
            mcpServer: nil,
            cliCommand: "bama",
            icon: ""
        ),
        AntigravityPluginInfo(
            id: "bawa",
            name: "Build Any Windows App (BAWA)",
            category: "Windows & WinUI",
            author: "bawa",
            version: "1.0.0",
            summary: "Разработка современных нативных приложений под Windows с использованием C#, WinUI 3, Windows App SDK и fluent-дизайна.",
            skillsCount: 22,
            skills: ["agent-cli", "app-brief", "app-icon", "bawa", "build-and-verify", "clone", "csharp-winui", "design-from-app", "design-kit", "design-system", "distribute", "improve-architecture", "improve-loop", "layout-grid", "new-windows-app", "os-integrations", "performance", "research", "test-windows-app", "user-stories", "ux-design", "windows-design"],
            mcpServer: nil,
            cliCommand: "bawa",
            icon: "🪟"
        ),
        AntigravityPluginInfo(
            id: "canva",
            name: "Canva Design & Export MCP",
            category: "Дизайн-платформы",
            author: "Canva",
            version: "2.1.0",
            summary: "Интеграция с платформой Canva через MCP: создание макетов, ресайз для соцсетей, бренд-киты, генерация баннеров и экспорт в PDF/PNG.",
            skillsCount: 11,
            skills: ["canva-brand-check", "canva-branded-presentation", "canva-bulk-create", "canva-classroom-helper", "canva-cli", "canva-design-feedback", "canva-edit-design", "canva-implement-feedback", "canva-presentation-time-fitting", "canva-resize-for-social-media", "canva-translate-design"],
            mcpServer: "canva_canva",
            cliCommand: nil,
            icon: "🎨"
        ),
        AntigravityPluginInfo(
            id: "chrome-devtools-plugin",
            name: "Chrome DevTools & a11y",
            category: "Тестирование и DevTools",
            author: "Google Chrome DevTools",
            version: "1.4.0",
            summary: "Профессиональный профилировщик Chrome через MCP: замеры Core Web Vitals (LCP, CLS, INP), аудит доступности WCAG, поиск утечек памяти и анализ куки.",
            skillsCount: 6,
            skills: ["a11y-debugging", "chrome-devtools", "cookie-debugging", "debug-optimize-lcp", "memory-leak-debugging", "troubleshooting"],
            mcpServer: "chrome-devtools",
            cliCommand: nil,
            icon: "🌐"
        ),
        AntigravityPluginInfo(
            id: "coderabbit",
            name: "CodeRabbit AI Review & Autofix",
            category: "Код-ревью и аудит",
            author: "CodeRabbit",
            version: "0.9.5",
            summary: "Глубокий анализ исходного кода, аудит безопасности пул-реквестов, классификация замечаний и автоматическое применение исправлений (autofix).",
            skillsCount: 2,
            skills: ["autofix", "code-review"],
            mcpServer: nil,
            cliCommand: "coderabbit",
            icon: "🐇"
        ),
        AntigravityPluginInfo(
            id: "figma",
            name: "Figma Design to Code & Connect",
            category: "Дизайн-системы",
            author: "Figma",
            version: "3.0.0",
            summary: "Двусторонняя интеграция с Figma: конвертация фреймов в чистый код (React, SwiftUI), Code Connect, генерация диаграмм FigJam и шейдеры.",
            skillsCount: 18,
            skills: ["figma-code-connect", "figma-code-workflows", "figma-create-new-file", "figma-design-to-code", "figma-generate-design", "figma-generate-diagram", "figma-generate-library", "figma-generative-plugins", "figma-implement-motion", "figma-shaders", "figma-spec", "figma-swiftui", "figma-use", "figma-use-figjam", "figma-use-motion", "figma-use-slides", "generate-project-plan", "video-interaction-mapper"],
            mcpServer: "figma_figma",
            cliCommand: nil,
            icon: "📐"
        ),
        AntigravityPluginInfo(
            id: "firebase",
            name: "Google Firebase Full-Stack",
            category: "Бэкенд и облачные сервисы",
            author: "Google Firebase",
            version: "2.2.0",
            summary: "Облачный бэкенд Google Firebase: Firebase Auth, Firestore Security Rules, Gemini AI Logic, App Hosting, Remote Config и Crashlytics.",
            skillsCount: 13,
            skills: ["extension-to-functions-codebase", "firebase-ai-logic-basics", "firebase-app-hosting-basics", "firebase-auth-basics", "firebase-basics", "firebase-crashlytics", "firebase-data-connect", "firebase-firestore", "firebase-hosting-basics", "firebase-remote-config-basics", "firebase-security-rules-auditor", "firestore-rules-creation", "xcode-project-setup"],
            mcpServer: nil,
            cliCommand: "firebase",
            icon: "🔥"
        ),
        AntigravityPluginInfo(
            id: "flutter",
            name: "Flutter & Dart Mobile SDK",
            category: "Мобильная разработка",
            author: "Google Flutter Team",
            version: "3.24.0",
            summary: "Инструменты разработки кроссплатформенных приложений на Flutter и Dart: адаптивная верстка, превью виджетов, линтинг dart analyze и юнит-тесты.",
            skillsCount: 25,
            skills: ["dart-add-unit-test", "dart-build-cli-app", "dart-collect-coverage", "dart-fix-runtime-errors", "dart-generate-test-mocks", "dart-migrate-to-checks-package", "dart-resolve-package-conflicts", "dart-run-static-analysis", "dart-setup-ffi-assets", "dart-use-doc-examples", "dart-use-ffigen", "dart-use-path-package", "dart-use-pattern-matching", "dart-use-primary-constructors", "dart-write-documentation", "flutter-add-integration-test", "flutter-add-widget-preview", "flutter-add-widget-test", "flutter-apply-architecture-best-practices", "flutter-build-responsive-layout", "flutter-fix-layout-issues", "flutter-implement-json-serialization", "flutter-setup-declarative-routing", "flutter-setup-localization", "flutter-use-http-package"],
            mcpServer: nil,
            cliCommand: "flutter / dart",
            icon: "💙"
        ),
        AntigravityPluginInfo(
            id: "gemini-api",
            name: "Google Gemini API & Docs",
            category: "Искусственный интеллект",
            author: "Google Gemini Team",
            version: "1.5.0",
            summary: "Официальная интеграция с семейством моделей Google Gemini 2.5 Flash, Pro и Live Audio API через документацию и SDK.",
            skillsCount: 3,
            skills: ["gemini-api-dev", "gemini-live-api-dev", "gemini-omni-flash-api"],
            mcpServer: "gemini-api_gemini-api-docs",
            cliCommand: nil,
            icon: "✨"
        ),
        AntigravityPluginInfo(
            id: "google_maps_platform",
            name: "Google Maps Platform",
            category: "Геолокация и карты",
            author: "Google Maps Team",
            version: "1.0.0",
            summary: "Интеграция карт, интерактивных маркеров, геокодирования, поиска мест (Places API) и расчета маршрутов Google Maps Platform.",
            skillsCount: 1,
            skills: ["google-maps-platform"],
            mcpServer: nil,
            cliCommand: nil,
            icon: "🗺️"
        ),
        AntigravityPluginInfo(
            id: "mobbin",
            name: "Mobbin UI/UX Real-World References",
            category: "Дизайн-референсы",
            author: "Mobbin",
            version: "2.0.0",
            summary: "Интеллектуальный поиск по каталогу 600,000+ скриншотов и пользовательских сценариев реальных топовых мобильных и веб-продуктов.",
            skillsCount: 4,
            skills: ["best-practices", "plain-writing", "redesign-screen", "search"],
            mcpServer: "mobbin_mobbin",
            cliCommand: nil,
            icon: "📱"
        ),
        AntigravityPluginInfo(
            id: "modern-web-guidance-plugin",
            name: "Modern Web Guidance",
            category: "Веб-стандарты",
            author: "Antigravity Core",
            version: "1.1.0",
            summary: "Сборник актуальных гайдлайнов и паттернов современной веб-разработки (PWA, Web Animations, Chrome Extensions Manifest V3).",
            skillsCount: 2,
            skills: ["chrome-extensions", "modern-web-guidance"],
            mcpServer: nil,
            cliCommand: nil,
            icon: "⚡️"
        ),
        AntigravityPluginInfo(
            id: "stitch-build",
            name: "Google Stitch Code Generation",
            category: "Инструменты Stitch AI",
            author: "Google Stitch Team",
            version: "1.0.0",
            summary: "Генерация чистого TypeScript/React кода, дашбордов TanStack Query, React Native версий и Remotion walkthrough-видео из Stitch-макетов.",
            skillsCount: 5,
            skills: ["react-vite-dashboard", "remotion", "shadcn-ui", "stitch::react-components", "stitch::react-native"],
            mcpServer: "stitch",
            cliCommand: nil,
            icon: "🧵"
        ),
        AntigravityPluginInfo(
            id: "stitch-design",
            name: "Google Stitch Design System",
            category: "Инструменты Stitch AI",
            author: "Google Stitch Team",
            version: "1.0.0",
            summary: "Управление дизайн-системами в Stitch: конвертация существующего кода в макеты, извлечение static HTML и синхронизация экранов.",
            skillsCount: 6,
            skills: ["stitch::code-to-design", "stitch::extract-design-md", "stitch::extract-static-html", "stitch::generate-design", "stitch::manage-design-system", "stitch::upload-to-stitch"],
            mcpServer: "stitch",
            cliCommand: nil,
            icon: "🧶"
        ),
        AntigravityPluginInfo(
            id: "stitch-utilities",
            name: "Google Stitch Utilities & Prompts",
            category: "Инструменты Stitch AI",
            author: "Google Stitch Team",
            version: "1.0.0",
            summary: "Утилиты для авторов Stitch: улучшение UI-промптов, синтез конституции сайта SITE.md и автономный цикл генерации сайтов (Stitch Loop).",
            skillsCount: 5,
            skills: ["design-md", "enhance-prompt", "site-md", "stitch-loop", "taste-design"],
            mcpServer: "stitch",
            cliCommand: nil,
            icon: "🪡"
        ),
        AntigravityPluginInfo(
            id: "supabase",
            name: "Supabase PostgreSQL & Edge MCP",
            category: "Бэкенд и базы данных",
            author: "Supabase",
            version: "2.0.0",
            summary: "Полное управление Supabase из среды Antigravity: SQL-запросы, RLS политики безопасности, миграции, генерация TypeScript-типов и Edge Functions.",
            skillsCount: 2,
            skills: ["supabase", "supabase-postgres-best-practices"],
            mcpServer: "supabase_mcp",
            cliCommand: nil,
            icon: "⚡️"
        ),
        AntigravityPluginInfo(
            id: "superpowers",
            name: "Superpowers Engineering System",
            category: "Инженерные суперсилы",
            author: "Antigravity Superpowers",
            version: "2.0.0",
            summary: "Дисциплинированная методология разработки: дивергентный брейншторминг, Test-Driven Development (TDD), систематический дебаггинг и параллельные субагенты.",
            skillsCount: 15,
            skills: ["brainstorming", "diagnosing-superpowers", "dispatching-parallel-agents", "executing-plans", "finishing-a-development-branch", "receiving-code-review", "requesting-code-review", "subagent-driven-development", "systematic-debugging", "test-driven-development", "using-git-worktrees", "using-superpowers", "verification-before-completion", "writing-plans", "writing-skills"],
            mcpServer: nil,
            cliCommand: nil,
            icon: "🦸‍♂️"
        ),
        AntigravityPluginInfo(
            id: "vercel-plugin",
            name: "Vercel Deployment & AI Cloud",
            category: "Vercel, Cloud & Edge",
            author: "Vercel",
            version: "3.2.0",
            summary: "Полный облачный стек Vercel: Vercel AI SDK, развертывание проектов, превью-URL, KV/Blob хранилище, Edge Middleware, Runtime Cache и MicroVM Sandbox.",
            skillsCount: 38,
            skills: ["access-protected-vercel-deployment", "ai-gateway", "ai-sdk", "auth", "bootstrap", "build-agents", "cdn-caching", "chat-sdk", "create-a-backend", "custom-metrics", "daemons", "deployments-cicd", "domains", "env-vars", "eve", "flags-sdk", "is-agentic", "knowledge-update", "marketplace", "microfrontends", "offload-to-sandbox", "queues", "react-best-practices", "routing-middleware", "runtime-cache", "vercel-agent", "vercel-cli", "vercel-connect", "vercel-firewall", "vercel-flags", "vercel-functions", "vercel-react-best-practices", "vercel-sandbox", "vercel-services", "vercel-storage", "vercel-tracing", "verification", "workflow"],
            mcpServer: nil,
            cliCommand: "vercel",
            icon: "▲"
        ),
    ]
}
