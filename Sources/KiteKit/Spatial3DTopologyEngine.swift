//
// Spatial3DTopologyEngine.swift
// KiteKit
//
// 3D Spatial Architecture Topology & Immersive Scene Graph Engine.
// Projects 2D architecture canvases onto 5 semantic Z-elevation strata (Edge, Presentation,
// Domain, Event Streaming, Stateful Storage), executes 3D force-directed spring-repulsion
// relaxation, performs analytic ray-sphere picking, and exports glTF 2.0 JSON scene graphs.
//

import Foundation

public struct Spatial3DNode: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let label: String
    public let stratum: String
    public var x: Double
    public var y: Double
    public var z: Double
    public let boundingRadius: Double

    public init(
        id: String,
        label: String,
        stratum: String,
        x: Double,
        y: Double,
        z: Double,
        boundingRadius: Double = 12.0
    ) {
        self.id = id
        self.label = label
        self.stratum = stratum
        self.x = x
        self.y = y
        self.z = z
        self.boundingRadius = boundingRadius
    }
}

public struct Spatial3DEdge: Codable, Sendable, Equatable {
    public let sourceId: String
    public let targetId: String
    public let wireProtocol: String

    enum CodingKeys: String, CodingKey {
        case sourceId
        case targetId
        case wireProtocol = "protocol"
    }

    public init(sourceId: String, targetId: String, wireProtocol: String = "gRPC") {
        self.sourceId = sourceId
        self.targetId = targetId
        self.wireProtocol = wireProtocol
    }
}

public struct Spatial3DScene: Codable, Sendable, Equatable {
    public let sceneId: String
    public let strataCount: Int
    public var nodes: [Spatial3DNode]
    public let edges: [Spatial3DEdge]

    public init(
        sceneId: String = "kite-spatial3d-scene-01",
        strataCount: Int = 5,
        nodes: [Spatial3DNode],
        edges: [Spatial3DEdge]
    ) {
        self.sceneId = sceneId
        self.strataCount = strataCount
        self.nodes = nodes
        self.edges = edges
    }
}

public struct RayPickHit: Codable, Sendable, Equatable {
    public let hit: Bool
    public let nodeId: String?
    public let distance: Double

    public init(hit: Bool, nodeId: String?, distance: Double) {
        self.hit = hit
        self.nodeId = nodeId
        self.distance = distance
    }
}

public struct GltfExportBundle: Codable, Sendable, Equatable {
    public let formatVersion: String
    public let nodeCount: Int
    public let gltfJson: String

    public init(formatVersion: String = "glTF-2.0", nodeCount: Int, gltfJson: String) {
        self.formatVersion = formatVersion
        self.nodeCount = nodeCount
        self.gltfJson = gltfJson
    }
}

public final class Spatial3DTopologyEngine: @unchecked Sendable {
    public static let shared = Spatial3DTopologyEngine()

    private let lock = NSLock()
    private var scene: Spatial3DScene

    public init() {
        scene = Self.makeDefaultScene()
    }

    private static func makeDefaultScene() -> Spatial3DScene {
        let nodes = [
            Spatial3DNode(id: "node-cdn", label: "Global Edge WASI CDN", stratum: "Z0-Edge", x: 0.0, y: 40.0, z: 0.0, boundingRadius: 12.0),
            Spatial3DNode(id: "node-bff", label: "Web & Mobile BFF", stratum: "Z1-Presentation", x: -24.0, y: 20.0, z: -40.0, boundingRadius: 12.0),
            Spatial3DNode(id: "node-orders", label: "Orders Domain Service", stratum: "Z2-Domain", x: 0.0, y: 0.0, z: -80.0, boundingRadius: 14.0),
            Spatial3DNode(id: "node-kafka", label: "Kafka Event Backbone", stratum: "Z3-Streaming", x: 28.0, y: -16.0, z: -120.0, boundingRadius: 12.0),
            Spatial3DNode(id: "node-pg", label: "CockroachDB Ledger", stratum: "Z4-StatefulStorage", x: 0.0, y: -36.0, z: -160.0, boundingRadius: 16.0)
        ]
        let edges = [
            Spatial3DEdge(sourceId: "node-cdn", targetId: "node-bff", wireProtocol: "HTTP/3"),
            Spatial3DEdge(sourceId: "node-bff", targetId: "node-orders", wireProtocol: "gRPC"),
            Spatial3DEdge(sourceId: "node-orders", targetId: "node-kafka", wireProtocol: "Kafka-TLS"),
            Spatial3DEdge(sourceId: "node-orders", targetId: "node-pg", wireProtocol: "PostgreSQL-Wire")
        ]
        return Spatial3DScene(sceneId: "kite-spatial3d-scene-01", strataCount: 5, nodes: nodes, edges: edges)
    }

