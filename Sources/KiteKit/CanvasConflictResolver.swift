import Foundation

public struct CanvasMergeResult: Sendable {
    public var frames: [CanvasFrame]
    public var stickies: [CanvasSticky]
    public var referenceCards: [CanvasReferenceCard]
    public var connections: [CanvasConnection]
    public var addedNodesCount: Int
    public var addedConnectionsCount: Int

    public init(
        frames: [CanvasFrame],
        stickies: [CanvasSticky],
        referenceCards: [CanvasReferenceCard],
        connections: [CanvasConnection],
        addedNodesCount: Int,
        addedConnectionsCount: Int
    ) {
        self.frames = frames
        self.stickies = stickies
        self.referenceCards = referenceCards
        self.connections = connections
        self.addedNodesCount = addedNodesCount
        self.addedConnectionsCount = addedConnectionsCount
    }
}

public enum CanvasConflictResolver {
    public static func merge(
        localFrames: [CanvasFrame],
        localStickies: [CanvasSticky],
        localReferenceCards: [CanvasReferenceCard],
        localConnections: [CanvasConnection],
        remote: CanvasExportModel
    ) -> CanvasMergeResult {
        var mergedFrames = localFrames
        var addedNodes = 0
        var addedConnections = 0

        // 1. Merge Frames: add new remote frames
        for rFrame in remote.frames {
            if !mergedFrames.contains(where: { $0.id == rFrame.id }) {
                mergedFrames.append(rFrame)
                addedNodes += 1
            }
        }

        // 2. Merge Stickies: add new remote stickies
        var mergedStickies = localStickies
        for rSticky in remote.stickies {
            if !mergedStickies.contains(where: { $0.id == rSticky.id }) {
                mergedStickies.append(rSticky)
                addedNodes += 1
            }
        }

        // 3. Merge Reference Cards: match by ID or URL
        var mergedRefs = localReferenceCards
        for rRef in remote.referenceCards {
            if !mergedRefs.contains(where: { $0.id == rRef.id || (!rRef.url.isEmpty && $0.url == rRef.url) }) {
                mergedRefs.append(rRef)
                addedNodes += 1
            }
        }

        // 4. Merge Connections: preserve local, add remote if endpoints exist
        var mergedConnections = localConnections
        for rConn in remote.connections {
            let alreadyExists = mergedConnections.contains(where: {
                $0.id == rConn.id || ($0.fromId == rConn.fromId && $0.toId == rConn.toId)
            })
            if !alreadyExists {
                mergedConnections.append(rConn)
                addedConnections += 1
            }
        }

        return CanvasMergeResult(
            frames: mergedFrames,
            stickies: mergedStickies,
            referenceCards: mergedRefs,
            connections: mergedConnections,
            addedNodesCount: addedNodes,
            addedConnectionsCount: addedConnections
        )
    }
}
