import AppKit
import Foundation

public enum EditorLauncher {
    public enum Editor: String, CaseIterable, Identifiable, Sendable {
        case cursor = "Cursor"
        case vsCode = "VS Code"
        case terminal = "Терминал"

        public var id: String { rawValue }

        public var systemImage: String {
            switch self {
            case .cursor: return "chevron.left.forwardslash.chevron.right"
            case .vsCode: return "curlybraces"
            case .terminal: return "terminal"
            }
        }
    }

    public static func isAvailable(_ editor: Editor) -> Bool {
        switch editor {
        case .cursor:
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92") != nil
                || FileManager.default.fileExists(atPath: "/Applications/Cursor.app")
        case .vsCode:
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") != nil
                || FileManager.default.fileExists(atPath: "/Applications/Visual Studio Code.app")
        case .terminal:
            return true
        }
    }

    public static func open(directory: URL, in editor: Editor) -> Bool {
        switch editor {
        case .cursor:
            let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92")
                ?? URL(fileURLWithPath: "/Applications/Cursor.app")
            if FileManager.default.fileExists(atPath: appUrl.path) {
                let config = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.open([directory], withApplicationAt: appUrl, configuration: config, completionHandler: nil)
                return true
            }
        case .vsCode:
            let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode")
                ?? URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
            if FileManager.default.fileExists(atPath: appUrl.path) {
                let config = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.open([directory], withApplicationAt: appUrl, configuration: config, completionHandler: nil)
                return true
            }
        case .terminal:
            let ghosttyUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.mitchellh.ghostty")
            let termUrl = ghosttyUrl ?? (NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") ?? URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([directory], withApplicationAt: termUrl, configuration: config, completionHandler: nil)
            return true
        }
        return false
    }
}
