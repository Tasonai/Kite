import AppKit
import SwiftUI
import KiteKit

// MARK: - Frame Node View
struct CanvasFrameNodeView: View {
    let frame: CanvasFrame
    let isSelected: Bool
    let isDragged: Bool
    let isElementInGroup: Bool
    let groupDragOffset: CGSize
    let frameDragOffset: CGSize
    let onTap: () -> Void
    let onDelete: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var body: some View {
        let curX = frame.x + (isElementInGroup ? groupDragOffset.width : (isDragged ? frameDragOffset.width : 0))
        let curY = frame.y + (isElementInGroup ? groupDragOffset.height : (isDragged ? frameDragOffset.height : 0))

        VStack(alignment: .leading, spacing: 0) {
            // Frame Header Tab (Drag Handle)
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.caption2)
                Text(frame.title)
                    .font(.caption.bold())
                    .lineLimit(1)

                Spacer()

                Button {
                    onDelete()
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
            .onTapGesture {
                onTap()
            }
            .gesture(
                DragGesture()
                    .onChanged(onDragChanged)
                    .onEnded(onDragEnded)
            )

            // Frame Body Bounds
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: frame.colorHex).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.accentColor : Color(hex: frame.colorHex).opacity(isDragged ? 0.6 : 0.35), style: StrokeStyle(lineWidth: isSelected ? 2 : (isDragged ? 2 : 1), dash: isSelected ? [] : [6, 4]))
                )
                .frame(width: frame.width, height: frame.height)
        }
        .scaleEffect(isDragged ? 1.01 : 1.0)
        .shadow(color: isDragged ? Color.black.opacity(0.16) : Color.clear, radius: isDragged ? 16 : 0, y: isDragged ? 8 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragged)
        .position(x: curX + frame.width / 2, y: curY + frame.height / 2) // grid: ok frame center position
    }
}

// MARK: - Reference Card Node View
struct CanvasReferenceNodeView: View {
    let ref: CanvasReferenceCard
    let isSelected: Bool
    let isDragged: Bool
    let isElementInGroup: Bool
    let isConnectingSource: Bool
    let groupDragOffset: CGSize
    let refCardDragOffset: CGSize
    let onTap: () -> Void
    let onDelete: () -> Void
    let onConvertToIdea: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var body: some View {
        let pos = CGPoint(
            x: ref.position.x + (isElementInGroup ? groupDragOffset.width : (isDragged ? refCardDragOffset.width : 0)),
            y: ref.position.y + (isElementInGroup ? groupDragOffset.height : (isDragged ? refCardDragOffset.height : 0))
        )

        VStack(alignment: .leading, spacing: 8) {
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
                    onDelete()
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
                    onConvertToIdea()
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
                .stroke(isSelected ? Color.accentColor : (isConnectingSource ? Color.orange : Color.secondary.opacity(0.2)), lineWidth: (isSelected || isConnectingSource) ? 2 : 1)
        )
        .scaleEffect(isDragged ? 1.04 : 1.0)
        .shadow(color: isDragged ? Color.black.opacity(0.24) : Color.black.opacity(0.08), radius: isDragged ? 16 : 6, y: isDragged ? 12 : 3)
        .zIndex(isDragged ? 100 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragged)
        .position(pos) // grid: ok reference card position
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
    }
}

// MARK: - Sticky Node View
struct CanvasStickyNodeView: View {
    let sticky: CanvasSticky
    let isSelected: Bool
    let isDragged: Bool
    let isElementInGroup: Bool
    let isConnectingSource: Bool
    let groupDragOffset: CGSize
    let stickyDragOffset: CGSize
    let onTap: () -> Void
    let onDelete: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let pos = CGPoint(
            x: sticky.position.x + (isElementInGroup ? groupDragOffset.width : (isDragged ? stickyDragOffset.width : 0)),
            y: sticky.position.y + (isElementInGroup ? groupDragOffset.height : (isDragged ? stickyDragOffset.height : 0))
        )

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Spacer()
                Button {
                    onDelete()
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
                .stroke(isSelected ? Color.accentColor : (isConnectingSource ? Color.orange : Color.clear), lineWidth: 2)
        )
        .scaleEffect(isDragged ? 1.05 : 1.0)
        .shadow(color: isDragged ? Color.black.opacity(0.24) : Color.black.opacity(0.1), radius: isDragged ? 16 : 4, y: isDragged ? 12 : 2)
        .zIndex(isDragged ? 100 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragged)
        .position(pos) // grid: ok canvas dynamic position
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
    }
}

// MARK: - Idea Node View
struct CanvasIdeaNodeView: View {
    let item: Item
    let position: CGPoint
    let isSelected: Bool
    let isConnectingSource: Bool
    let isDragged: Bool
    let onTap: () -> Void
    let onOpenDetails: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    onOpenDetails()
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
                .stroke(isSelected ? Color.accentColor : (isConnectingSource ? Color.orange : Color.secondary.opacity(0.2)), lineWidth: (isSelected || isConnectingSource) ? 2 : 1)
        )
        .scaleEffect(isDragged ? 1.04 : 1.0)
        .shadow(color: isDragged ? Color.black.opacity(0.24) : Color.black.opacity(0.08), radius: isDragged ? 16 : 6, y: isDragged ? 12 : 3)
        .zIndex(isDragged ? 100 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragged)
        .position(position) // grid: ok canvas dynamic position
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
    }
}
