import CoreGraphics
import Foundation

public struct CanvasSticky: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public var text: String
    public var colorHex: String
    public var position: CGPoint

    public init(id: UUID = UUID(), text: String, colorHex: String, position: CGPoint = .zero) {
        self.id = id
        self.text = text
        self.colorHex = colorHex
        self.position = position
    }

    enum CodingKeys: String, CodingKey {
        case id, text, colorHex, position, x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rawId = try? container.decode(UUID.self, forKey: .id) {
            self.id = rawId
        } else if let strId = try? container.decode(String.self, forKey: .id), let parsed = UUID(uuidString: strId) {
            self.id = parsed
        } else {
            self.id = UUID()
        }
        self.text = (try? container.decode(String.self, forKey: .text)) ?? ""
        self.colorHex = (try? container.decode(String.self, forKey: .colorHex)) ?? "#FEF08A"

        if let pt = try? container.decode(CGPoint.self, forKey: .position) {
            self.position = pt
        } else if let arr = try? container.decode([CGFloat].self, forKey: .position), arr.count >= 2 {
            self.position = CGPoint(x: arr[0], y: arr[1])
        } else if let x = try? container.decode(CGFloat.self, forKey: .x), let y = try? container.decode(CGFloat.self, forKey: .y) {
            self.position = CGPoint(x: x, y: y)
        } else {
            self.position = CGPoint(x: 100, y: 100)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(position, forKey: .position)
    }
}

public enum CanvasConnectionProtocol: String, Sendable, CaseIterable, Codable {
    case rest = "REST"
    case trpc = "tRPC"
    case grpc = "gRPC"
    case websocket = "WebSocket"
    case eventbus = "EventBus"
    case graphql = "GraphQL"
    case sql = "SQL"
    case queue = "Queue"

    public var colorHex: String {
        switch self {
        case .rest: return "#3B82F6"
        case .trpc: return "#8B5CF6"
        case .grpc: return "#10B981"
        case .websocket: return "#EC4899"
        case .eventbus: return "#F59E0B"
        case .graphql: return "#E11D48"
        case .sql: return "#64748B"
        case .queue: return "#14B8A6"
        }
    }

    public static func color(for label: String) -> String {
        let lower = label.lowercased()
        if lower.contains("trpc") { return CanvasConnectionProtocol.trpc.colorHex }
        if lower.contains("grpc") { return CanvasConnectionProtocol.grpc.colorHex }
        if lower.contains("ws") || lower.contains("socket") || lower.contains("stream") { return CanvasConnectionProtocol.websocket.colorHex }
        if lower.contains("event") || lower.contains("bus") || lower.contains("kafka") { return CanvasConnectionProtocol.eventbus.colorHex }
        if lower.contains("graphql") || lower.contains("gql") { return CanvasConnectionProtocol.graphql.colorHex }
        if lower.contains("sql") || lower.contains("db") || lower.contains("query") { return CanvasConnectionProtocol.sql.colorHex }
        if lower.contains("queue") || lower.contains("inngest") || lower.contains("job") { return CanvasConnectionProtocol.queue.colorHex }
        return CanvasConnectionProtocol.rest.colorHex
    }
}

public struct CanvasConnection: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let fromId: String
    public let toId: String
    public var label: String
    public var colorHex: String

    public init(id: UUID = UUID(), fromId: String, toId: String, label: String = "", colorHex: String = "#D97757") {
        self.id = id
        self.fromId = fromId
        self.toId = toId
        self.label = label
        self.colorHex = colorHex
    }

    enum CodingKeys: String, CodingKey {
        case id, fromId, toId, label, colorHex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rawId = try? container.decode(UUID.self, forKey: .id) {
            self.id = rawId
        } else if let strId = try? container.decode(String.self, forKey: .id), let parsed = UUID(uuidString: strId) {
            self.id = parsed
        } else {
            self.id = UUID()
        }
        self.fromId = (try? container.decode(String.self, forKey: .fromId)) ?? ""
        self.toId = (try? container.decode(String.self, forKey: .toId)) ?? ""
        self.label = (try? container.decode(String.self, forKey: .label)) ?? ""
        self.colorHex = (try? container.decode(String.self, forKey: .colorHex)) ?? "#D97757"
    }
}

public struct CanvasFrame: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public var title: String
    public var colorHex: String
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var height: CGFloat

    public init(id: UUID = UUID(), title: String, colorHex: String = "#3B82F6", x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, colorHex, x, y, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rawId = try? container.decode(UUID.self, forKey: .id) {
            self.id = rawId
        } else if let strId = try? container.decode(String.self, forKey: .id), let parsed = UUID(uuidString: strId) {
            self.id = parsed
        } else {
            self.id = UUID()
        }
        self.title = (try? container.decode(String.self, forKey: .title)) ?? "Frame"
        self.colorHex = (try? container.decode(String.self, forKey: .colorHex)) ?? "#3B82F6"
        self.x = (try? container.decode(CGFloat.self, forKey: .x)) ?? 100
        self.y = (try? container.decode(CGFloat.self, forKey: .y)) ?? 100
        self.width = (try? container.decode(CGFloat.self, forKey: .width)) ?? 340
        self.height = (try? container.decode(CGFloat.self, forKey: .height)) ?? 420
    }
}

public struct CanvasReferenceCard: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public var title: String
    public var source: String // Mobbin, Figma, Recent Design
    public var url: String
    public var colorHex: String
    public var position: CGPoint
    public var tags: [String]
    public var description: String

    public init(
        id: UUID = UUID(),
        title: String,
        source: String,
        url: String,
        colorHex: String,
        position: CGPoint,
        tags: [String],
        description: String
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.url = url
        self.colorHex = colorHex
        self.position = position
        self.tags = tags
        self.description = description
    }
}

public struct CanvasExportModel: Codable, Sendable {
    public var version: Int
    public var exportedAt: String
    public var frames: [CanvasFrame]
    public var stickies: [CanvasSticky]
    public var referenceCards: [CanvasReferenceCard]
    public var connections: [CanvasConnection]
    public var replace: Bool?

    public init(
        version: Int = 1,
        exportedAt: String = ISO8601DateFormatter().string(from: Date()),
        frames: [CanvasFrame] = [],
        stickies: [CanvasSticky] = [],
        referenceCards: [CanvasReferenceCard] = [],
        connections: [CanvasConnection] = [],
        replace: Bool? = false
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.frames = frames
        self.stickies = stickies
        self.referenceCards = referenceCards
        self.connections = connections
        self.replace = replace
    }

    enum CodingKeys: String, CodingKey {
        case version, exportedAt, frames, stickies, referenceCards, connections, replace
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = (try? container.decode(Int.self, forKey: .version)) ?? 1
        self.exportedAt = (try? container.decode(String.self, forKey: .exportedAt)) ?? ISO8601DateFormatter().string(from: Date())
        self.frames = (try? container.decode([CanvasFrame].self, forKey: .frames)) ?? []
        self.stickies = (try? container.decode([CanvasSticky].self, forKey: .stickies)) ?? []
        self.referenceCards = (try? container.decode([CanvasReferenceCard].self, forKey: .referenceCards)) ?? []
        self.connections = (try? container.decode([CanvasConnection].self, forKey: .connections)) ?? []
        self.replace = try? container.decode(Bool.self, forKey: .replace)
    }
}
