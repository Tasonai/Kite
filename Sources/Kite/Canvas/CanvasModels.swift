import Foundation

public struct CanvasSticky: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public var text: String
    public var colorHex: String
    public var position: CGPoint

    public init(id: UUID = UUID(), text: String, colorHex: String, position: CGPoint) {
        self.id = id
        self.text = text
        self.colorHex = colorHex
        self.position = position
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
