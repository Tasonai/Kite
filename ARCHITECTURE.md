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
└── TranslatorOutputView.swift     Quality readiness gauge, Anti-Pitfall card, starter prompt copy, and plan editor
Sources/KiteKit/
├── AIPitfalls.swift               Heuristic beginner pitfall detector (auth, payments, media, DB, AI quotas)
├── ProjectScaffolder.swift        Full project generator with START_HERE.md and GSD phase architecture
├── EditorLauncher.swift           One-click launcher for Cursor, VS Code, and Terminal
└── WebMockupGenerator.swift       Self-contained interactive HTML/Tailwind web prototype generator
```

### Quality and Craftsmanship Standards

- **Apple HIG Grid**: Every dimension, margin, and padding adheres strictly to 0, 1, 2, or multiples of 4 pt.
- **Zero Emojis**: 100% SF Symbols and system glyphs across UI, code, comments, and commit messages.
- **Zero Warnings**: Clean release compilation under Swift 6.
- **Automated Self-Test**: 55/55 regression checks covering search, models, networking, canvas serialization, conflict resolution, pitfalls, starter prompt generation, editor launching, interactive mockups, blueprint packs, Antigravity waves, readiness linter, and enhanced Mermaid export.
