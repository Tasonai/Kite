import Foundation

/// Keeps the architect chat between launches, in a small JSON file next to the app's other data.
public enum ChatHistoryStore {
    /// How many messages are kept. Older ones are dropped so the file and the model prompt stay small.
    public static let limit = 200

    public static var defaultURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "Kite", directoryHint: .isDirectory)
            .appending(path: "ChatHistory.json")
    }

    public static func load(from url: URL = defaultURL) -> [ChatMessageItem]? {
        guard let data = try? Data(contentsOf: url),
              let messages = try? JSONDecoder().decode([ChatMessageItem].self, from: data),
              !messages.isEmpty else { return nil }
        return messages
    }

    public static func save(_ messages: [ChatMessageItem], to url: URL = defaultURL) {
        let kept = Array(messages.suffix(limit))
        guard let data = try? JSONEncoder().encode(kept) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
