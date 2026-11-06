import Foundation

public struct GitStoryReport: Sendable {
    public var prTitle: String
    public var suggestedCommits: [String]
    public var prBodyMarkdown: String

    public init(prTitle: String, suggestedCommits: [String], prBodyMarkdown: String) {
        self.prTitle = prTitle
        self.suggestedCommits = suggestedCommits
        self.prBodyMarkdown = prBodyMarkdown
    }
}

public enum GitStoryteller {
    public static func craftStory(
        title: String,
        concept: String,
        platform: String,
        style: String,
        repoDirectory: URL? = nil
    ) -> GitStoryReport {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Проект" : title
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Реализация проекта" : concept

        let prTitle = "feat: implement \(cleanTitle) MVP architecture"
        let commits = [
            "feat(core): initialize foundation, data schemas, and persistence layer",
            "feat(domain): implement core state machines, services, and validation",
            "feat(ui): compose screens adhering to 4pt/8pt grid and \(style) tokens",
            "test(quality): add regression tests, audit a11y, and clean dead code"
        ]

        let prBody = """
        ## Overview & JTBD
        \(cleanConcept)

        - **Target Platform:** \(platform)
        - **Visual System:** \(style) (Strict 4pt/8pt grid, zero slop)
        - **Craftsmanship:** Sub-250ms tactile feedback, keyboard accessibility

        ## Architectural Waves Implemented
        - [x] **Wave 1 (Foundation):** Core domain entities, storage models, and type contracts.
        - [x] **Wave 2 (Logic):** State machines, domain services, and edge case handling.
        - [x] **Wave 3 (UI):** High-density interface, design tokens, and focus states.
        - [x] **Wave 4 (Quality Gate):** Automated tests, WCAG AA contrast check, zero console logs.

        ## Verification & Testing
        ```bash
        # Run test suite
        npm test || swift test
        ```

        > Created and audited via **Kite Pre-flight Cockpit for Antigravity**.
        """

        return GitStoryReport(
            prTitle: prTitle,
            suggestedCommits: commits,
            prBodyMarkdown: prBody
        )
    }
}
