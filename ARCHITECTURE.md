# Architecture Documentation

Kite is a native macOS application built with SwiftUI, SwiftData, and KiteKit.

## Canvas Subsystem Architecture

The Infinite Canvas subsystem is organized into modular, single-responsibility components:

```
Sources/Kite/
├── InfiniteCanvasView.swift      Viewport state, gestures, coordinate mapping, and lifecycle
├── CanvasToolbarView.swift       Floating HUD, tool selection, action menus, zoom, and banners
├── CanvasConnectionView.swift    Curved Bezier connectors, arrowheads, protocol badges, and traffic simulation
├── CanvasNodeViews.swift         Node renderers (Frames, References, Stickies, Ideas)
├── CanvasLANPeersPopover.swift   LAN peer discovery popover and synchronization triggers
├── CanvasExporter.swift          Multi-format exporters (SVG, PNG, PDF, HTML, Mermaid with subgraphs)
├── InteractiveMockupSheet.swift  Native interactive HTML/Tailwind web mockup preview sheet
├── AntigravityPackSheet.swift    Pre-flight cockpit sheet with 4 execution waves and ANTIGRAVITY.md
└── Canvas/
    ├── CanvasComponents.swift    Geometry primitives (ArrowHead, CanvasGridBackground)
    └── CanvasReferencePicker.swift Reference catalog sheet (Mobbin / Figma)
Sources/KiteKit/
├── AntigravityPack.swift         Antigravity wave generator, ANTIGRAVITY.md compiler, and readiness linter
├── CanvasBlueprintPacks.swift    Pre-wired architecture starter packs (Micro-SaaS, AI Agent, Offline Tool, Mobile)
└── CanvasConflictResolver.swift  Three-way lossless union merge algorithm
```

### Component Responsibilities

1. **InfiniteCanvasView**
   - Coordinates pan and zoom viewport transformation matrix.
   - Manages marquee drag selection and multi-selection bounding boxes.
   - Dispatches node drag gestures and group movement offsets.
   - Connects SwiftData `@Query private var items: [Item]` to canvas nodes.
   - Integrates conflict-free canvas synchronization via `CanvasConflictResolver`.

2. **CanvasToolbarView**
   - Floating glass HUD adhering to Apple HIG 4pt/8pt grid.
   - Tool picker (Select mode vs Pan mode).
   - Menus for AI Architecture (Auto-layout, Co-architect, Repo Ingestion, Roadmap HUD).
   - Live traffic simulation toggle (`waveform.path.ecg`).
   - Menus for node creation and multi-format exports.
   - Integrated LAN peer discovery status indicator and popover launcher.

3. **CanvasConnectionView**
   - Dynamic cubic Bezier curve rendering with auto-orienting arrowheads.
   - Inline interactive connection badge for editing relationship names.
   - Protocol selector menu (Calls, HTTP/REST, SSE Stream, gRPC, WAL Query, Depends On, Audits).
   - Real-time particle stream simulation (`TimelineView(.animation)`) with live RPS/QPS indicators.

4. **CanvasNodeViews**
   - `CanvasFrameNodeView`: Subsystem container with header drag handle and enclosed item tracking.
   - `CanvasReferenceNodeView`: Mobbin / Figma reference cards with external link preview and one-click conversion to Idea.
   - `CanvasStickyNodeView`: Quick design/architecture notes with colored tactile styling.
   - `CanvasIdeaNodeView`: SwiftData item cards with status, style tokens, and direct detail navigation.

5. **CanvasLANPeersPopover & CanvasConflictResolver**
   - Discovered local Kite instances on port 49494.
   - Three-way lossless union merge: local edits are preserved while newly created remote frames, stickies, and connections are seamlessly appended.

## Prompt Translator Subsystem