    public func getScene() -> Spatial3DScene {
        lock.lock()
        defer { lock.unlock() }
        return scene
    }

    public func computeForceDirectedLayout(iterations: Int = 12) -> Spatial3DScene {
        lock.lock()
        defer { lock.unlock() }

        var nodes = scene.nodes.map { n in
            Spatial3DNode(
                id: n.id,
                label: n.label,
                stratum: n.stratum,
                x: n.x,
                y: n.y,
                z: Self.stratumElevationZ(n.stratum),
                boundingRadius: n.boundingRadius
            )
        }

        let steps = min(max(iterations, 1), 50)
        let repulsionK = 180.0

        for _ in 0..<steps {
            for i in 0..<nodes.count {
                var fx = 0.0
                var fy = 0.0
                for j in 0..<nodes.count where i != j {
                    let dx = nodes[i].x - nodes[j].x
                    let dy = nodes[i].y - nodes[j].y
                    let distSq = (dx * dx) + (dy * dy) + 16.0
                    let dist = sqrt(distSq)
                    let force = repulsionK / distSq
                    fx += (dx / dist) * force
                    fy += (dy / dist) * force
                }
                nodes[i].x = ((nodes[i].x + fx * 0.25) * 100.0).rounded() / 100.0
                nodes[i].y = ((nodes[i].y + fy * 0.25) * 100.0).rounded() / 100.0
            }
        }

        scene.nodes = nodes
        return scene
    }

    public func raycastPick(
        originX: Double,
        originY: Double,
        originZ: Double,
        dirX: Double,
        dirY: Double,
        dirZ: Double
    ) -> RayPickHit {
        lock.lock()
        let nodes = scene.nodes
        lock.unlock()

        let len = sqrt((dirX * dirX) + (dirY * dirY) + (dirZ * dirZ))
        guard len >= 1e-9 else {
            return RayPickHit(hit: false, nodeId: nil, distance: -1.0)
        }

        let dx = dirX / len
        let dy = dirY / len
        let dz = dirZ / len

        var closestNode: String? = nil
        var closestT = Double.greatestFiniteMagnitude

        for n in nodes {
            let ocX = originX - n.x
            let ocY = originY - n.y
            let ocZ = originZ - n.z

            let b = (ocX * dx) + (ocY * dy) + (ocZ * dz)
            let c = (ocX * ocX) + (ocY * ocY) + (ocZ * ocZ) - (n.boundingRadius * n.boundingRadius)
            let discriminant = (b * b) - c

            if discriminant >= 0.0 {
                let t = -b - sqrt(discriminant)
                if t > 0.0 && t < closestT {
                    closestT = t
                    closestNode = n.id
                }
            }
        }

        if let hitId = closestNode {
            let roundedDist = (closestT * 100.0).rounded() / 100.0
            return RayPickHit(hit: true, nodeId: hitId, distance: roundedDist)
        }
        return RayPickHit(hit: false, nodeId: nil, distance: -1.0)
    }

    public func exportGltfScene() -> GltfExportBundle {
        lock.lock()
        let snap = scene
        lock.unlock()

        let gltfNodes = snap.nodes.map { n in
            let xStr = String(format: "%.2f", n.x)
            let yStr = String(format: "%.2f", n.y)
            let zStr = String(format: "%.2f", n.z)
            return "{\"name\": \"\(n.id)\", \"translation\": [\(xStr), \(yStr), \(zStr)], \"extras\": {\"label\": \"\(n.label)\", \"stratum\": \"\(n.stratum)\"}}"
        }.joined(separator: ",\n    ")

        let indices = (0..<snap.nodes.count).map(String.init).joined(separator: ", ")

        let gltf = """
        {
          "asset": {
            "version": "2.0",
            "generator": "Kite Spatial3D Topology Exporter"
          },
          "scene": 0,
          "scenes": [
            {
              "name": "\(snap.sceneId)",
              "nodes": [\(indices)]
            }
          ],
          "nodes": [
            \(gltfNodes)
          ]
        }
        """

        return GltfExportBundle(formatVersion: "glTF-2.0", nodeCount: snap.nodes.count, gltfJson: gltf)
    }

    private static func stratumElevationZ(_ stratum: String) -> Double {
        if stratum.hasPrefix("Z0") { return 0.0 }
        if stratum.hasPrefix("Z1") { return -40.0 }
        if stratum.hasPrefix("Z2") { return -80.0 }
        if stratum.hasPrefix("Z3") { return -120.0 }
        return -160.0
    }
}
