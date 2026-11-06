import Foundation

public struct ProposedAddition: Sendable {
    public let frameTitle: String
    public let stickyText: String
    public let colorHex: String
    public let connectionFrom: String
    public let connectionLabel: String
}

public enum CanvasCoArchitect {
    public static func suggestGaps(frames: [CanvasFrame], stickies: [CanvasSticky]) -> [ProposedAddition] {
        var additions: [ProposedAddition] = []
        let allText = (frames.map { $0.title } + stickies.map { $0.text }).joined(separator: " ").lowercased()

        // 1. Auth & Identity gap
        if !allText.contains("auth") && !allText.contains("identity") && !allText.contains("jwt") {
            additions.append(ProposedAddition(
                frameTitle: "Security & Identity",
                stickyText: "Token Auth & Access Boundary",
                colorHex: "#FEE2E2",
                connectionFrom: "UI",
                connectionLabel: "Authenticates"
            ))
        }

        // 2. Cache & Performance gap
        if !allText.contains("cache") && !allText.contains("redis") && !allText.contains("buffer") {
            additions.append(ProposedAddition(
                frameTitle: "Performance & Caching",
                stickyText: "In-Memory LRU Cache & WAL",
                colorHex: "#FEF3C7",
                connectionFrom: "Service",
                connectionLabel: "Cached By"
            ))
        }

        // 3. Observability & Tracing gap
        if !allText.contains("log") && !allText.contains("trace") && !allText.contains("metric") && !allText.contains("telemetry") {
            additions.append(ProposedAddition(
                frameTitle: "Observability & Audit",
                stickyText: "Structured Logs & Tracing Span",
                colorHex: "#E0E7FF",
                connectionFrom: "Storage",
                connectionLabel: "Monitors"
            ))
        }

        return additions
    }

    public static func applyGaps(
        to frames: inout [CanvasFrame],
        stickies: inout [CanvasSticky],
        connections: inout [CanvasConnection]
    ) -> Int {
        let suggestions = suggestGaps(frames: frames, stickies: stickies)
        guard !suggestions.isEmpty else { return 0 }

        var startX: CGFloat = 1300
        let startY: CGFloat = 100

        for s in suggestions {
            let frame = CanvasFrame(
                title: s.frameTitle,
                colorHex: "#EC4899",
                x: startX,
                y: startY,
                width: 320,
                height: 300
            )
            frames.append(frame)

            let sticky = CanvasSticky(
                text: s.stickyText,
                colorHex: s.colorHex,
                position: CGPoint(x: startX + 20, y: startY + 60)
            )
            stickies.append(sticky)

            // Connect from existing sticky if found
            if let existing = stickies.first(where: { $0.text.lowercased().contains(s.connectionFrom.lowercased()) && $0.id != sticky.id }) {
                connections.append(CanvasConnection(
                    fromId: existing.id.uuidString,
                    toId: sticky.id.uuidString,
                    label: s.connectionLabel,
                    colorHex: "#EC4899"
                ))
            }

            startX += 360
        }

        return suggestions.count
    }
}
