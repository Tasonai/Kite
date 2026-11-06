import AppKit
import SwiftUI
import KiteKit

// MARK: - Arrow Head Shape
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

// MARK: - Background Dot Matrix
struct CanvasGridBackground: View {
    let offset: CGSize
    let scale: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

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
                        context.fill(Path(ellipseIn: rect), with: .color(isDark ? Color.white.opacity(0.10) : Color.secondary.opacity(0.18)))
                        y += spacing
                    }
                    x += spacing
                }
            }
        }
        .background(isDark ? Color(hex: "#121214") : Color(nsColor: .windowBackgroundColor))
    }
}
