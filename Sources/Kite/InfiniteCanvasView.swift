import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct CanvasSticky: Identifiable, Sendable {
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

struct CanvasConnection: Identifiable, Sendable {
    let id: UUID
    let fromId: String
    let toId: String

    init(id: UUID = UUID(), fromId: String, toId: String) {
        self.id = id
        self.fromId = fromId
        self.toId = toId
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
        CanvasSticky(text: "⚡️ Архитектурный контраст: отказ от серого слопа", colorHex: "#FEF08A", position: CGPoint(x: 520, y: 120)),
        CanvasSticky(text: "📱 44px Touch Targets & Apple HIG 4pt Grid", colorHex: "#BBF7D0", position: CGPoint(x: 520, y: 340)),
        CanvasSticky(text: "🪄 Zero-latency нативный отклик SwiftData", colorHex: "#DDD6FE", position: CGPoint(x: 160, y: 440))
    ]
    @State private var draggedStickyId: UUID?
    @State private var stickyDragOffset: CGSize = .zero

    // Connections between ideas
    @State private var connections: [CanvasConnection] = []

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
                // Connection Lines
                ForEach(connections) { conn in
                    connectionLine(from: conn.fromId, to: conn.toId)
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

            // Top Floating Canvas Controls
            VStack {
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

                    // Zoom Controls
                    HStack(spacing: 4) {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                zoomScale = max(0.5, zoomScale - 0.15)
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
                .padding(16)

                Spacer()
            }
        }
        .onAppear {
            initializePositionsIfNeeded()
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
        return CGPoint(x: 120 + col * 320, y: 120 + row * 240)
    }

    private func ideaCard(_ item: Item) -> some View {
        let index = items.firstIndex(where: { $0.uuid == item.uuid }) ?? 0
        let pos = positionFor(item: item, index: index)

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
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        .position(pos) // grid: ok canvas dynamic position
        .gesture(
            DragGesture()
                .onChanged { val in
                    draggedItemId = item.uuid
                    itemDragOffset = val.translation
                }
                .onEnded { val in
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

        return VStack(alignment: .leading, spacing: 4) {
            Text(sticky.text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#1C1B18"))
                .lineSpacing(3)
        }
        .padding(16)
        .frame(width: 200, height: 160, alignment: .topLeading)
        .background(Color(hex: sticky.colorHex))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .position(pos) // grid: ok canvas dynamic position
        .gesture(
            DragGesture()
                .onChanged { val in
                    draggedStickyId = sticky.id
                    stickyDragOffset = val.translation
                }
                .onEnded { val in
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

    private func connectionLine(from: String, to: String) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 200, y: 150))
            path.addCurve(
                to: CGPoint(x: 520, y: 180),
                control1: CGPoint(x: 360, y: 150),
                control2: CGPoint(x: 360, y: 180)
            )
        }
        .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
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

    private func addSticky() {
        let colors = ["#FEF08A", "#FED7AA", "#BBF7D0", "#DDD6FE", "#BAE6FD"]
        let randomColor = colors.randomElement() ?? "#FEF08A"
        let newSticky = CanvasSticky(
            text: "Новая заметка: зафиксируйте идею или микро-задачу...",
            colorHex: randomColor,
            position: CGPoint(x: 360, y: 240)
        )
        stickies.append(newSticky)
    }

    private func addNewIdea() {
        model.addItem(
            title: "Идея на холсте",
            concept: "Спроектируйте архитектуру визуально на холсте.",
            platform: "Web",
            style: "Linear & DevTool Cockpit"
        )
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
