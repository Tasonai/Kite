import Foundation

public struct IngestedNode: Sendable {
    public let id: String
    public let title: String
    public let role: String // ui, service, data, external
    public let details: String
}

public struct IngestedArchitecture: Sendable {
    public let projectType: String
    public let name: String
    public let frames: [CanvasFrame]
    public let stickies: [CanvasSticky]
    public let connections: [CanvasConnection]
}

public enum CodebaseIngestion {
    public static func analyze(at folderURL: URL) -> IngestedArchitecture {
        let fm = FileManager.default
        let folderName = folderURL.lastPathComponent
        
        var projectType = "Generic Project"
        var uiNodes: [String] = []
        var serviceNodes: [String] = []
        var dataNodes: [String] = []
        var testNodes: [String] = []
        
        // Check Package.swift (Swift)
        if fm.fileExists(atPath: folderURL.appendingPathComponent("Package.swift").path) {
            projectType = "Swift SPM Package"
        }
        // Check .csproj / .sln (.NET)
        let files = (try? fm.contentsOfDirectory(atPath: folderURL.path)) ?? []
        if files.contains(where: { $0.hasSuffix(".csproj") || $0.hasSuffix(".sln") }) {
            projectType = ".NET 10 / WinUI 3"
        }
        // Check package.json (Node/Web)
        if fm.fileExists(atPath: folderURL.appendingPathComponent("package.json").path) {
            projectType = "TypeScript / Modern Web"
        }

        // Scan subdirectories
        for item in files {
            let lower = item.lowercased()
            if lower.contains("view") || lower.contains("page") || lower.contains("ui") || lower.contains("component") {
                uiNodes.append(item)
            } else if lower.contains("service") || lower.contains("sync") || lower.contains("controller") || lower.contains("api") || lower.contains("kit") {
                serviceNodes.append(item)
            } else if lower.contains("model") || lower.contains("data") || lower.contains("store") || lower.contains("db") {
                dataNodes.append(item)
            } else if lower.contains("test") {
                testNodes.append(item)
            }
        }

        // Defaults if sparse
        if uiNodes.isEmpty { uiNodes = ["Views & Pages", "Design Tokens", "Navigation HUD"] }
        if serviceNodes.isEmpty { serviceNodes = ["P2P Sync Server", "AI Generator Service", "REST Client"] }
        if dataNodes.isEmpty { dataNodes = ["Local Store (WAL)", "Cache Index", "Schema Models"] }

        // Generate Frames
        let frameUI = CanvasFrame(
            title: "UI & Presentation Layer (\(projectType))",
            colorHex: "#3B82F6",
            x: 100, y: 100, width: 340, height: 420
        )
        let frameService = CanvasFrame(
            title: "Domain Services & P2P",
            colorHex: "#10B981",
            x: 500, y: 100, width: 340, height: 420
        )
        let frameData = CanvasFrame(
            title: "Data Persistence & State",
            colorHex: "#8B5CF6",
            x: 900, y: 100, width: 340, height: 420
        )

        var stickies: [CanvasSticky] = []
        var connections: [CanvasConnection] = []

        // Create stickies for UI
        var lastUIId = ""
        for (idx, node) in uiNodes.prefix(3).enumerated() {
            let sticky = CanvasSticky(
                text: "UI: \(node)",
                colorHex: "#DBEAFE",
                position: CGPoint(x: 120, y: 160 + (idx * 110))
            )
            stickies.append(sticky)
            lastUIId = sticky.id.uuidString
        }

        // Create stickies for Service
        var lastServiceId = ""
        for (idx, node) in serviceNodes.prefix(3).enumerated() {
            let sticky = CanvasSticky(
                text: "Service: \(node)",
                colorHex: "#D1FAE5",
                position: CGPoint(x: 520, y: 160 + (idx * 110))
            )
            stickies.append(sticky)
            lastServiceId = sticky.id.uuidString
        }

        // Create stickies for Data
        var lastDataId = ""
        for (idx, node) in dataNodes.prefix(3).enumerated() {
            let sticky = CanvasSticky(
                text: "Storage: \(node)",
                colorHex: "#EDE9FE",
                position: CGPoint(x: 920, y: 160 + (idx * 110))
            )
            stickies.append(sticky)
            lastDataId = sticky.id.uuidString
        }

        // Connect UI -> Service -> Data
        if !lastUIId.isEmpty && !lastServiceId.isEmpty {
            connections.append(CanvasConnection(fromId: lastUIId, toId: lastServiceId, label: "Calls", colorHex: "#3B82F6"))
        }
        if !lastServiceId.isEmpty && !lastDataId.isEmpty {
            connections.append(CanvasConnection(fromId: lastServiceId, toId: lastDataId, label: "Persists", colorHex: "#10B981"))
        }

        return IngestedArchitecture(
            projectType: projectType,
            name: folderName,
            frames: [frameUI, frameService, frameData],
            stickies: stickies,
            connections: connections
        )
    }
}
