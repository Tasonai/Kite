# Architecture Documentation

Kite is a native macOS application built with SwiftUI, SwiftData, and KiteKit.

## Canvas Subsystem Architecture

The Infinite Canvas subsystem is organized into modular, single-responsibility components:

```
Sources/Kite/
├── InfiniteCanvasView.swift      Viewport state, gestures, coordinate mapping, and lifecycle
├── CanvasToolbarView.swift       Floating HUD, tool selection, action menus, zoom, and banners
├── CanvasConnectionView.swift    Curved Bezier connectors, arrowheads, and protocol badges
├── CanvasNodeViews.swift         Node renderers (Frames, References, Stickies, Ideas)
├── CanvasLANPeersPopover.swift   LAN peer discovery popover and synchronization triggers
├── CanvasExporter.swift          Multi-format exporters (SVG, PNG, PDF, HTML, Mermaid)
└── Canvas/
    ├── CanvasComponents.swift    Geometry primitives (ArrowHead, CanvasGridBackground)
    └── CanvasReferencePicker.swift Reference catalog sheet (Mobbin / Figma)
```

### Component Responsibilities

1. **InfiniteCanvasView**
   - Coordinates pan and zoom viewport transformation matrix.
   - Manages marquee drag selection and multi-selection bounding boxes.
   - Dispatches node drag gestures and group movement offsets.
   - Connects SwiftData `@Query private var items: [Item]` to canvas nodes.

2. **CanvasToolbarView**
   - Floating glass HUD adhering to Apple HIG 4pt/8pt grid.
   - Tool picker (Select mode vs Pan mode).
   - Menus for AI Architecture (Auto-layout, Co-architect, Repo Ingestion, Roadmap HUD).
   - Menus for node creation and multi-format exports.
   - Integrated LAN peer discovery status indicator and popover launcher.

3. **CanvasConnectionView**
   - Dynamic cubic Bezier curve rendering with auto-orienting arrowheads.
   - Inline interactive connection badge for editing relationship names.
   - Protocol selector menu (Calls, HTTP/REST, SSE Stream, gRPC, WAL Query, Depends On, Audits).

4. **CanvasNodeViews**
   - `CanvasFrameNodeView`: Subsystem container with header drag handle and enclosed item tracking.
   - `CanvasReferenceNodeView`: Mobbin / Figma reference cards with external link preview and one-click conversion to Idea.
   - `CanvasStickyNodeView`: Quick design/architecture notes with colored tactile styling.
   - `CanvasIdeaNodeView`: SwiftData item cards with status, style tokens, and direct detail navigation.

5. **CanvasLANPeersPopover**
   - Discovered local Kite instances on port 49494.
   - Platform identification (macOS vs Windows) with one-click bidirectional canvas sync.

### Quality and Craftsmanship Standards

- **Apple HIG Grid**: Every dimension, margin, and padding adheres strictly to 0, 1, 2, or multiples of 4 pt.
- **Zero Emojis**: 100% SF Symbols and system glyphs across UI, code, comments, and commit messages.
- **Zero Warnings**: Clean release compilation under Swift 6.
- **Automated Self-Test**: 45/45 regression checks covering search, models, networking, and canvas serialization.
