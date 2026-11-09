import Foundation

public enum TelemetryHealthStatus: String, Codable, Sendable {
    case healthy = "healthy"
    case degraded = "degraded"
    case failing = "failing"

    public var colorHex: String {
        switch self {
        case .healthy: return "#2ECC71"
        case .degraded: return "#F39C12"
        case .failing: return "#E74C3C"
        }
    }
}

public struct NodeTelemetry: Codable, Sendable, Identifiable {
    public var id: String { nodeId }
    public var nodeId: String
    public var rps: Double
    public var p99LatencyMs: Double
    public var errorRate: Double
    public var status: TelemetryHealthStatus
    public var lastUpdated: Date

    public init(
        nodeId: String,
        rps: Double,
        p99LatencyMs: Double,
        errorRate: Double,
        lastUpdated: Date = Date()
    ) {
        self.nodeId = nodeId
        self.rps = max(0.0, rps)
        self.p99LatencyMs = max(0.0, p99LatencyMs)
        self.errorRate = max(0.0, min(1.0, errorRate))
        self.lastUpdated = lastUpdated

        if self.errorRate >= 0.05 || self.p99LatencyMs >= 1000.0 {
            self.status = .failing
        } else if self.errorRate >= 0.01 || self.p99LatencyMs >= 300.0 {
            self.status = .degraded
        } else {
            self.status = .healthy
        }
    }
}

public struct IDEBridgeMessage: Codable, Sendable {
    public var type: String
    public var filePath: String?
    public var line: Int?
    public var column: Int?
    public var nodeId: String?
    public var nodeName: String?
    public var editor: String?
    public var telemetry: NodeTelemetry?

    public init(
        type: String,
        filePath: String? = nil,
        line: Int? = nil,
        column: Int? = nil,
        nodeId: String? = nil,
        nodeName: String? = nil,
        editor: String? = nil,
        telemetry: NodeTelemetry? = nil
    ) {
        self.type = type
        self.filePath = filePath
        self.line = line
        self.column = column
        self.nodeId = nodeId
        self.nodeName = nodeName
        self.editor = editor
        self.telemetry = telemetry
    }
}

public final class IDEBridgeHub: @unchecked Sendable {
    public static let shared = IDEBridgeHub()

    private let lock = NSLock()
    private var activeFilePath: String?
    private var activeLine: Int?
    private var telemetries: [String: NodeTelemetry] = [:]
    private var connectedEditors: Set<String> = []

    private init() {}

    public func updateActiveFile(path: String, line: Int? = nil, editor: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        self.activeFilePath = path
        self.activeLine = line
        if let ed = editor, !ed.isEmpty {
            self.connectedEditors.insert(ed)
        }
    }

    public var currentActiveFile: (path: String?, line: Int?) {
        lock.lock()
        defer { lock.unlock() }
        return (activeFilePath, activeLine)
    }

    public func setTelemetry(_ telemetry: NodeTelemetry) {
        lock.lock()
        defer { lock.unlock() }
        telemetries[telemetry.nodeId] = telemetry
    }

    public func getTelemetry(for nodeId: String) -> NodeTelemetry? {
        lock.lock()
        defer { lock.unlock() }
        return telemetries[nodeId]
    }

    public func allTelemetries() -> [NodeTelemetry] {
        lock.lock()
        defer { lock.unlock() }
        return Array(telemetries.values)
    }

    public func createEditorDeepLink(filePath: String, line: Int? = nil, column: Int? = nil, editor: String = "vscode") -> URL? {
        let l = line ?? 1
        let c = column ?? 1
        let scheme = editor.lowercased().contains("cursor") ? "cursor" : "vscode"
        let encodedPath = filePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filePath
        let urlString = "\(scheme)://file/\(encodedPath):\(l):\(c)"
        return URL(string: urlString)
    }
}
