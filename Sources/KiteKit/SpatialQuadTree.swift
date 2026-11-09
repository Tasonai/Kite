import CoreGraphics
import Foundation

/// 2D axis-aligned bounding box for spatial indexing.
public struct SpatialRect: Sendable, Equatable, Codable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var minX: Double { x }
    public var maxX: Double { x + width }
    public var minY: Double { y }
    public var maxY: Double { y + height }

    public func contains(pointX px: Double, pointY py: Double) -> Bool {
        px >= minX && px <= maxX && py >= minY && py <= maxY
    }

    public func intersects(_ other: SpatialRect) -> Bool {
        !(other.minX > maxX || other.maxX < minX || other.minY > maxY || other.maxY < minY)
    }

    public func contains(_ other: SpatialRect) -> Bool {
        other.minX >= minX && other.maxX <= maxX && other.minY >= minY && other.maxY <= maxY
    }
}

/// Generic item stored within the QuadTree index.
public struct SpatialItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let bounds: SpatialRect
    public let kind: String

    public init(id: String, bounds: SpatialRect, kind: String = "node") {
        self.id = id
        self.bounds = bounds
        self.kind = kind
    }
}

/// High-performance 2D spatial partitioning QuadTree for canvas view frustum culling.
/// Enables 120 FPS rendering on 10,000+ node architecture graphs.
public final class SpatialQuadTree: @unchecked Sendable {
    public let boundary: SpatialRect
    public let capacity: Int
    public let maxDepth: Int
    public let depth: Int

    private var items: [SpatialItem] = []
    private var children: [SpatialQuadTree]? = nil

    public init(boundary: SpatialRect, capacity: Int = 16, maxDepth: Int = 8, depth: Int = 0) {
        self.boundary = boundary
        self.capacity = capacity
        self.maxDepth = maxDepth
        self.depth = depth
    }

    public var count: Int {
        var total = items.count
        if let children = children {
            for child in children {
                total += child.count
            }
        }
        return total
    }

    @discardableResult
    public func insert(_ item: SpatialItem) -> Bool {
        if !boundary.intersects(item.bounds) {
            return false
        }

        if let children = children {
            for child in children {
                if child.boundary.contains(item.bounds) {
                    return child.insert(item)
                }
            }
            items.append(item)
            return true
        }

        items.append(item)

        if items.count > capacity && depth < maxDepth {
            subdivide()
        }

        return true
    }

    private func subdivide() {
        let halfW = boundary.width / 2.0
        let halfH = boundary.height / 2.0
        let x = boundary.x
        let y = boundary.y
        let nextDepth = depth + 1

        let nw = SpatialQuadTree(boundary: SpatialRect(x: x, y: y, width: halfW, height: halfH), capacity: capacity, maxDepth: maxDepth, depth: nextDepth)
        let ne = SpatialQuadTree(boundary: SpatialRect(x: x + halfW, y: y, width: halfW, height: halfH), capacity: capacity, maxDepth: maxDepth, depth: nextDepth)
        let sw = SpatialQuadTree(boundary: SpatialRect(x: x, y: y + halfH, width: halfW, height: halfH), capacity: capacity, maxDepth: maxDepth, depth: nextDepth)
        let se = SpatialQuadTree(boundary: SpatialRect(x: x + halfW, y: y + halfH, width: halfW, height: halfH), capacity: capacity, maxDepth: maxDepth, depth: nextDepth)

        let newChildren = [nw, ne, sw, se]
        children = newChildren

        // Redistribute items that fit cleanly into a quadrant
        var remaining: [SpatialItem] = []
        for it in items {
            var placed = false
            for child in newChildren {
                if child.boundary.contains(it.bounds) {
                    child.insert(it)
                    placed = true
                    break
                }
            }
            if !placed {
                remaining.append(it)
            }
        }
        items = remaining
    }

    public func query(range: SpatialRect) -> [SpatialItem] {
        var results: [SpatialItem] = []
        queryInternal(range: range, results: &results)
        return results
    }

    private func queryInternal(range: SpatialRect, results: inout [SpatialItem]) {
        if !boundary.intersects(range) {
            return
        }

        for it in items {
            if it.bounds.intersects(range) {
                results.append(it)
            }
        }

        if let children = children {
            for child in children {
                child.queryInternal(range: range, results: &results)
            }
        }
    }

    /// Query view frustum with configurable margin buffer to eliminate edge pop-in.
    public func queryFrustum(viewport: SpatialRect, margin: Double = 100.0) -> [SpatialItem] {
        let bufferedRange = SpatialRect(
            x: viewport.x - margin,
            y: viewport.y - margin,
            width: viewport.width + (margin * 2.0),
            height: viewport.height + (margin * 2.0)
        )
        return query(range: bufferedRange)
    }

    public func clear() {
        items.removeAll(keepingCapacity: false)
        children = nil
    }
}
