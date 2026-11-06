# Architecture Review: 2026-11-06

Survey date: 2026-11-06
Codebase: Kite (macOS SwiftUI & KiteKit)
Standard: Apple HIG 4pt/8pt grid, Swift 6, Zero Emojis

## Survey Findings

- Hot spots by commit frequency (last 30 days):
  - `Sources/Kite/ContentView.swift` (18 changes)
  - `Sources/Kite/SelfTest.swift` (12 changes)
  - `Sources/Kite/InfiniteCanvasView.swift` (12 changes)
  - `Sources/KiteKit/AIGenerator.swift` (11 changes)
  - `Sources/Kite/PromptTranslatorView.swift` (11 changes)
- Largest Swift files:
  - `Sources/Kite/InfiniteCanvasView.swift`: 1,657 lines (urgent trigger: > 1,000 lines)
  - `Sources/KiteKit/WebStudio.swift`: 1,080 lines (raw HTML/JS template)
  - `Sources/Kite/ContentView.swift`: 646 lines (trigger: > 600 lines)
  - `Sources/Kite/PromptTranslatorView.swift`: 620 lines (trigger: > 600 lines)
  - `Sources/Kite/SkillsCatalogView.swift`: 582 lines

---

## Candidate 1: Infinite Canvas Modularization & Subview Extraction [Strong]

Files: `Sources/Kite/InfiniteCanvasView.swift` (1,657 lines)
Signal: File exceeds 1,000 lines (currently 1,657 lines). Touched in almost every canvas iteration.
Problem: `InfiniteCanvasView.swift` combines canvas pan/zoom coordination, floating toolbar HUD, LAN peers popover, marquee selection bounding box math, multi-element group drag delta translation, interactive bezier connection curves with protocol flyouts, and card renderers for frames, stickies, references, and ideas. Any small change to canvas logic forces re-evaluation of the entire 1,600-line body.
Proposal:
Decompose `InfiniteCanvasView.swift` into clean, focused sub-modules:
1. `CanvasToolbarView.swift`: Floating HUD, tools picker (Select vs Pan), action menus (AI, Add, Export), and peer badge.
2. `CanvasLANPeersPopover.swift`: Discovered local peers list and one-click sync handler.
3. `CanvasConnectionView.swift`: Dynamic bezier connection lines, arrowheads, protocol preset badges, and inline label editing.
4. `CanvasNodeViews.swift`: Dedicated SwiftUI subviews for `CanvasFrameView`, `CanvasStickyView`, and `CanvasReferenceCardView`.
5. `InfiniteCanvasView.swift`: Retains only viewport pan/zoom state, world coordinate container, and gesture event dispatching (~300 lines).

Benefits:
- Locality: Toolbar UI changes no longer touch canvas rendering or gesture handling.
- Readability: Each component fits on a single screen (80-200 lines).
- Compilation speed: Eliminates deep SwiftUI type-checker bottlenecks on large `ZStack` bodies.
Proof of same behavior:
- 45/45 Self-test checks pass (`tools/selftest.sh`).
- Apple HIG 4pt/8pt grid lint passes (`tools/grid-lint.sh`).
- Zero Emojis audit passes.
Plan:
1. Step 1: Extract `CanvasLANPeersPopover.swift` and `CanvasToolbarView.swift`.
2. Step 2: Extract `CanvasConnectionView.swift` (lines, arrows, protocol badges).
3. Step 3: Extract `CanvasNodeViews.swift` (`CanvasFrameView`, `CanvasStickyView`, `CanvasReferenceCardView`).
4. Step 4: Verify full suite, grid lint, and zero-warning build.

---

## Candidate 2: Prompt Translator View & Socratic Interview Split [Worth exploring]

Files: `Sources/Kite/PromptTranslatorView.swift` (620 lines)
Signal: File passes 600 lines threshold.
Problem: Houses the main idea translation form, the 3-question Socratic interview sheet, the AI model picker, and the multi-tab artifact preview renderer (PROJECT.md, DESIGN.md, BRIEF.md).
Proposal:
Extract `TranslatorInterviewSheet.swift` and `TranslatorArtifactPreview.swift` into separate modular views.
Benefits:
- Isolates Socratic interview state from artifact display.
- Reusable artifact previewer for other AI workflows.
Proof of same behavior:
- Self-test prompt translation checks pass.
Plan:
1. Extract `TranslatorInterviewSheet.swift`.
2. Extract `TranslatorArtifactPreview.swift`.
3. Re-assemble in `PromptTranslatorView.swift`.

---

## Candidate 3: Web Studio Resource Modularization [Speculative]

Files: `Sources/KiteKit/WebStudio.swift` (1,080 lines)
Signal: File passes 1,000 lines threshold.
Problem: Contains a large raw multiline string embedding CSS, SVG rendering, and vanilla JavaScript event listeners.
Proposal:
Split `WebStudio.swift` into `WebStudioHtml.swift`, `WebStudioCss.swift`, and `WebStudioJs.swift` extensions.
Benefits:
- Cleaner navigation of template parts.
Proof of same behavior:
- Byte-for-byte or functional output check on `GET /` of KiteSyncServer.

---

## Top Recommendation

**Candidate 1: Infinite Canvas Modularization & Subview Extraction [Strong]**.
`InfiniteCanvasView.swift` at 1,657 lines is the largest and most actively modified file in the project. Splitting it into focused subviews (`CanvasToolbarView`, `CanvasConnectionView`, `CanvasNodeViews`, `CanvasLANPeersPopover`) will dramatically improve code clarity, maintainability, and compilation times while keeping 100% behavior and visual parity.

### Considered, Not Recommended for Immediate Action
- Candidate 2 (`PromptTranslatorView.swift`): At 620 lines, it is only slightly above the 600-line warning threshold and remains relatively stable.
- Candidate 3 (`WebStudio.swift`): The file is a single consolidated string template for an embedded zero-dependency web server; splitting it across Swift files adds boilerplate without significant architectural gain.