```
Sources/Kite/
├── PromptTranslatorView.swift     Form inputs, platform/style pickers, Guided Wizard, and skill tag matrix
├── TranslatorInterviewPanel.swift Socratic question card and option chips
├── TranslatorOutputView.swift     Quality readiness gauge, Anti-Pitfall card, starter prompt copy, and plan editor
├── VibeErrorDoctorSheet.swift     Terminal and compiler log diagnostic sheet with surgical Antigravity fix prompts
├── DataSchemaDesignerSheet.swift  Visual schema and entity designer with SQL, Prisma, and SwiftData generator
├── CodebaseAuditorSheet.swift     Post-flight repository cleanliness auditor and polish prompt generator
├── DesignTokenSandboxSheet.swift  Interactive live design token sandbox with spring physics
├── APIContractSheet.swift         Visual API route builder and local mock server inspector
├── StateFlowSheet.swift           Interactive state machine simulator and XState / Swift store generator
├── SitemapRouterSheet.swift       Application screen hierarchy and Next.js / SwiftUI router generator
├── GitStorytellerSheet.swift      Conventional Commits sequence and GitHub Pull Request description generator
├── SeedDataSheet.swift            Realistic database seed and mock JSON fixture generator sheet
├── SecretShieldSheet.swift        API key leak scanner, sanitizer, and .env.example generator sheet
├── DependencyGuardSheet.swift     NPM bloat auditor and lightweight native replacement catalog sheet
├── DeployBlueprintSheet.swift     Production deployment blueprints (Vercel, Cloudflare, Docker, Actions)
├── ContextOptimizerSheet.swift    Ultra-dense token spec and CONTEXT.md digest sheet
├── ComponentContractSheet.swift   UI component interface and props matrix sheet
├── AcceptanceCriteriaSheet.swift  Given/When/Then scenarios and Playwright test spec sheet
├── NegativeScopeSheet.swift       Negative boundaries and OUT_OF_SCOPE.md firewall sheet
├── WorkstreamSplitterSheet.swift  Parallel AI subagent workstream isolation and WORKSTREAMS.md sheet
├── PatchInspectorSheet.swift      Real-time diff analyzer, regression risk assessor, and fix generator sheet
├── FallbackPlannerSheet.swift     Offline resilience, degradation matrix, and FALLBACKS.md sheet
├── RunbookSheet.swift             Developer runbook, package.json scripts, and Makefile sheet
├── EvalHarnessSheet.swift         AI regression eval test bench, assertions, and prompt runner sheet
├── FeatureFlagSheet.swift         Feature flag catalog, rollout percentage, and TypeScript resolver sheet
├── TelemetrySheet.swift           Product analytics event registry and PII-free client sheet
├── PerformanceBudgetSheet.swift   Core Web Vitals budgets, bundle size limits, and next.config sheet
├── ThreatModelerSheet.swift       OWASP threat model, RLS policies, and SECURITY.md sheet
├── MigrationStrategistSheet.swift Zero-downtime expand-and-contract migrations and MIGRATIONS.md sheet
├── LocalizationSheet.swift        I18n interface strings, namespace catalogs, and LOCALIZATION.md sheet
├── WebhookSheet.swift             Webhook signature verification bench and WEBHOOKS.md sheet
├── AccessibilitySheet.swift       WCAG 2.2 AA audit, focus management, and Playwright Axe suite sheet
├── MonorepoSheet.swift            Workspace package boundaries, turbo.json, and MONOREPO.md sheet
├── SEOSheet.swift                 Next.js 15 metadata, OpenGraph cards, and SEO.md sheet
├── SkillSheet.swift               Custom Antigravity SKILL.md and MCP tool schema generator sheet
├── TokenBudgetSheet.swift         AI token, cost, and latency budget management sheet
├── RealtimeSheet.swift            SSE and WebSocket streaming with auto-reconnection sheet
├── JobQueueSheet.swift            Background jobs, Inngest queues, and cron spec sheet
├── IncidentCommanderSheet.swift   Disaster recovery runbook, healthz probes, and rollback sheet
├── VectorStoreSheet.swift         Vector embedding indexes, pgvector DDL, and RAG retrieval sheet
├── ComplianceSheet.swift          GDPR Art. 17/20 privacy compliance and data deletion sheet
├── MultiTenantSheet.swift         Multi-tenant organization isolation and RBAC roles sheet
├── StressTestSheet.swift          High-concurrency k6 load testing scenarios sheet
├── EmailSheet.swift               Transactional email template studio and React Email sheet
├── DocStudioSheet.swift           Interactive Mintlify/Fumadocs API documentation and playground sheet
├── IndexOptimizerSheet.swift      PostgreSQL composite/GIN index optimizer and concurrent DDL sheet
├── ModelRouterSheet.swift         Gemini 3.8 multi-model orchestrator and latency routing sheet
├── StorageGuardSheet.swift        Cloud storage presigned upload rules and security sheet
├── CacheStrategistSheet.swift     HTTP/CDN cache-control headers and edge caching sheet
├── RpcContractSheet.swift         Type-safe tRPC procedure builder and Zod validation sheet
└── ExperimentSheet.swift          Deterministic A/B experiment bucketing and cohort sheet
Sources/KiteKit/
├── AIPitfalls.swift               Heuristic beginner pitfall detector (auth, payments, media, DB, AI quotas)
├── ProjectScaffolder.swift        Full project generator with START_HERE.md and GSD phase architecture
├── EditorLauncher.swift           One-click launcher for Cursor, VS Code, and Terminal
├── WebMockupGenerator.swift       Self-contained interactive HTML/Tailwind web prototype generator
├── VibeErrorDoctor.swift          Error log analyzer and root-cause diagnostician
├── DataSchemaDesigner.swift       Multi-dialect data model and schema generator
├── CodebaseAuditor.swift          File-level code quality, leftover log, and emoji auditor
├── InstantPreviewServer.swift     Local Wi-Fi HTTP server, mock API router, and native vector QR code generator
├── APIContractBuilder.swift       API route definitions, TypeScript client, and OpenAPI generator
├── StateFlowSimulator.swift       State flow and transition definition model
├── SitemapRouterBuilder.swift     Route tree and screen presentation router generator
├── GitStoryteller.swift           Conventional Commits and Pull Request story compiler
├── SeedDataGenerator.swift        Realistic dummy data generator (SQL INSERT, Prisma, JSON fixtures)
├── SecretShield.swift             API token detector, process.env sanitizer, and .env template builder
├── DependencyGuard.swift          Knowledge base of bloated npm packages and native zero-bloat directives
├── DeployBlueprintGenerator.swift Multi-platform deployment config generator (Vercel, Cloudflare, Docker, CI/CD)
├── ContextOptimizer.swift         Token-compressed architecture digest compiler (CONTEXT.md)
├── ComponentContractMatrix.swift  Component interfaces, variant states, and ARIA roles
├── AcceptanceCriteriaBuilder.swift Gherkin feature scenarios and automated Playwright suites
├── NegativeScopeFirewall.swift    Strict out-of-scope constraints and anti-overengineering firewalls
├── WorkstreamSplitter.swift       Multi-agent parallel workstream decomposer and collision preventer
├── PatchInspector.swift           Code diff regression linter and surgical fix prompt synthesizer
├── FallbackPlanner.swift          Graceful degradation matrix and offline resilience directive compiler
├── RunbookBuilder.swift           Lifecycle command generator, RUNBOOK.md compiler, and Makefile builder
├── EvalHarness.swift              AI eval benchmark generator, assertion runner, and prompt directive
├── FeatureFlagMatrix.swift        Feature flag catalog, TypeScript SDK client, and rollout directive
├── TelemetrySpecifier.swift       Product analytics event catalog, PII-free client, and tracking directive
├── PerformanceBudget.swift        Core Web Vitals threshold definitions and Next.js optimization directive
├── ThreatModeler.swift            OWASP threat modeling, RLS policies, and security directive compiler
├── MigrationStrategist.swift      Safe two-phase database migration planner and Expand/Contract directive
├── LocalizationSpecifier.swift    I18n string dictionary generator and catalog specifier
├── WebhookSimulator.swift         Webhook cryptographic signature verifier and test dispatcher
├── AccessibilityAuditor.swift     WCAG 2.2 AA accessibility requirements and Playwright Axe suite builder
├── MonorepoArchitect.swift        Workspace package boundary compiler and Turborepo configuration
├── SEOStudio.swift                Next.js 15 metadata synthesizer and OpenGraph card generator
├── SkillSynthesizer.swift         Custom Antigravity SKILL.md compiler and MCP schema builder
├── TokenBudgeteer.swift           AI token, cost, and latency resource constraint compiler
├── RealtimeArchitect.swift        Streaming protocol selector and resilient SSE hook synthesizer
├── JobQueueStrategist.swift       Background worker catalog and Inngest function compiler
├── IncidentCommander.swift        Disaster recovery runbook compiler and healthz probe generator
├── VectorStoreSpecifier.swift     Vector chunking specification and pgvector DDL compiler
├── ComplianceGuardian.swift       GDPR/CCPA privacy compliance and data deletion route generator
├── MultiTenantArchitect.swift     Multi-tenant organization isolation and RBAC middleware builder
├── StressTestArchitect.swift      High-throughput stress scenario and executable k6 script compiler
├── EmailStudio.swift              Transactional email catalog and React Email template synthesizer
├── DocStudio.swift                Interactive API documentation and curl/TypeScript snippet builder
├── IndexOptimizer.swift           Database query plan analyzer and concurrent index DDL generator
├── ModelRouter.swift              Gemini 3.8 intelligent task routing matrix and TS client generator
├── StorageGuard.swift             Cloud storage security policies and presigned URL compiler
├── CacheStrategist.swift          HTTP caching rules and Next.js edge middleware generator
├── RpcContractStudio.swift        Typed RPC procedure catalog and tRPC router synthesizer
└── ExperimentStudio.swift         Deterministic user bucketing and A/B test spec compiler
```

