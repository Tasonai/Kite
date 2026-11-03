# Kite

A native macOS studio for curating anti-slop visual aesthetics, capturing project ideas, and generating production-grade engineering prompts and starter scaffolds for Google Antigravity agents.

## Replaces
Scattered browser bookmarks, unorganized notes, generic LLM prompts, and manual agent scaffolding.

## Main jobs
1. **Curate Taste & Styles:** Explore curated visual design systems (Swiss Modern, Linear Cockpit, Neo-Brutalism, Voxel 3D, Editorial) with color tokens, typography rules, and reference links.
2. **Idea Backlog & Scratchpad:** Rapidly capture project concepts with status tracking (Backlog, In Progress, Completed), target platforms (Web, Mobile, Desktop), and tags.
3. **Prompt & Blueprint Studio:** Translate project ideas into comprehensive engineering specifications (`/plan`, skills composition, JTBD, anti-slop constraints) ready for Antigravity agents in 1 click.

## Data
- `InspirationStyle`: title, category, description, imagePrompt, copyBrief, keywords, tokens (accent, background, surface, text, typography).
- `ProjectIdea`: title, concept, platform (web/mobile/desktop), preferredStyle, status (backlog/in_progress/completed), tags, timestamps.
- `PromptBlueprint`: rawInput, formattedPlan, skills, qualityScore, targetPlatform, timestamp.

## Shape
Three-pane NavigationSplitView window (Sidebar, Content List, Detail Inspector). macOS 26 or later. Local SwiftData storage. Works 100% offline. No accounts.

## System hooks
- Menu bar quick action
- Keyboard shortcuts (⌘N for new idea, ⌘K for search)
- 1-click system clipboard copy with audio feedback

## Reference
Linear, Craft, Things 3, Raycast.

## Look
Native macOS design on warm stone surfaces (`#FAF9F5`), ink-dark typography (`#1C1B18`), subtle hairline dividers (`#DDD9D0`), terracotta accent token (`#D97757`), SF Pro and New York serif headings.

## Not in version one
- Cloud account sync
- Multi-user team sharing
- Remote Git repository push (exports to local files or clipboard instead)
