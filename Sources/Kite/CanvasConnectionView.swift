import SwiftUI
import KiteKit

struct CanvasConnectionView: View {
    let conn: CanvasConnection
    let isSelected: Bool
    let start: CGPoint
    let end: CGPoint
    let isSimulationActive: Bool
    let isEditing: Bool
    @Binding var editingText: String
    let onStartEditing: () -> Void
    let onSubmitEditing: (String) -> Void
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onSetProtocol: (String) -> Void

    private var connectionGeometry: (startPt: CGPoint, endPt: CGPoint, midPt: CGPoint, dx: CGFloat) {
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
        return (startPt, endPt, midPt, dx)
    }

    var body: some View {
        let geo = connectionGeometry

        ZStack {
            // Curved Path
            Path { path in
                path.move(to: geo.startPt)
                let cdx = (geo.endPt.x - geo.startPt.x) * 0.5
                path.addCurve(
                    to: geo.endPt,
                    control1: CGPoint(x: geo.startPt.x + cdx, y: geo.startPt.y),
                    control2: CGPoint(x: geo.endPt.x - cdx, y: geo.endPt.y)
                )
            }
            .stroke(
                isSelected ? Color.orange : Color(hex: conn.colorHex),
                style: StrokeStyle(lineWidth: isSelected ? 3 : 2, dash: isSimulationActive ? [4, 4] : [6, 4]) // grid: ok stroke
            )

            // Dynamic Throughput Particle Stream (when simulation is active)
            if isSimulationActive {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let p0 = geo.startPt
                    let cdx = (geo.endPt.x - geo.startPt.x) * 0.5
                    let p1 = CGPoint(x: geo.startPt.x + cdx, y: geo.startPt.y)
                    let p2 = CGPoint(x: geo.endPt.x - cdx, y: geo.endPt.y)
                    let p3 = geo.endPt

                    ForEach(0..<2, id: \.self) { idx in
                        let phase = Double(idx) * 0.5
                        let t = CGFloat((time * 0.8 + phase).truncatingRemainder(dividingBy: 1.0))

                        let u = 1.0 - t
                        let tt = t * t
                        let uu = u * u
                        let uuu = uu * u
                        let ttt = tt * t

                        let px = uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x
                        let py = uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y

                        Circle()
                            .fill(isSelected ? Color.orange : Color(hex: conn.colorHex))
                            .frame(width: 8, height: 8)
                            .shadow(color: Color(hex: conn.colorHex).opacity(0.8), radius: 4)
                            .position(x: px, y: py) // grid: ok simulation particle
                    }
                }
            }

            // Arrow Head at end
            ArrowHead(at: geo.endPt, from: CGPoint(x: geo.endPt.x - (geo.dx > 0 ? 20 : -20), y: geo.endPt.y))
                .fill(isSelected ? Color.orange : Color(hex: conn.colorHex))

            // Connection Label / Interaction Badge
            if isEditing {
                HStack(spacing: 4) {
                    TextField("Подпись", text: $editingText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced)) // grid: ok font
                        .frame(width: 80)
                        .onSubmit {
                            onSubmitEditing(editingText)
                        }

                    Button {
                        onSubmitEditing(editingText)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10)) // grid: ok font
                            .foregroundStyle(Color.green)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                .position(geo.midPt) // grid: ok connection mid badge position
            } else {
                HStack(spacing: 4) {
                    if isSimulationActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                    }

                    if !conn.label.isEmpty {
                        Text(conn.label)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced)) // grid: ok font
                            .foregroundStyle(Color.primary)
                    }

                    if isSimulationActive {
                        Text("1.2k rps")
                            .font(.system(size: 8, weight: .bold, design: .monospaced)) // grid: ok font
                            .foregroundStyle(Color.green)
                    }

                    if isSelected {
                        Button {
                            onStartEditing()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 9)) // grid: ok font
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onDelete()
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
                .position(geo.midPt) // grid: ok connection mid badge position
                .onTapGesture(count: 2) {
                    onStartEditing()
                }
                .onTapGesture {
                    onSelect()
                }
                .contextMenu {
                    Button {
                        onStartEditing()
                    } label: {
                        Label("Изменить подпись", systemImage: "pencil")
                    }

                    Menu("Изменить протокол") {
                        ForEach(CanvasConnectionProtocol.allCases, id: \.self) { proto in
                            Button(proto.rawValue) {
                                onSetProtocol(proto.rawValue)
                            }
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Удалить связь", systemImage: "trash")
                    }
                }
            }
        }
    }
}
