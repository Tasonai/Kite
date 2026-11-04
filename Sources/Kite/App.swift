import AppKit
import SwiftData
import SwiftUI
import KiteKit

// Kite
//   Kite                      the app
//   APP_STORE=<file> Kite     use another database (tests, experiments)
//   APP_SNAPSHOT=<dir> Kite   save a PNG of every sidebar page and Settings tab in light and dark mode, then quit
//   APP_SEED=1 Kite           fill an empty /tmp store with sample items (tools/snap.sh)
//   Kite --selftest           run the self-test on a /tmp store and quit with 0 or 1 (tools/selftest.sh)
//   APP_ACCENT=<id> Kite      run with another accent from Theme.all (UI/Theme.swift)
//   APP_GRID=1 Kite           draw the 8 pt grid and the layout probes over the window

@main
struct KiteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model: AppModel

    init() {
        let appModel = AppModel(container: Store.makeContainer())
        _model = State(initialValue: appModel)
        if SelfTest.requested {
            SelfTest.run(model: appModel)
        }
    }

    var body: some Scene {
        WindowGroup("Kite", id: "main") {
            ContentView()
                .environment(model)
                .themed()
                .overlay { if GridOverlay.enabled { GridOverlay() } }
                .frame(minWidth: 960, minHeight: 600)
                .task {
                    guard !SelfTest.requested && !Snapshot.requested else { return }
                    QuickCaptureManager.shared.start(model: model)
                    configureSyncServer(model: model)
                }
        }
        .modelContainer(model.container)
        .defaultSize(width: 1240, height: 780)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            ToolbarCommands()
            CommandGroup(replacing: .newItem) {
                Button("New Item") { model.addItem() }
                    .keyboardShortcut("n")
                Button("Quick Capture...") {
                    QuickCaptureManager.shared.show()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("Kite", systemImage: "paperplane") {
            MenuBarView()
                .environment(model)
                .modelContainer(model.container)
                .themed()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(model)
                .themed()
        }
        .windowResizability(.contentSize)
    }

    private func configureSyncServer(model: AppModel) {
        let server = KiteSyncServer.shared
        server.exportIdeasProvider = { @Sendable in
            await MainActor.run {
                model.exportIdeas()
            }
        }
        server.importIdeasHandler = { @Sendable data in
            await MainActor.run {
                model.importIdeas(from: data)
            }
        }
        server.start()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Started from a terminal, the process is not a foreground app yet.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            for window in NSApp.windows where window.canBecomeMain && !window.isSheet {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        SelfTest.requested || Snapshot.requested
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in NSApp.windows where window.canBecomeMain && !window.isSheet {
                window.makeKeyAndOrderFront(nil)
                return true
            }
            return false
        }
        return true
    }

    /// The self-test's result becomes the exit code, after a normal quit.
    func applicationWillTerminate(_ notification: Notification) {
        if SelfTest.requested { exit(SelfTest.exitCode) }
    }
}

/// Where the data lives: ~/Library/Application Support/Kite/Kite.store
enum Store {
    /// True when APP_STORE points somewhere else (tests, snapshots, seed data).
    static var isOverridden: Bool {
        !(ProcessInfo.processInfo.environment["APP_STORE"] ?? "").isEmpty
    }

    static var url: URL {
        if let path = ProcessInfo.processInfo.environment["APP_STORE"], !path.isEmpty {
            return URL(fileURLWithPath: path)
        }
        let dir = URL.applicationSupportDirectory.appending(path: "Kite", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "Kite.store")
    }

    static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Item.self, configurations: ModelConfiguration(url: url))
        } catch {
            fatalError("Could not open the database at \(url.path): \(error)")
        }
    }
}
