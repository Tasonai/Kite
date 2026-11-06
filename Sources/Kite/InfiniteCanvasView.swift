import AppKit
import SwiftData
import SwiftUI
import KiteKit

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

    // Frames (Feature 1)
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

    // Reference Cards (Feature 3)
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

    // Connections between ideas & stickies
    @State private var connections: [CanvasConnection] = []
    @State private var isConnectingMode: Bool = false
    @State private var connectingSourceId: String? = nil
    @State private var selectedConnectionId: UUID? = nil

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

            // Top Floating Canvas Controls & HUD
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.split.3x3")
                            .foregroundStyle(Color.accentColor)
                        Text("Холст")
                            .font(.headline)
                            .fixedSize()
                        Text("\(items.count + stickies.count + referenceCards.count)")
                            .font(.system(size: 10, design: .monospaced)) // grid: ok font
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .fixedSize()

                    Spacer(minLength: 8)

                    // AI Architecture Tools Menu
                    Menu {
                        Button {
                            performAIAutoLayout()
                        } label: {
                            Label("AI-Раскладка секций", systemImage: "wand.and.stars")
                        }

                        Button {
                            applyCoArchitect()
                        } label: {
                            Label("AI Ко-Архитектор (пробелы и защита)", systemImage: "cpu")
                        }

                        Button {
                            applyRepoIngestion()
                        } label: {
                            Label("Импорт структуры репозитория", systemImage: "square.stack.3d.down.right")
                        }

                        Button {
                            applyRoadmapHUD()
                        } label: {
                            Label("Дорожная карта (волны выполнения)", systemImage: "chart.bar.xaxis")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                            Text("AI Архитектор")
                        }
                        .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .fixedSize()
                    .help("Инструменты AI-проектирования: авто-раскладка, аудит пробелов, дорожная карта")

                    // Add Elements Menu
                    Menu {
                        Button {
                            addFrame()
                        } label: {
                            Label("Фрейм", systemImage: "squareshape.dashed.squareshape")
                        }

                        Button {
                            addSticky()
                        } label: {
                            Label("Стикер", systemImage: "note.text.badge.plus")
                        }

                        Button {
                            addNewIdea()
                        } label: {
                            Label("Идея", systemImage: "plus")
                        }

                        Button {
                            isReferencePickerOpen = true
                        } label: {
                            Label("Референс (Mobbin / Figma)", systemImage: "photo.on.rectangle.angled")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Добавить")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .fixedSize()

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
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isConnectingMode ? Color.orange : Color.secondary.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    // Export Menu
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

                        Button {
                            exportAsHTML()
                        } label: {
                            Label("Интерактивный HTML (.html)", systemImage: "safari")
                        }

                        Button {
                            exportAsMermaid()
                        } label: {
                            Label("Диаграмма Mermaid (.mmd)", systemImage: "arrow.triangle.branch")
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
                            .font(.system(size: 11, design: .monospaced)) // grid: ok font
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                // Connecting Helper Banner
                if isConnectingMode {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.orange)
                        Text(connectingSourceId == nil ? "Кликните на первую карточку, стикер или референс" : "Теперь выберите целевой узел для соединения стрелкой")
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
        }
    }

    private var totalOffset: CGSize {
        CGSize(
            width: offset.width + currentDragTranslation.width,
            height: offset.height + currentDragTranslation.height
        )
    }

    // MARK: - Frame View
    private func frameView(_ frame: CanvasFrame) -> some View {
        let isDragged = draggedFrameId == frame.id
        let curX = frame.x + (isDragged ? frameDragOffset.width : 0)
        let curY = frame.y + (isDragged ? frameDragOffset.height : 0)

        return VStack(alignment: .leading, spacing: 0) {
            // Frame Header Tab (Drag Handle)
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.caption2)
                Text(frame.title)
                    .font(.caption.bold())
                    .lineLimit(1)

                Spacer()

                Button {
                    frames.removeAll(where: { $0.id == frame.id })
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold)) // grid: ok icon font
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(hex: frame.colorHex))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 8))
            .gesture(
                DragGesture()
                    .onChanged { val in
                        draggedFrameId = frame.id
                        frameDragOffset = val.translation
                    }
                    .onEnded { val in
                        if let idx = frames.firstIndex(where: { $0.id == frame.id }) {
                            let dx = val.translation.width
                            let dy = val.translation.height

                            // Move frame
                            frames[idx].x += dx
                            frames[idx].y += dy

                            // Move enclosed items
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
            )

            // Frame Body Bounds
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: frame.colorHex).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: frame.colorHex).opacity(isDragged ? 0.6 : 0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                )
                .frame(width: frame.width, height: frame.height)
        }
        .scaleEffect(isDragged ? 1.01 : 1.0)
        .shadow(color: isDragged ? Color.black.opacity(0.16) : Color.clear, radius: isDragged ? 16 : 0, y: isDragged ? 8 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragged)
        .position(x: curX + frame.width / 2, y: curY + frame.height / 2) // grid: ok frame center position
    }

    // MARK: - Reference Card View
    private func referenceCardView(_ ref: CanvasReferenceCard) -> some View {
        let isDragged = draggedRefCardId == ref.id
        let pos = CGPoint(
            x: ref.position.x + (isDragged ? refCardDragOffset.width : 0),
            y: ref.position.y + (isDragged ? refCardDragOffset.height : 0)
        )
        let nodeId = "ref-\(ref.id.uuidString)"
        let isConnectingSource = connectingSourceId == nodeId

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Source Badge
                Text(ref.source)
                    .font(.system(size: 9, weight: .bold, design: .monospaced)) // grid: ok font
                    .foregroundStyle(Color(hex: ref.colorHex))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: ref.colorHex).opacity(0.16))
                    .clipShape(Capsule())

                Spacer()

                Button {
                    if let url = URL(string: ref.url) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Открыть референс в браузере")

                Button {
                    referenceCards.removeAll(where: { $0.id == ref.id })
                    connections.removeAll(where: { $0.fromId == nodeId || $0.toId == nodeId })
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(ref.title)
                .font(.headline)
                .lineLimit(2)

            Text(ref.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 4) {
                ForEach(ref.tags.prefix(3), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 9, design: .monospaced)) // grid: ok font
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    model.addItem(
                        title: ref.title,
                        concept: ref.description,
                        platform: "Web",
                        style: "Linear & DevTool Cockpit"
                    )
                    showToast("Создан проект на базе референса")
                } label: {
                    Text("В идею")
                        .font(.system(size: 9, weight: .semibold)) // grid: ok font
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 260, height: 160)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isConnectingSource ? Color.orange : Color.secondary.opacity(0.2), lineWidth: isConnectingSource ? 2 : 1)
        )
        .scaleEffect(isDragged ? 1.04 : 1.0)
        .shadow(color: isDragged ? Color.black.opacity(0.24) : Color.black.opacity(0.08), radius: isDragged ? 16 : 6, y: isDragged ? 12 : 3)
        .zIndex(isDragged ? 100 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragged)
        .position(pos) // grid: ok reference card position
        .onTapGesture {
            handleNodeTap(nodeId: nodeId)
        }
        .gesture(
            DragGesture()
                .onChanged { val in
                    guard !isConnectingMode else { return }
                    draggedRefCardId = ref.id
                    refCardDragOffset = val.translation
                }
                .onEnded { val in
                    guard !isConnectingMode else { return }
                    if let idx = referenceCards.firstIndex(where: { $0.id == ref.id }) {
                        referenceCards[idx].position = CGPoint(
                            x: ref.position.x + val.translation.width,
                            y: ref.position.y + val.translation.height
                        )
                    }
                    draggedRefCardId = nil
                    refCardDragOffset = .zero
                }
        )
    }

    private func positionFor(item: Item, index: Int) -> CGPoint {
        if let pos = itemPositions[item.uuid] {
            if draggedItemId == item.uuid {
                return CGPoint(x: pos.x + itemDragOffset.width, y: pos.y + itemDragOffset.height)
            }
            return pos
        }
        let col = index % 3
        let row = index / 3
        return CGPoint(x: 160 + col * 320, y: 160 + row * 240)
    }

    private func ideaCard(_ item: Item) -> some View {
        let index = items.firstIndex(where: { $0.uuid == item.uuid }) ?? 0
        let pos = positionFor(item: item, index: index)
        let nodeId = "item-\(item.uuid.uuidString)"
        let isConnectingSource = connectingSourceId == nodeId
        let isDragged = draggedItemId == item.uuid

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
                    .font(.system(size: 9, design: .monospaced)) // grid: ok font
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())

                Text(item.style)
                    .font(.system(size: 9)) // grid: ok font
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
        .scaleEffect(isDragged ? 1.04 : 1.0)
        .shadow(color: isDragged ? Color.black.opacity(0.24) : Color.black.opacity(0.08), radius: isDragged ? 16 : 6, y: isDragged ? 12 : 3)
        .zIndex(isDragged ? 100 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragged)
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
        .background(Color(hex: sticky.colorHex).opacity(colorScheme == .dark ? 0.88 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isConnectingSource ? Color.orange : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isDragged ? 1.05 : 1.0)
        .shadow(color: isDragged ? Color.black.opacity(0.24) : Color.black.opacity(0.1), radius: isDragged ? 16 : 4, y: isDragged ? 12 : 2)
        .zIndex(isDragged ? 100 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragged)
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
                label: "связь",
                colorHex: "#D97757"
            )
            connections.append(newConn)
            connectingSourceId = nil
            isConnectingMode = false
            showToast("Связь успешно создана")
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
                            .font(.system(size: 10, weight: .semibold, design: .monospaced)) // grid: ok font
                            .foregroundStyle(Color.primary)
                    }

                    if isSelected {
                        Button {
                            connections.removeAll(where: { $0.id == conn.id })
                            selectedConnectionId = nil
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 9)) // grid: ok font
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
        }
        return nil
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
            title: "Идея на холсте",
            concept: "Спроектируйте архитектуру визуально на холсте.",
            platform: "Web",
            style: "Linear & DevTool Cockpit"
        )
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
