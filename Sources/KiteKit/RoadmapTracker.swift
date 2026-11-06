import Foundation

public struct PhaseTask: Sendable {
    public let title: String
    public let status: String // pending, in_progress, verified
}

public struct PhaseWave: Sendable {
    public let phaseNumber: Int
    public let name: String
    public let tasks: [PhaseTask]
}

public enum RoadmapTracker {
    public static func parseOrCreateRoadmap(from markdown: String? = nil, ideaTitle: String = "Project") -> [PhaseWave] {
        if let md = markdown, !md.isEmpty {
            var waves: [PhaseWave] = []
            var currentPhaseName = ""
            var currentTasks: [PhaseTask] = []
            var phaseCounter = 1

            for line in md.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("## Phase") || trimmed.hasPrefix("## Фаза") {
                    if !currentPhaseName.isEmpty {
                        waves.append(PhaseWave(phaseNumber: phaseCounter, name: currentPhaseName, tasks: currentTasks))
                        phaseCounter += 1
                        currentTasks.removeAll()
                    }
                    currentPhaseName = trimmed.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
                } else if trimmed.hasPrefix("- [x]") {
                    currentTasks.append(PhaseTask(title: trimmed.replacingOccurrences(of: "- [x]", with: "").trimmingCharacters(in: .whitespaces), status: "verified"))
                } else if trimmed.hasPrefix("- [/]") {
                    currentTasks.append(PhaseTask(title: trimmed.replacingOccurrences(of: "- [/]", with: "").trimmingCharacters(in: .whitespaces), status: "in_progress"))
                } else if trimmed.hasPrefix("- [ ]") {
                    currentTasks.append(PhaseTask(title: trimmed.replacingOccurrences(of: "- [ ]", with: "").trimmingCharacters(in: .whitespaces), status: "pending"))
                }
            }

            if !currentPhaseName.isEmpty {
                waves.append(PhaseWave(phaseNumber: phaseCounter, name: currentPhaseName, tasks: currentTasks))
            }

            if !waves.isEmpty { return waves }
        }

        // Standard default 3 waves
        return [
            PhaseWave(phaseNumber: 1, name: "Phase 1: Foundation & Data", tasks: [
                PhaseTask(title: "Local Schema & SQLite/SwiftData", status: "verified"),
                PhaseTask(title: "P2P REST Handshake (Port 24242/3)", status: "verified"),
                PhaseTask(title: "Zero Emojis Lint & Audit", status: "verified")
            ]),
            PhaseWave(phaseNumber: 2, name: "Phase 2: Core Architecture", tasks: [
                PhaseTask(title: "Interactive Canvas & Connectors", status: "in_progress"),
                PhaseTask(title: "AI Co-Architect & Gap Engine", status: "in_progress"),
                PhaseTask(title: "Repo Ingestion Parser", status: "pending")
            ]),
            PhaseWave(phaseNumber: 3, name: "Phase 3: Polish & Distribution", tasks: [
                PhaseTask(title: "Apple HIG & BAWA Grid Verification", status: "pending"),
                PhaseTask(title: "Homebrew Cask & Setup.exe", status: "verified"),
                PhaseTask(title: "End-to-End P2P Sync Test", status: "verified")
            ])
        ]
    }

    public static func generateWaves(content: String = "") -> (frames: [CanvasFrame], stickies: [CanvasSticky], connections: [CanvasConnection]) {
        let waves = parseOrCreateRoadmap(from: content)
        return generateCanvasLanes(waves: waves)
    }

    public static func generateCanvasLanes(waves: [PhaseWave]) -> (frames: [CanvasFrame], stickies: [CanvasSticky], connections: [CanvasConnection]) {
        var frames: [CanvasFrame] = []
        var stickies: [CanvasSticky] = []
        var connections: [CanvasConnection] = []

        var startX: CGFloat = 80
        var previousPhaseLastStickyId = ""

        for wave in waves {
            let color = wave.phaseNumber == 1 ? "#10B981" : (wave.phaseNumber == 2 ? "#3B82F6" : "#8B5CF6")
            let frame = CanvasFrame(
                title: "\(wave.name) [Wave \(wave.phaseNumber)]",
                colorHex: color,
                x: startX,
                y: 80,
                width: 360,
                height: 480
            )
            frames.append(frame)

            var firstStickyIdInPhase = ""
            for (idx, task) in wave.tasks.prefix(3).enumerated() {
                let badge = task.status == "verified" ? "[DONE]" : (task.status == "in_progress" ? "[WIP]" : "[TODO]")
                let stickyColor = task.status == "verified" ? "#D1FAE5" : (task.status == "in_progress" ? "#FEF3C7" : "#F3F4F6")
                let sticky = CanvasSticky(
                    text: "\(badge) \(task.title)",
                    colorHex: stickyColor,
                    position: CGPoint(x: startX + 24.0, y: 150.0 + CGFloat(idx * 100))
                )
                stickies.append(sticky)

                if idx == 0 { firstStickyIdInPhase = sticky.id.uuidString }
                if idx == wave.tasks.count - 1 {
                    if !previousPhaseLastStickyId.isEmpty {
                        connections.append(CanvasConnection(
                            fromId: previousPhaseLastStickyId,
                            toId: firstStickyIdInPhase,
                            label: "Depends On",
                            colorHex: color
                        ))
                    }
                    previousPhaseLastStickyId = sticky.id.uuidString
                }
            }

            startX += 420
        }

        return (frames, stickies, connections)
    }
}
