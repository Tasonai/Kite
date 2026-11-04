import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct CanvasSticky: Identifiable, Sendable, Equatable, Codable {
    let id: UUID
    var text: String
    var colorHex: String
    var position: CGPoint

    init(id: UUID = UUID(), text: String, colorHex: String, position: CGPoint) {
        self.id = id
        self.text = text
        self.colorHex = colorHex
        self.position = position
    }
}

struct CanvasConnection: Identifiable, Sendable, Equatable, Codable {
    let id: UUID
    let fromId: String
    let toId: String
    var label: String
    var colorHex: String

    init(id: UUID = UUID(), fromId: String, toId: String, label: String = "", colorHex: String = "#D97757") {
        self.id = id
        self.fromId = fromId
        self.toId = toId
        self.label = label
        self.colorHex = colorHex
    }
}

struct InfiniteCanvasView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query private var items: [Item]

    // Pan & Zoom State
    @State private var offset: CGSize = CGSize(width: 80, height: 60)
    @State private var currentDragTranslation: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0

    // Node Positions map (Item UUID -> CGPoint)
    @State private var itemPositions: [UUID: CGPoint] = [:]
    @State private var draggedItemId: UUID?
    @State private var itemDragOffset: CGSize = .zero

    // Stickies
    @State private var stickies: [CanvasSticky] = [
        CanvasSticky(text: "⚡️ Архитектурный контраст: отказ от серого слопа", colorHex: "#FEF08A", position: CGPoint(x: 560, y: 120)),
        CanvasSticky(text: "📱 44px Touch Targets & Apple HIG 4pt Grid", colorHex: "#BBF7D0", position: CGPoint(x: 560, y: 360)),
        CanvasSticky(text: "🪄 Zero-latency нативный отклик SwiftData", colorHex: "#DDD6FE", position: CGPoint(x: 160, y: 440))
    ]
    @State private var draggedStickyId: UUID?
    @State private var stickyDragOffset: CGSize = .zero

    // Connections between ideas & stickies
    @State private var connections: [CanvasConnection] = []
    @State private var isConnectingMode: Bool = false
    @State private var connectingSourceId: String? = nil
    @State private var selectedConnectionId: UUID? = nil
    @State private var editingLabelConnId: UUID? = nil
    @State private var tempConnLabel: String = ""

    // Export notification toast
    @State private var exportToast: String? = nil

    var body: some View {
        ZStack {
            // Background Dot Grid
            CanvasGridBackground(offset: totalOffset, scale: zoomScale)
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            currentDragTranslation = val.translation
                        }
                        .onEnded { val in
                            offset.width += val.translation.width
                            offset.height += val.translation.height
                            currentDragTranslation = .zero
                        }
                )

            // Zoomed and Panned World
            ZStack(alignment: .topLeading) {
                // Connection Lines (Rendered below cards)
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

                // Stickies
                ForEach(stickies) { sticky in
                    stickyView(sticky)
                }

                // SwiftData Idea Cards
                ForEach(items) { item in
                    ideaCard(item)
                }
            }
            .scaleEffect(zoomScale, anchor: .center)
            .offset(totalOffset) // grid: ok canvas pan offset

            // Top Floating Canvas Controls & HUD
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.split.3x3")
                            .foregroundStyle(Color.accentColor)
                        Text("Холст идей")
                            .font(.headline)
                        Text("\(items.count + stickies.count) объектов")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Connect Mode Toggle Button
                    Button {
                        isConnectingMode.toggle()
                        connectingSourceId = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isConnectingMode ? "xmark.circle.fill" : "link.badge.plus")
                            Text(isConnectingMode ? "Отмена связи" : "Связать")
                        }
                        .font(.caption)
                        .foregroundStyle(isConnectingMode ? Color.white : Color.primary)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isConnectingMode ? .orange : .secondary)

                    // Add Sticky Button
                    Button {
                        addSticky()
                    } label: {
                        Label("+ Стикер", systemImage: "note.text.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    // Add Idea Button
                    Button {
                        addNewIdea()
                    } label: {
                        Label("+ Идея", systemImage: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    // Export Menu (Feature 2)
                    Menu {
                        Button {
                            exportAsSVG()
                        } label: {
                            Label("Векторный SVG (.svg)", systemImage: "chevron.left.forwardslash.chevron.right")
                        }

                        Button {
                            exportAsPNG()
                        } label: {
                            Label("Изображение PNG (.png)", systemImage: "photo")
                        }

                        Button {
                            exportAsPDF()
                        } label: {
                            Label("Векторный PDF (.pdf)", systemImage: "doc.richtext")
                        }

                        Divider()

                        Button {
                            copyPNGToClipboard()
                        } label: {
                            Label("Скопировать в буфер (PNG)", systemImage: "doc.on.doc")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Экспорт")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    // Zoom Controls
                    HStack(spacing: 4) {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                zoomScale = max(0.4, zoomScale - 0.15)
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)

                        Text("\(Int(zoomScale * 100))%")
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 44)

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                zoomScale = min(2.0, zoomScale + 0.15)
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)

                        Button("100%") {
                            withAnimation(.easeOut(duration: 0.2)) {
                                zoomScale = 1.0
                                offset = CGSize(width: 80, height: 60)
                            }
                        }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                // Connecting Helper Banner
                if isConnectingMode {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.orange)
                        Text(connectingSourceId == nil ? "Кликните на первую карточку или стикер" : "Теперь кликните на целевой узел для соединения стрелкой")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)

                        Spacer()

                        Button("Отмена") {
                            isConnectingMode = false
                            connectingSourceId = nil
                        }
                        .font(.caption2)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Toast Notification
                if let toast = exportToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(toast)
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            .padding(16)
        }
        .onAppear {
            initializePositionsIfNeeded()
            setupInitialConnectionsIfNeeded()
        }
    }

    private var totalOffset: CGSize {
        CGSize(
            width: offset.width + currentDragTranslation.width,
            height: offset.height + currentDragTranslation.height
        )
    }

    private func positionFor(item: Item, index: Int) -> CGPoint {
        if let pos = itemPositions[item.uuid] {
            if draggedItemId == item.uuid {
                return CGPoint(x: pos.x + itemDragOffset.width, y: pos.y + itemDragOffset.height)
            }
            return pos
        }
        // Auto-arrange in staggered grid
        let col = index % 3
        let row = index / 3
        return CGPoint(x: 160 + col * 320, y: 160 + row * 240)
    }

    private func ideaCard(_ item: Item) -> some View {
        let index = items.firstIndex(where: { $0.uuid == item.uuid }) ?? 0
        let pos = positionFor(item: item, index: index)
        let nodeId = "item-\(item.uuid.uuidString)"
        let isConnectingSource = connectingSourceId == nodeId

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: item.status == "completed" ? "checkmark.circle.fill" : (item.status == "in_progress" ? "bolt.circle.fill" : "circle"))
                    .foregroundStyle(item.status == "completed" ? Color.green : (item.status == "in_progress" ? Color.blue : Color.secondary))
                    .font(.caption)

                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if item.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }

            if !item.concept.isEmpty {
                Text(item.concept)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack(spacing: 8) {
                Text(item.platform)
                    .font(.system(size: 9, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())

                Text(item.style)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Button {
                    model.selection = item.id
                    model.sidebar = .all
                } label: {
                    Image(systemName: "arrow.up.right.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isConnectingSource ? Color.orange : Color.secondary.opacity(0.2), lineWidth: isConnectingSource ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        .position(pos) // grid: ok canvas dynamic position
        .onTapGesture {
            handleNodeTap(nodeId: nodeId)
        }
        .gesture(
            DragGesture()
                .onChanged { val in
                    guard !isConnectingMode else { return }
                    draggedItemId = item.uuid
                    itemDragOffset = val.translation
                }
                .onEnded { val in
                    guard !isConnectingMode else { return }
                    let cur = itemPositions[item.uuid] ?? pos
                    itemPositions[item.uuid] = CGPoint(x: cur.x + val.translation.width, y: cur.y + val.translation.height)
                    draggedItemId = nil
                    itemDragOffset = .zero
                }
        )
    }

    private func stickyView(_ sticky: CanvasSticky) -> some View {
        let isDragged = draggedStickyId == sticky.id
        let pos = CGPoint(
            x: sticky.position.x + (isDragged ? stickyDragOffset.width : 0),
            y: sticky.position.y + (isDragged ? stickyDragOffset.height : 0)
        )
        let nodeId = "sticky-\(sticky.id.uuidString)"
        let isConnectingSource = connectingSourceId == nodeId

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Spacer()
                Button {
                    stickies.removeAll(where: { $0.id == sticky.id })
                    connections.removeAll(where: { $0.fromId == nodeId || $0.toId == nodeId })
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.caption2)
                        .foregroundStyle(Color.black.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            Text(sticky.text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#1C1B18"))
                .lineSpacing(3)
        }
        .padding(16)
        .frame(width: 200, height: 160, alignment: .topLeading)
        .background(Color(hex: sticky.colorHex))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isConnectingSource ? Color.orange : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .position(pos) // grid: ok canvas dynamic position
        .onTapGesture {
            handleNodeTap(nodeId: nodeId)
        }
        .gesture(
            DragGesture()
                .onChanged { val in
                    guard !isConnectingMode else { return }
                    draggedStickyId = sticky.id
                    stickyDragOffset = val.translation
                }
                .onEnded { val in
                    guard !isConnectingMode else { return }
                    if let idx = stickies.firstIndex(where: { $0.id == sticky.id }) {
                        stickies[idx].position = CGPoint(
                            x: sticky.position.x + val.translation.width,
                            y: sticky.position.y + val.translation.height
                        )
                    }
                    draggedStickyId = nil
                    stickyDragOffset = .zero
                }
        )
    }

    private func handleNodeTap(nodeId: String) {
        guard isConnectingMode else { return }
        if connectingSourceId == nil {
            connectingSourceId = nodeId
        } else if let source = connectingSourceId, source != nodeId {
            let newConn = CanvasConnection(
                fromId: source,
                toId: nodeId,
                label: "архитектура",
                colorHex: "#D97757"
            )
            connections.append(newConn)
            connectingSourceId = nil
            isConnectingMode = false
            showToast("Связь успешно создана 🔗")
        }
    }

    // Dynamic Bézier Connection Line & Arrowhead
    private func connectionLineView(_ conn: CanvasConnection) -> some View {
        let isSelected = selectedConnectionId == conn.id

        guard let start = centerForNode(conn.fromId),
              let end = centerForNode(conn.toId) else {
            return AnyView(EmptyView())
        }

        let dx = end.x - start.x
        let dy = end.y - start.y

        // Smart edge offsets so curves start/end at card borders rather than deep centers
        let startPt: CGPoint
        let endPt: CGPoint

        if abs(dx) > abs(dy) {
            startPt = CGPoint(x: start.x + (dx > 0 ? 100 : -100), y: start.y)
            endPt = CGPoint(x: end.x + (dx > 0 ? -100 : 100), y: end.y)
        } else {
            startPt = CGPoint(x: start.x, y: start.y + (dy > 0 ? 70 : -70))
            endPt = CGPoint(x: end.x, y: end.y + (dy > 0 ? -70 : 70))
        }

        let midPt = CGPoint(x: (startPt.x + endPt.x) / 2, y: (startPt.y + endPt.y) / 2)

        return AnyView(
            ZStack {
                // Curved Path
                Path { path in
                    path.move(to: startPt)
                    let cdx = (endPt.x - startPt.x) * 0.5
                    path.addCurve(
                        to: endPt,
                        control1: CGPoint(x: startPt.x + cdx, y: startPt.y),
                        control2: CGPoint(x: endPt.x - cdx, y: endPt.y)
                    )
                }
                .stroke(
                    isSelected ? Color.orange : Color(hex: conn.colorHex),
                    style: StrokeStyle(lineWidth: isSelected ? 3 : 2, dash: [6, 4])
                )

                // Arrow Head at end
                ArrowHead(at: endPt, from: CGPoint(x: endPt.x - (dx > 0 ? 20 : -20), y: endPt.y))
                    .fill(isSelected ? Color.orange : Color(hex: conn.colorHex))

                // Connection Label / Interaction Badge
                HStack(spacing: 4) {
                    if !conn.label.isEmpty {
                        Text(conn.label)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.primary)
                    }

                    if isSelected {
                        Button {
                            connections.removeAll(where: { $0.id == conn.id })
                            selectedConnectionId = nil
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.orange : Color(hex: conn.colorHex).opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                .position(midPt) // grid: ok connection mid badge position
                .onTapGesture {
                    selectedConnectionId = (selectedConnectionId == conn.id ? nil : conn.id)
                }
            }
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
        } else if nodeId.hasPrefix("item-") {
            let raw = String(nodeId.dropFirst("item-".count))
            guard let uuid = UUID(uuidString: raw),
                  let item = items.first(where: { $0.uuid == uuid }) else { return nil }
            let index = items.firstIndex(where: { $0.uuid == item.uuid }) ?? 0
            return positionFor(item: item, index: index)
        }
        return nil
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
        if let firstItem = items.first {
            connections.append(
                CanvasConnection(
                    fromId: "item-\(firstItem.uuid.uuidString)",
                    toId: "sticky-\(stickies[0].id.uuidString)",
                    label: "дизайн-токены",
                    colorHex: "#D97757"
                )
            )
        }
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
        showToast("Стикер добавлен на холст 📝")
    }

    private func addNewIdea() {
        model.addItem(
            title: "Идея на холсте",
            concept: "Спроектируйте архитектуру визуально на холсте.",
            platform: "Web",
            style: "Linear & DevTool Cockpit"
        )
        showToast("Идея создана 💡")
    }

    // Export Helpers (Feature 2)
    private func exportAsSVG() {
        let svg = CanvasExporter.exportSVG(items: items, itemPositions: itemPositions, stickies: stickies, connections: connections)
        if let data = svg.data(using: .utf8) {
            CanvasExporter.saveWithPanel(data: data, defaultFilename: "kite-canvas-architecture.svg", fileExtension: "svg")
            showToast("Экспорт в SVG выполнен! 📐")
        }
    }

    private func exportAsPNG() {
        if let img = CanvasExporter.exportPNG(items: items, itemPositions: itemPositions, stickies: stickies, connections: connections),
           let tiff = img.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let pngData = rep.representation(using: .png, properties: [:]) {
            CanvasExporter.saveWithPanel(data: pngData, defaultFilename: "kite-canvas-preview.png", fileExtension: "png")
            showToast("Экспорт в PNG выполнен! 🖼️")
        }
    }

    private func exportAsPDF() {
        if let pdfData = CanvasExporter.exportPDF(items: items, itemPositions: itemPositions, stickies: stickies, connections: connections) {
            CanvasExporter.saveWithPanel(data: pdfData, defaultFilename: "kite-canvas-document.pdf", fileExtension: "pdf")
            showToast("Экспорт в PDF выполнен! 📄")
        }
    }

    private func copyPNGToClipboard() {
        CanvasExporter.copyPNGToClipboard(items: items, itemPositions: itemPositions, stickies: stickies, connections: connections)
        showToast("Скопировано в буфер обмена 📋")
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

// Arrow Head Shape
struct ArrowHead: Shape {
    let at: CGPoint
    let from: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let angle = atan2(at.y - from.y, at.x - from.x)
        let arrowLength: CGFloat = 12
        let arrowWidth: CGFloat = 8

        let p1 = CGPoint(
            x: at.x - arrowLength * cos(angle) + arrowWidth * sin(angle),
            y: at.y - arrowLength * sin(angle) - arrowWidth * cos(angle)
        )
        let p2 = CGPoint(
            x: at.x - arrowLength * cos(angle) - arrowWidth * sin(angle),
            y: at.y - arrowLength * sin(angle) + arrowWidth * cos(angle)
        )

        path.move(to: at)
        path.addLine(to: p1)
        path.addLine(to: p2)
        path.closeSubpath()
        return path
    }
}

// Background Dot Matrix
struct CanvasGridBackground: View {
    let offset: CGSize
    let scale: CGFloat

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let spacing: CGFloat = 24 * max(0.5, scale)
                let xOffset = offset.width.truncatingRemainder(dividingBy: spacing)
                let yOffset = offset.height.truncatingRemainder(dividingBy: spacing)

                var x = xOffset - spacing
                while x < size.width + spacing {
                    var y = yOffset - spacing
                    while y < size.height + spacing {
                        let rect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                        context.fill(Path(ellipseIn: rect), with: .color(Color.secondary.opacity(0.18)))
                        y += spacing
                    }
                    x += spacing
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