### Quality and Craftsmanship Standards

- **Apple HIG Grid**: Every dimension, margin, and padding adheres strictly to 0, 1, 2, or multiples of 4 pt.
- **Zero Emojis**: 100% SF Symbols and system glyphs across UI, code, comments, and commit messages.
- **Zero Warnings**: Clean release compilation under Swift 6.
- **Automated Self-Test**: 103/103 regression checks covering search, models, networking, canvas serialization, conflict resolution, pitfalls, starter prompt generation, editor launching, interactive mockups, blueprint packs, Antigravity waves, readiness linter, enhanced Mermaid export, error doctor, schema designer, codebase auditor, instant preview server, API contracts, state flow simulator, sitemap router, git storyteller, seed data generator, secret shield, dependency guard, deploy blueprint generator, context optimizer, component contract matrix, acceptance criteria builder, negative scope firewall, workstream splitter, patch inspector, fallback planner, developer runbook builder, eval harness, feature flag matrix, telemetry specifier, performance budget, threat modeler, migration strategist, localization specifier, webhook simulator, accessibility auditor, monorepo architect, SEO studio, skill synthesizer, token budgeteer, realtime architect, job queue strategist, incident commander, vector store specifier, compliance guardian, multi-tenant architect, stress test architect, email studio, doc studio, index optimizer, model router, storage guard, cache strategist, rpc contract studio, and experiment studio.
