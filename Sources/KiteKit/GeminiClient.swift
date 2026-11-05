import Foundation

/// Talks to the Gemini API. Retries temporary failures and moves to another model when one is gone,
/// so a retired model name or a busy server does not turn into a canned template.
public enum GeminiClient {
    /// The model used when the user has not picked one.
    public static let defaultModel = "gemini-3.5-flash"

    /// Tried after the requested model, in this order.
    static let fallbackModels = ["gemini-3.5-flash", "gemini-3.1-flash-lite", "gemini-flash-latest"]

    /// Model names Google has retired for new keys. They map to the default.
    static let retiredModels: Set<String> = ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-pro"]

    /// The models to try, in order, without repeats.
    public static func modelChain(requested: String) -> [String] {
        let trimmed = requested.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = (trimmed.isEmpty || retiredModels.contains(trimmed)) ? defaultModel : trimmed
        var chain = [first]
        for model in fallbackModels where !chain.contains(model) { chain.append(model) }
        return chain
    }

    /// 404 and temporary server states: move on to the next model. Everything else is the caller's problem.
    static func shouldTryNextModel(status: Int) -> Bool {
        status == 404 || status == 429 || status == 500 || status == 503
    }

    /// Server is busy or limiting: worth one more try on the same model.
    static func shouldRetrySameModel(status: Int) -> Bool {
        status == 429 || status == 500 || status == 503
    }

    public static func generate(payload: [String: Any], apiKey: String, model: String) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = try JSONSerialization.data(withJSONObject: payload)
        var lastStatus = 0
        var lastMessage = ""

        for candidate in modelChain(requested: model) {
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(candidate):generateContent") else {
                throw URLError(.badURL)
            }
            for attempt in 1...2 {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 120
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
                request.httpBody = body

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

                if http.statusCode == 200 { return try parseText(data) }

                lastStatus = http.statusCode
                lastMessage = errorMessage(from: data)
                KiteLog.ai.error("Gemini \(candidate) answered \(http.statusCode)")

                if http.statusCode == 400 || http.statusCode == 401 || http.statusCode == 403 {
                    throw NSError(domain: "GeminiAPI", code: http.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Gemini отклонил запрос (\(http.statusCode)): \(lastMessage). Проверьте ключ в настройках."
                    ])
                }
                if shouldRetrySameModel(status: http.statusCode), attempt == 1 {
                    try await Task.sleep(for: .seconds(1.5))
                    continue
                }
                if shouldTryNextModel(status: http.statusCode) { break }
                throw NSError(domain: "GeminiAPI", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "Ошибка Gemini (\(http.statusCode)): \(lastMessage)"
                ])
            }
        }
        throw NSError(domain: "GeminiAPI", code: lastStatus, userInfo: [
            NSLocalizedDescriptionKey: "Ни одна модель Gemini не ответила (последняя ошибка \(lastStatus)): \(lastMessage)"
        ])
    }

    /// The text carried by one server-sent-event line, or nil for lines that carry none.
    public static func streamedText(fromLine line: String) -> String? {
        guard line.hasPrefix("data:") else { return nil }
        let json = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
        guard !json.isEmpty, let data = json.data(using: .utf8),
              let text = try? parseText(data) else { return nil }
        return text
    }

    /// Streams the answer piece by piece. Falls back across models only before the first piece arrives;
    /// after that the stream either finishes or fails, because the text already shown cannot be unsaid.
    public static func stream(payload: [String: Any], apiKey: String, model: String) -> AsyncThrowingStream<String, Error> {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = try? JSONSerialization.data(withJSONObject: payload)
        let bodyWithoutThinking = withoutThinking(payload).flatMap { try? JSONSerialization.data(withJSONObject: $0) }
        let chain = modelChain(requested: model)

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let body else { throw URLError(.cannotParseResponse) }
                    try await run(chain: chain, key: key, body: body, bodyWithoutThinking: bodyWithoutThinking, continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func run(
        chain: [String],
        key: String,
        body initialBody: Data,
        bodyWithoutThinking: Data?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        var lastStatus = 0
        var lastMessage = ""
        var body = initialBody

        for candidate in chain {
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(candidate):streamGenerateContent?alt=sse") else {
                throw URLError(.badURL)
            }
            for attempt in 1...2 {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 120
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
                request.httpBody = body

                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

                if http.statusCode == 200 {
                    for try await line in bytes.lines {
                        if let piece = streamedText(fromLine: line) { continuation.yield(piece) }
                    }
                    return
                }

                var errorData = Data()
                for try await byte in bytes { errorData.append(byte) }
                lastStatus = http.statusCode
                lastMessage = errorMessage(from: errorData)
                KiteLog.ai.error("Gemini stream \(candidate) answered \(http.statusCode)")

                // This model may not know the thinking setting: ask again without it before giving up.
                if http.statusCode == 400, let plain = bodyWithoutThinking, body != plain {
                    body = plain
                    continue
                }
                if http.statusCode == 400 || http.statusCode == 401 || http.statusCode == 403 {
                    throw NSError(domain: "GeminiAPI", code: http.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Gemini отклонил запрос (\(http.statusCode)): \(lastMessage). Проверьте ключ в настройках."
                    ])
                }
                if shouldRetrySameModel(status: http.statusCode), attempt == 1 {
                    try await Task.sleep(for: .seconds(1.5))
                    continue
                }
                if shouldTryNextModel(status: http.statusCode) { break }
                throw NSError(domain: "GeminiAPI", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "Ошибка Gemini (\(http.statusCode)): \(lastMessage)"
                ])
            }
        }
        throw NSError(domain: "GeminiAPI", code: lastStatus, userInfo: [
            NSLocalizedDescriptionKey: "Ни одна модель Gemini не ответила (последняя ошибка \(lastStatus)): \(lastMessage)"
        ])
    }

    /// The payload minus its thinking setting, or nil when it had none.
    public static func withoutThinking(_ payload: [String: Any]) -> [String: Any]? {
        guard var config = payload["generationConfig"] as? [String: Any], config["thinkingConfig"] != nil else { return nil }
        config.removeValue(forKey: "thinkingConfig")
        var copy = payload
        copy["generationConfig"] = config
        return copy
    }

    /// Joins the answer's text parts; thought parts are skipped.
    static func parseText(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Пустой ответ Gemini."])
        }
        let text = parts
            .filter { ($0["thought"] as? Bool) != true }
            .compactMap { $0["text"] as? String }
            .joined()
        guard !text.isEmpty else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Gemini вернул ответ без текста."])
        }
        return text
    }

    private static func errorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return String(message.prefix(240))
        }
        return String(String(data: data, encoding: .utf8)?.prefix(240) ?? "без текста ошибки")
    }
}
