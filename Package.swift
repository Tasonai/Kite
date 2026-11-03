// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Kite",
    platforms: [.macOS(.v26)],
    targets: [
        // Rules and data logic with no SwiftUI, so tests run without the app.
        .target(name: "KiteKit"),
        .executableTarget(
            name: "Kite",
            dependencies: ["KiteKit"],
            // App code runs on the main thread unless you say otherwise.
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "KiteKitTests", dependencies: ["KiteKit"]),
    ]
)
