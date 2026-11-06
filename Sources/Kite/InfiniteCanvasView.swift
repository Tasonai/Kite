import AppKit
import SwiftData
import SwiftUI
import KiteKit

enum CanvasTool: String, CaseIterable, Identifiable {
    case select = "Выбор"
    case pan = "Рука"
    var id: String { rawValue }
}

struct InfiniteCanvasView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Query private var items: [Item]

    // Pan & Zoom State
    @State private var offset: CGSize = CGSize(width: 80, height: 60)
    @State private var currentDragTranslation: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0

    // Node Positions map (Item UUID -> CGPoint)
    @State private var itemPositions: [UUID: CGPoint] = [:]
    @State private var draggedItemId: UUID?
    @State private var itemDragOffset: CGSize = .zero

    // Frames
    @State private var frames: [CanvasFrame] = [
        CanvasFrame(
            title: "Архитектурные принципы и UI/UX",
            colorHex: "#3B82F6",
            x: 480,
            y: 40,
            width: 440,
            height: 520
        )
    ]
    @State private var draggedFrameId: UUID?
    @State private var frameDragOffset: CGSize = .zero

    // Reference Cards
    @State private var referenceCards: [CanvasReferenceCard] = [
        CanvasReferenceCard(
            title: "Linear Navigation & Command HUD",
            source: "Mobbin",
            url: "https://mobbin.com",
            colorHex: "#10B981",
            position: CGPoint(x: 200, y: 180),
            tags: ["Shortcuts", "Ergonomics", "Dark Mode"],
            description: "Референс компактной навигации и быстрого доступа через клавиши."
        )
    ]
    @State private var draggedRefCardId: UUID?
    @State private var refCardDragOffset: CGSize = .zero
    @State private var isReferencePickerOpen: Bool = false

    // Stickies
    @State private var stickies: [CanvasSticky] = [
        CanvasSticky(text: "Архитектурный контраст: отказ от серого слопа", colorHex: "#FEF08A", position: CGPoint(x: 600, y: 140)),
        CanvasSticky(text: "44px Touch Targets & Apple HIG 4pt Grid", colorHex: "#BBF7D0", position: CGPoint(x: 600, y: 380)),
        CanvasSticky(text: "Zero-latency нативный отклик SwiftData", colorHex: "#DDD6FE", position: CGPoint(x: 200, y: 440))
    ]
    @State private var draggedStickyId: UUID?
    @State private var stickyDragOffset: CGSize = .zero

    // Connections between nodes
    @State private var connections: [CanvasConnection] = []
    @State private var isConnectingMode: Bool = false
    @State private var connectingSourceId: String? = nil
    @State private var selectedConnectionId: UUID? = nil
    @State private var editingConnectionId: UUID? = nil
    @State private var editingConnectionText: String = ""

    // Live Data Flow Simulation
    @State private var isSimulationActive: Bool = false

    // Notification toast
    @State private var exportToast: String? = nil

    // Canvas interaction mode & multi-selection
    @State private var canvasTool: CanvasTool = .select
    @State private var selectedElementIds: Set<String> = []
    @State private var marqueeStart: CGPoint? = nil
    @State private var marqueeCurrent: CGPoint? = nil
    @State private var isMarqueeActive: Bool = false
    @State private var groupDragOffset: CGSize = .zero
    @State private var isDraggingSelection: Bool = false

    // LAN P2P collaboration
    @State private var lanPeers: [KitePeer] = []

    var body: some View {
        ZStack {
            // Background Dot Grid
            CanvasGridBackground(offset: totalOffset, scale: zoomScale)
                .ignoresSafeArea()

            // Zoomed and Panned World
            ZStack(alignment: .topLeading) {
                // 0. World Backdrop (Marquee drag & click to deselect)
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: 8000, height: 8000)
                    .position(x: 4000, y: 4000) // grid: ok canvas world backdrop
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { val in
                                if canvasTool == .select {
                                    isMarqueeActive = true
                                    if marqueeStart == nil {
                                        marqueeStart = val.startLocation
                                    }
                                    marqueeCurrent = val.location
                                    updateMarqueeSelection()
                                } else {
                                    currentDragTranslation = val.translation
                                }
                            }
                            .onEnded { val in
                                if canvasTool == .select {
                                    isMarqueeActive = false
                                    marqueeStart = nil
                                    marqueeCurrent = nil
                                } else {
                                    offset.width += val.translation.width
                                    offset.height += val.translation.height
                                    currentDragTranslation = .zero
                                }
                            }
                    )
                    .onTapGesture {
                        selectedElementIds.removeAll()
                        selectedConnectionId = nil
                    }

                // Visual Marquee Selection Rectangle
                if isMarqueeActive, let start = marqueeStart, let cur = marqueeCurrent {
                    let minX = min(start.x, cur.x)
                    let minY = min(start.y, cur.y)
                    let w = max(2, abs(cur.x - start.x))
                    let h = max(2, abs(cur.y - start.y))

                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        .background(Color.accentColor.opacity(0.12))
                        .frame(width: w, height: h)
                        .position(x: minX + w / 2, y: minY + h / 2) // grid: ok marquee rect position
                }

                // 1. Frames rendered in the back layer
                ForEach(frames) { frame in
                    frameView(frame)
                }

                // 2. Connection Lines (Rendered below cards)
                ForEach(connections) { conn in
                    connectionLineView(conn)
                }

                // Temporary line while connecting
                if let src = connectingSourceId, let srcPoint = centerForNode(src) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .position(srcPoint) // grid: ok canvas source indicator
                }

                // 3. Reference Cards from Mobbin / Figma
                ForEach(referenceCards) { ref in
                    referenceCardView(ref)
                }

                // 4. Stickies
                ForEach(stickies) { sticky in
                    stickyView(sticky)
                }

                // 5. SwiftData Idea Cards
                ForEach(items) { item in
                    ideaCard(item)
                }
            }
            .scaleEffect(zoomScale, anchor: .center)
            .offset(totalOffset) // grid: ok canvas pan offset
            .onDeleteCommand {
                if !selectedElementIds.isEmpty {
                    deleteSelectedElements()
                } else if let sel = selectedConnectionId {
                    connections.removeAll(where: { $0.id == sel })
                    selectedConnectionId = nil
                    showToast("Связь удалена")
                }
            }

            // Top Floating Canvas Controls & HUD
            CanvasToolbarView(
                totalElementCount: items.count + stickies.count + referenceCards.count,
                canvasTool: $canvasTool,
                isConnectingMode: $isConnectingMode,
                connectingSourceId: connectingSourceId,
                selectedElementCount: selectedElementIds.count,
                lanPeers: lanPeers,
                zoomScale: $zoomScale,
                toastMessage: exportToast,
                isSimulationActive: $isSimulationActive,
                onAIAutoLayout: { performAIAutoLayout() },
                onCoArchitect: { applyCoArchitect() },
                onRepoIngestion: { applyRepoIngestion() },
                onRoadmapHUD: { applyRoadmapHUD() },
                onAddFrame: { addFrame() },
                onAddSticky: { addSticky() },
                onAddNewIdea: { addNewIdea() },
                onOpenReferencePicker: { isReferencePickerOpen = true },
                onGroupSelected: { groupSelectedElements() },
                onDeleteSelected: { deleteSelectedElements() },
                onSyncPeer: { peer in pullFromPeer(peer) },
                onExportSVG: { exportAsSVG() },
                onExportPNG: { exportAsPNG() },
                onExportPDF: { exportAsPDF() },
                onExportHTML: { exportAsHTML() },
                onExportMermaid: { exportAsMermaid() },
                onCopyPNG: { copyPNGToClipboard() },
                onResetZoom: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        zoomScale = 1.0
                        offset = CGSize(width: 80, height: 60)
                    }
                },
                onCancelConnecting: {
                    isConnectingMode = false
                    connectingSourceId = nil
                }
            )
        }
        .sheet(isPresented: $isReferencePickerOpen) {
            CanvasReferencePickerSheet(
                onSelect: { card in
                    referenceCards.append(card)
                    isReferencePickerOpen = false
                    showToast("Референс добавлен на холст")
                },
                onDismiss: {
                    isReferencePickerOpen = false
                }
            )
        }
        .onAppear {
            initializePositionsIfNeeded()
            setupInitialConnectionsIfNeeded()
            KiteLANBeacon.shared.onPeersChanged = { peers in
                Task { @MainActor in
                    self.lanPeers = peers
                }
            }
            self.lanPeers = KiteLANBeacon.shared.activePeers
        }
    }

    private var totalOffset: CGSize {
        CGSize(
            width: offset.width + currentDragTranslation.width,
            height: offset.height + currentDragTranslation.height
        )
    }

    // MARK: - Node Views
    private func frameView(_ frame: CanvasFrame) -> some View {
        let nodeId = "frame-\(frame.id.uuidString)"
        let isSelected = selectedElementIds.contains(nodeId)
        let isDragged = draggedFrameId == frame.id
        let isElementInGroup = isDraggingSelection && isSelected

        return CanvasFrameNodeView(
            frame: frame,
            isSelected: isSelected,
            isDragged: isDragged,
            isElementInGroup: isElementInGroup,
            groupDragOffset: groupDragOffset,
            frameDragOffset: frameDragOffset,
            onTap: { handleNodeTap(nodeId: nodeId) },
            onDelete: {
                frames.removeAll(where: { $0.id == frame.id })
                selectedElementIds.remove(nodeId)
            },
            onDragChanged: { val in
                if selectedElementIds.contains(nodeId) && selectedElementIds.count > 1 {
                    isDraggingSelection = true
                    groupDragOffset = val.translation
                } else {
                    draggedFrameId = frame.id
                    frameDragOffset = val.translation
                }
            },
            onDragEnded: { val in
                if selectedElementIds.contains(nodeId) && selectedElementIds.count > 1 {
                    applyGroupDragDelta(dx: val.translation.width, dy: val.translation.height)
                    isDraggingSelection = false
                    groupDragOffset = .zero
                } else {
                    if let idx = frames.firstIndex(where: { $0.id == frame.id }) {
                        let dx = val.translation.width
                        let dy = val.translation.height

                        frames[idx].x += dx
                        frames[idx].y += dy

                        let box = frame.rect
                        for (itemId, pos) in itemPositions where box.contains(pos) {
                            itemPositions[itemId] = CGPoint(x: pos.x + dx, y: pos.y + dy)
                        }
                        for sIdx in stickies.indices where box.contains(stickies[sIdx].position) {
                            stickies[sIdx].position = CGPoint(x: stickies[sIdx].position.x + dx, y: stickies[sIdx].position.y + dy)
                        }
                        for rIdx in referenceCards.indices where box.contains(referenceCards[rIdx].position) {
                            referenceCards[rIdx].position = CGPoint(x: referenceCards[rIdx].position.x + dx, y: referenceCards[rIdx].position.y + dy)
                        }
                    }
                    draggedFrameId = nil
                    frameDragOffset = .zero
                }
            }
        )
    }

    private func referenceCardView(_ ref: CanvasReferenceCard) -> some View {
        let nodeId = "ref-\(ref.id.uuidString)"
        let isSelected = selectedElementIds.contains(nodeId)
        let isDragged = draggedRefCardId == ref.id
        let isElementInGroup = isDraggingSelection && isSelected

        return CanvasReferenceNodeView(
            ref: ref,
            isSelected: isSelected,
            isDragged: isDragged,
            isElementInGroup: isElementInGroup,
            isConnectingSource: connectingSourceId == nodeId,
            groupDragOffset: groupDragOffset,
            refCardDragOffset: refCardDragOffset,
            onTap: { handleNodeTap(nodeId: nodeId) },
            onDelete: {
                referenceCards.removeAll(where: { $0.id == ref.id })
                selectedElementIds.remove(nodeId)
                connections.removeAll(where: { $0.fromId == nodeId || $0.toId == nodeId })
            },
            onConvertToIdea: {
                model.addItem(
                    title: ref.title,
                    concept: ref.description,
                    platform: "Web",
                    style: "Linear & DevTool Cockpit"
                )
                showToast("Создан проект на базе референса")
            },
            onDragChanged: { val in
                guard !isConnectingMode else { return }
                if selectedElementIds.contains(nodeId) && selectedElementIds.count > 1 {
                    isDraggingSelection = true
                    groupDragOffset = val.translation
                } else {
                    draggedRefCardId = ref.id
                    refCardDragOffset = val.translation
                }
            },
            onDragEnded: { val in
                guard !isConnectingMode else { return }
                if selectedElementIds.contains(nodeId) && selectedElementIds.count > 1 {
                    applyGroupDragDelta(dx: val.translation.width, dy: val.translation.height)
                    isDraggingSelection = false
                    groupDragOffset = .zero
                } else {
                    if let idx = referenceCards.firstIndex(where: { $0.id == ref.id }) {
                        referenceCards[idx].position = CGPoint(
                            x: referenceCards[idx].position.x + val.translation.width,
                            y: referenceCards[idx].position.y + val.translation.height
                        )
                    }
                    draggedRefCardId = nil
                    refCardDragOffset = .zero
                }
            }
        )
    }

    private func stickyView(_ sticky: CanvasSticky) -> some View {
        let nodeId = "sticky-\(sticky.id.uuidString)"
        let isSelected = selectedElementIds.contains(nodeId)
        let isDragged = draggedStickyId == sticky.id
        let isElementInGroup = isDraggingSelection && isSelected

        return CanvasStickyNodeView(
            sticky: sticky,
            isSelected: isSelected,
            isDragged: isDragged,
            isElementInGroup: isElementInGroup,
            isConnectingSource: connectingSourceId == nodeId,
            groupDragOffset: groupDragOffset,
            stickyDragOffset: stickyDragOffset,
            onTap: { handleNodeTap(nodeId: nodeId) },
            onDelete: {
                stickies.removeAll(where: { $0.id == sticky.id })
                selectedElementIds.remove(nodeId)
                connections.removeAll(where: { $0.fromId == nodeId || $0.toId == nodeId })
            },
            onDragChanged: { val in
                guard !isConnectingMode else { return }
                if selectedElementIds.contains(nodeId) && selectedElementIds.count > 1 {
                    isDraggingSelection = true
                    groupDragOffset = val.translation
                } else {
                    draggedStickyId = sticky.id
                    stickyDragOffset = val.translation
                }
            },
            onDragEnded: { val in
                guard !isConnectingMode else { return }
                if selectedElementIds.contains(nodeId) && selectedElementIds.count > 1 {
                    applyGroupDragDelta(dx: val.translation.width, dy: val.translation.height)
                    isDraggingSelection = false
                    groupDragOffset = .zero
                } else {
                    if let idx = stickies.firstIndex(where: { $0.id == sticky.id }) {
                        stickies[idx].position = CGPoint(
                            x: stickies[idx].position.x + val.translation.width,
                            y: stickies[idx].position.y + val.translation.height
                        )
                    }
                    draggedStickyId = nil
                    stickyDragOffset = .zero
                }
            }
        )
    }

    private func positionFor(item: Item, index: Int) -> CGPoint {
        let base: CGPoint
        if let pos = itemPositions[item.uuid] {
            base = pos
        } else {
            let col = index % 3
            let row = index / 3
            base = CGPoint(x: 160 + col * 320, y: 160 + row * 240)
        }
        let nodeId = "item-\(item.uuid.uuidString)"
        if isDraggingSelection && selectedElementIds.contains(nodeId) {
            return CGPoint(x: base.x + groupDragOffset.width, y: base.y + groupDragOffset.height)
        }
        if draggedItemId == item.uuid {
            return CGPoint(x: base.x + itemDragOffset.width, y: base.y + itemDragOffset.height)
        }
        return base
    }

    private func ideaCard(_ item: Item) -> some View {
        let index = items.firstIndex(where: { $0.uuid == item.uuid }) ?? 0
        let pos = positionFor(item: item, index: index)
        let nodeId = "item-\(item.uuid.uuidString)"
        let isSelected = selectedElementIds.contains(nodeId)
        let isConnectingSource = connectingSourceId == nodeId
        let isDragged = draggedItemId == item.uuid

        return CanvasIdeaNodeView(
            item: item,
            position: pos,
            isSelected: isSelected,
            isConnectingSource: isConnectingSource,
            isDragged: isDragged,
            onTap: { handleNodeTap(nodeId: nodeId) },
            onOpenDetails: {
                model.selection = item.id
                model.sidebar = .all
            },
            onDragChanged: { val in
                guard !isConnectingMode else { return }
                if selectedElementIds.contains(nodeId) && selectedElementIds.count > 1 {
                    isDraggingSelection = true
                    groupDragOffset = val.translation
                } else {
                    draggedItemId = item.uuid
                    itemDragOffset = val.translation
                }
            },
            onDragEnded: { val in
                guard !isConnectingMode else { return }
                if selectedElementIds.contains(nodeId) && selectedElementIds.count > 1 {
                    applyGroupDragDelta(dx: val.translation.width, dy: val.translation.height)
                    isDraggingSelection = false
                    groupDragOffset = .zero
                } else {
                    let cur = itemPositions[item.uuid] ?? pos
                    itemPositions[item.uuid] = CGPoint(x: cur.x + val.translation.width, y: cur.y + val.translation.height)
                    draggedItemId = nil
                    itemDragOffset = .zero
                }
            }
        )
    }

    private func handleNodeTap(nodeId: String) {
        if isConnectingMode {
            if connectingSourceId == nil {
                connectingSourceId = nodeId
            } else if let src = connectingSourceId, src != nodeId {
                connections.append(
                    CanvasConnection(
                        fromId: src,
                        toId: nodeId,
                        label: "Связь",
                        colorHex: "#3B82F6"
                    )
                )
                connectingSourceId = nil
                isConnectingMode = false
                showToast("Связь установлена")
            }
        } else {
            if NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command) {
                if selectedElementIds.contains(nodeId) {
                    selectedElementIds.remove(nodeId)
                } else {
                    selectedElementIds.insert(nodeId)
                }
            } else {
                selectedElementIds = [nodeId]
            }
        }
    }

    // Dynamic Bézier Connection Line & Arrowhead
    private func connectionLineView(_ conn: CanvasConnection) -> some View {
        guard let start = centerForNode(conn.fromId),
              let end = centerForNode(conn.toId) else {
            return AnyView(EmptyView())
        }

        return AnyView(
            CanvasConnectionView(
                conn: conn,
                isSelected: selectedConnectionId == conn.id,
                start: start,
                end: end,
                isSimulationActive: isSimulationActive,
                isEditing: editingConnectionId == conn.id,
                editingText: $editingConnectionText,
                onStartEditing: {
                    editingConnectionId = conn.id
                    editingConnectionText = conn.label
                },
                onSubmitEditing: { newText in
                    if let idx = connections.firstIndex(where: { $0.id == conn.id }) {
                        connections[idx].label = newText
                    }
                    editingConnectionId = nil
                },
                onSelect: {
                    selectedConnectionId = (selectedConnectionId == conn.id ? nil : conn.id)
                },
                onDelete: {
                    connections.removeAll(where: { $0.id == conn.id })
                    selectedConnectionId = nil
                    showToast("Связь удалена")
                },
                onSetProtocol: { proto in
                    if let idx = connections.firstIndex(where: { $0.id == conn.id }) {
                        connections[idx].label = proto
                    }
                }
            )
        )
    }

    private func centerForNode(_ nodeId: String) -> CGPoint? {
        if nodeId.hasPrefix("sticky-") {
            let raw = String(nodeId.dropFirst("sticky-".count))
            guard let uuid = UUID(uuidString: raw),
                  let sticky = stickies.first(where: { $0.id == uuid }) else { return nil }
            let isDragged = draggedStickyId == sticky.id
            return CGPoint(
                x: sticky.position.x + (isDragged ? stickyDragOffset.width : 0),
                y: sticky.position.y + (isDragged ? stickyDragOffset.height : 0)
            )
        } else if nodeId.hasPrefix("ref-") {
            let raw = String(nodeId.dropFirst("ref-".count))
            guard let uuid = UUID(uuidString: raw),
                  let ref = referenceCards.first(where: { $0.id == uuid }) else { return nil }
            let isDragged = draggedRefCardId == ref.id
            return CGPoint(
                x: ref.position.x + (isDragged ? refCardDragOffset.width : 0),
                y: ref.position.y + (isDragged ? refCardDragOffset.height : 0)
            )
        } else if nodeId.hasPrefix("item-") {
            let raw = String(nodeId.dropFirst("item-".count))
            guard let uuid = UUID(uuidString: raw),
                  let item = items.first(where: { $0.uuid == uuid }) else { return nil }
            let index = items.firstIndex(where: { $0.uuid == item.uuid }) ?? 0
            return positionFor(item: item, index: index)
        } else if nodeId.hasPrefix("frame-") {
            let raw = String(nodeId.dropFirst("frame-".count))
            guard let uuid = UUID(uuidString: raw),
                  let frame = frames.first(where: { $0.id == uuid }) else { return nil }
            return CGPoint(x: frame.x + frame.width / 2, y: frame.y + frame.height / 2)
        }
        return nil
    }

    // MARK: - Multi-Selection & Group Operations
    private func updateMarqueeSelection() {
        guard let start = marqueeStart, let cur = marqueeCurrent else { return }
        let box = CGRect(
            x: min(start.x, cur.x),
            y: min(start.y, cur.y),
            width: abs(cur.x - start.x),
            height: abs(cur.y - start.y)
        )

        var newSel = Set<String>()
        for sticky in stickies {
            let r = CGRect(x: sticky.position.x - 100, y: sticky.position.y - 80, width: 200, height: 160)
            if box.intersects(r) { newSel.insert("sticky-\(sticky.id.uuidString)") }
        }
        for item in items {
            let pt = itemPositions[item.uuid] ?? CGPoint(x: 560, y: 200)
            let r = CGRect(x: pt.x - 140, y: pt.y - 80, width: 280, height: 160)
            if box.intersects(r) { newSel.insert("item-\(item.uuid.uuidString)") }
        }
        for ref in referenceCards {
            let r = CGRect(x: ref.position.x - 130, y: ref.position.y - 80, width: 260, height: 160)
            if box.intersects(r) { newSel.insert("ref-\(ref.id.uuidString)") }
        }
        for frame in frames {
            let r = CGRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height)
            if box.intersects(r) { newSel.insert("frame-\(frame.id.uuidString)") }
        }
        selectedElementIds = newSel
    }

    private func applyGroupDragDelta(dx: CGFloat, dy: CGFloat) {
        for id in selectedElementIds {
            if id.starts(with: "sticky-") {
                let raw = String(id.dropFirst("sticky-".count))
                if let idx = stickies.firstIndex(where: { $0.id.uuidString == raw }) {
                    stickies[idx].position = CGPoint(x: stickies[idx].position.x + dx, y: stickies[idx].position.y + dy)
                }
            } else if id.starts(with: "item-") {
                let raw = String(id.dropFirst("item-".count))
                if let uuid = UUID(uuidString: raw) {
                    let cur = itemPositions[uuid] ?? CGPoint(x: 560, y: 200)
                    itemPositions[uuid] = CGPoint(x: cur.x + dx, y: cur.y + dy)
                }
            } else if id.starts(with: "ref-") {
                let raw = String(id.dropFirst("ref-".count))
                if let idx = referenceCards.firstIndex(where: { $0.id.uuidString == raw }) {
                    referenceCards[idx].position = CGPoint(x: referenceCards[idx].position.x + dx, y: referenceCards[idx].position.y + dy)
                }
            } else if id.starts(with: "frame-") {
                let raw = String(id.dropFirst("frame-".count))
                if let idx = frames.firstIndex(where: { $0.id.uuidString == raw }) {
                    frames[idx].x += dx
                    frames[idx].y += dy
                }
            }
        }
    }

    private func deleteSelectedElements() {
        let count = selectedElementIds.count
        guard count > 0 else { return }

        for id in selectedElementIds {
            if id.starts(with: "sticky-") {
                let raw = String(id.dropFirst("sticky-".count))
                stickies.removeAll(where: { $0.id.uuidString == raw })
                connections.removeAll(where: { $0.fromId == id || $0.toId == id })
            } else if id.starts(with: "ref-") {
                let raw = String(id.dropFirst("ref-".count))
                referenceCards.removeAll(where: { $0.id.uuidString == raw })
                connections.removeAll(where: { $0.fromId == id || $0.toId == id })
            } else if id.starts(with: "frame-") {
                let raw = String(id.dropFirst("frame-".count))
                frames.removeAll(where: { $0.id.uuidString == raw })
            } else if id.starts(with: "item-") {
                let raw = String(id.dropFirst("item-".count))
                if let uuid = UUID(uuidString: raw) {
                    itemPositions.removeValue(forKey: uuid)
                }
                connections.removeAll(where: { $0.fromId == id || $0.toId == id })
            }
        }
        selectedElementIds.removeAll()
        showToast("Удалено объектов: \(count)")
    }

    private func groupSelectedElements() {
        guard !selectedElementIds.isEmpty else { return }

        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity

        for id in selectedElementIds {
            if let pt = centerForNode(id) {
                minX = min(minX, pt.x - 130)
                minY = min(minY, pt.y - 90)
                maxX = max(maxX, pt.x + 130)
                maxY = max(maxY, pt.y + 90)
            }
        }

        guard minX < CGFloat.infinity else { return }

        let newFrame = CanvasFrame(
            title: "Подсистема",
            colorHex: "#3B82F6",
            x: max(20, minX - 24),
            y: max(20, minY - 32),
            width: max(240, maxX - minX + 48),
            height: max(180, maxY - minY + 56)
        )
        frames.append(newFrame)
        showToast("Объекты объединены в подсистему")
    }

    private func pullFromPeer(_ peer: KitePeer) {
        guard let url = URL(string: "http://\(peer.ip):\(peer.port)/api/canvas") else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let doc = try JSONDecoder().decode(CanvasExportModel.self, from: data)
                await MainActor.run {
                    let result = CanvasConflictResolver.merge(
                        localFrames: self.frames,
                        localStickies: self.stickies,
                        localReferenceCards: self.referenceCards,
                        localConnections: self.connections,
                        remote: doc
                    )
                    self.frames = result.frames
                    self.stickies = result.stickies
                    self.referenceCards = result.referenceCards
                    self.connections = result.connections

                    if result.addedNodesCount > 0 || result.addedConnectionsCount > 0 {
                        showToast("Синхронизировано с \(peer.hostname): +\(result.addedNodesCount) узлов, +\(result.addedConnectionsCount) связей")
                    } else {
                        showToast("Холст актуален с \(peer.hostname)")
                    }
                }
            } catch {
                await MainActor.run {
                    showToast("Ошибка соединения с \(peer.hostname)")
                }
            }
        }
    }

    // MARK: - AI Auto-Layout
    private func performAIAutoLayout() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            // Column 1: Reference Cards (Left, x = 180)
            for (idx, _) in referenceCards.enumerated() {
                referenceCards[idx].position = CGPoint(x: 180, y: 160 + CGFloat(idx) * 220)
            }

            // Column 2: Idea Cards (Center, x = 520)
            for (idx, item) in items.enumerated() {
                itemPositions[item.uuid] = CGPoint(x: 520, y: 160 + CGFloat(idx) * 240)
            }

            // Column 3: Stickies (Right, x = 860)
            for (idx, _) in stickies.enumerated() {
                stickies[idx].position = CGPoint(x: 860, y: 160 + CGFloat(idx) * 200)
            }

            // Auto-Enclosing Frames
            let refHeight = max(400, CGFloat(max(1, referenceCards.count)) * 240 + 80)
            let ideasHeight = max(400, CGFloat(max(1, items.count)) * 260 + 80)
            let stickiesHeight = max(400, CGFloat(max(1, stickies.count)) * 220 + 80)

            frames = [
                CanvasFrame(
                    title: "1. Референсы (Mobbin & Figma)",
                    colorHex: "#10B981",
                    x: 40,
                    y: 60,
                    width: 280,
                    height: refHeight
                ),
                CanvasFrame(
                    title: "2. Архитектура и задачи (SwiftData)",
                    colorHex: "#3B82F6",
                    x: 360,
                    y: 60,
                    width: 320,
                    height: ideasHeight
                ),
                CanvasFrame(
                    title: "3. Дизайн-система и заметки",
                    colorHex: "#F59E0B",
                    x: 720,
                    y: 60,
                    width: 280,
                    height: stickiesHeight
                )
            ]
        }
        showToast("AI Auto-Layout: элементы упорядочены по смысловым фреймам")
    }

    private func addFrame() {
        let colors = ["#3B82F6", "#10B981", "#8B5CF6", "#F59E0B", "#EC4899"]
        let chosenColor = colors.randomElement() ?? "#3B82F6"
        let newFrame = CanvasFrame(
            title: "Новый спринт / Модуль",
            colorHex: chosenColor,
            x: 240,
            y: 80,
            width: 360,
            height: 380
        )
        frames.append(newFrame)
        showToast("Фрейм добавлен на холст")
    }

    private func applyCoArchitect() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            let count = CanvasCoArchitect.applyGaps(to: &frames, stickies: &stickies, connections: &connections)
            if count > 0 {
                showToast("AI Архитектор: добавлено \(count) критических модулей со связями")
            } else {
                showToast("Архитектура сбалансирована, критических пробелов не обнаружено")
            }
        }
    }

    private func applyRepoIngestion() {
        let currentFolder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let arch = CodebaseIngestion.analyze(at: currentFolder)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            frames = arch.frames
            stickies = arch.stickies
            connections = arch.connections
        }
        showToast("Импорт структуры: \(arch.name) (\(arch.projectType)) размещен на холсте")
    }

    private func applyRoadmapHUD() {
        let (rFrames, rStickies, rConnections) = RoadmapTracker.generateWaves()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            frames = rFrames
            stickies = rStickies
            connections = rConnections
        }
        showToast("Дорожная карта: волны выполнения и статус задач отображены")
    }

    private func initializePositionsIfNeeded() {
        for (idx, item) in items.enumerated() {
            if itemPositions[item.uuid] == nil {
                let col = idx % 3
                let row = idx / 3
                itemPositions[item.uuid] = CGPoint(x: 160 + col * 320, y: 160 + row * 240)
            }
        }
    }

    private func setupInitialConnectionsIfNeeded() {
        guard connections.isEmpty, stickies.count >= 2 else { return }

        // Connect first reference card to first sticky or idea
        if let firstRef = referenceCards.first, !stickies.isEmpty {
            connections.append(
                CanvasConnection(
                    fromId: "ref-\(firstRef.id.uuidString)",
                    toId: "sticky-\(stickies[0].id.uuidString)",
                    label: "UX референс",
                    colorHex: "#10B981"
                )
            )
        }

        // Link sticky 0 to sticky 1
        connections.append(
            CanvasConnection(
                fromId: "sticky-\(stickies[0].id.uuidString)",
                toId: "sticky-\(stickies[1].id.uuidString)",
                label: "HIG 4pt",
                colorHex: "#10B981"
            )
        )
        if stickies.count >= 3 {
            connections.append(
                CanvasConnection(
                    fromId: "sticky-\(stickies[2].id.uuidString)",
                    toId: "sticky-\(stickies[1].id.uuidString)",
                    label: "архитектура",
                    colorHex: "#8B5CF6"
                )
            )
        }
    }

    private func addSticky() {
        let colors = ["#FEF08A", "#FED7AA", "#BBF7D0", "#DDD6FE", "#BAE6FD"]
        let randomColor = colors.randomElement() ?? "#FEF08A"
        let newSticky = CanvasSticky(
            text: "Новая заметка: зафиксируйте идею или микро-задачу...",
            colorHex: randomColor,
            position: CGPoint(x: 360, y: 240)
        )
        stickies.append(newSticky)
        showToast("Стикер добавлен на холст")
    }

    private func addNewIdea() {
        model.addItem(
            title: "Новая архитектурная концепция",
            concept: "Опишите системный компонент или пользовательский сценарий...",
            platform: "macOS",
            style: "Apple HIG Native"
        )
        initializePositionsIfNeeded()
        showToast("Идея создана")
    }

    // MARK: - Export Helpers
    private func exportAsSVG() {
        let svg = CanvasExporter.exportSVG(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        )
        if let data = svg.data(using: .utf8) {
            CanvasExporter.saveWithPanel(data: data, defaultFilename: "kite-canvas-architecture.svg", fileExtension: "svg")
            showToast("Экспорт в SVG выполнен")
        }
    }

    private func exportAsPNG() {
        if let img = CanvasExporter.exportPNG(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        ),
           let tiff = img.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let pngData = rep.representation(using: .png, properties: [:]) {
            CanvasExporter.saveWithPanel(data: pngData, defaultFilename: "kite-canvas-preview.png", fileExtension: "png")
            showToast("Экспорт в PNG выполнен")
        }
    }

    private func exportAsPDF() {
        if let pdfData = CanvasExporter.exportPDF(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        ) {
            CanvasExporter.saveWithPanel(data: pdfData, defaultFilename: "kite-canvas-document.pdf", fileExtension: "pdf")
            showToast("Экспорт в PDF выполнен")
        }
    }

    private func exportAsHTML() {
        let html = CanvasExporter.exportHTML(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        )
        if let data = html.data(using: .utf8) {
            CanvasExporter.saveWithPanel(data: data, defaultFilename: "kite-canvas-interactive.html", fileExtension: "html")
            showToast("Экспорт в интерактивный HTML выполнен")
        }
    }

    private func exportAsMermaid() {
        let mmd = CanvasExporter.exportMermaid(items: items, connections: connections)
        if let data = mmd.data(using: .utf8) {
            CanvasExporter.saveWithPanel(data: data, defaultFilename: "kite-canvas-flowchart.mmd", fileExtension: "mmd")
            showToast("Экспорт в Mermaid выполнен")
        }
    }

    private func copyPNGToClipboard() {
        CanvasExporter.copyPNGToClipboard(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        )
        showToast("Скопировано в буфер обмена")
    }

    private func showToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            exportToast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeIn(duration: 0.2)) {
                if exportToast == message {
                    exportToast = nil
                }
            }
        }
    }
}
