import SwiftUI

/// Emil Kowalski Design Engineering:
/// Tactile micro-spring press feedback for responsive buttons
public struct TactileButtonStyle: ButtonStyle {
    public var scale: CGFloat = 0.97

    public init(scale: CGFloat = 0.97) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == TactileButtonStyle {
    static var tactile: TactileButtonStyle { TactileButtonStyle() }
    static func tactile(scale: CGFloat) -> TactileButtonStyle { TactileButtonStyle(scale: scale) }
}
