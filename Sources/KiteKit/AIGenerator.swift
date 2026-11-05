import Foundation

public enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    case gemini = "Gemini API"
    case openAI = "OpenAI Compatible"
    case localOllama = "Local Ollama"
    case localCompiler = "Local Blueprint (Offline)"

    public var id: String { rawValue }
}

public struct ChatMessageItem: Sendable, Identifiable, Codable {
    public let id: UUID
    public let role: String // "user" or "assistant" / "model"
    public var content: String
    public let timestamp: Date

    public init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public enum AIGenerator {
    /// Shown whenever an answer comes from a fixed offline template instead of a model.
    public static let offlineNotice = "Офлайн-режим: ключ Gemini не задан, поэтому это шаблонный ответ без ИИ. Добавьте ключ: меню Kite, Настройки (⌘,), вкладка «AI & Models»."

    /// Sampling for Gemini: warm enough to avoid the same stock answer every time.
    private static var generationConfig: [String: Any] { generationConfig(thinking: nil) }

    /// `thinking` is "low", "medium" or "high": how long the model deliberates before answering.
    private static func generationConfig(thinking: String?) -> [String: Any] {
        var config: [String: Any] = ["temperature": 0.8, "topP": 0.95]
        if let thinking { config["thinkingConfig"] = ["thinkingLevel": thinking] }
        return config
    }

    /// Short modes and chat answer fast; the plan and Stitch modes keep the full deliberation.
    public static func thinkingLevel(forMode mode: String) -> String? {
        switch mode {
        case "concise", "action", "edit": return "low"
        default: return nil
        }
    }

    public static func generateSpecification(
        title: String,
        concept: String,
        platform: String,
        style: String,
        apiKey: String,
        provider: AIProvider = .gemini,
        modelName: String = GeminiClient.defaultModel,
        ollamaEndpoint: String = "http://localhost:11434/api/generate",
        mode: String = "full",
        skills: [String] = ["/site-md", "/design-md", "/taste-design", "/impeccable", "/emil-design-eng"]
    ) async throws -> String {
        let promptText = AIPrompts.translator(
            mode: mode,
            rawPrompt: ideaText(title: title, concept: concept),
            platform: platform,
            style: style,
            skills: skills
        )
        switch provider {
        case .gemini:
            if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return PromptCompiler.compileBlueprint(
                    title: title,
                    concept: concept,
                    platform: platform,
                    style: style
                )
            }
            return try await callGeminiAPI(
                promptText: promptText,
                apiKey: apiKey,
                modelName: modelName
            )
        case .openAI:
            let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanKey.isEmpty && !ollamaEndpoint.contains("localhost") {
                return PromptCompiler.compileBlueprint(
                    title: title,
                    concept: concept,
                    platform: platform,
                    style: style
                )
            }
            return try await callOpenAIAPI(
                promptText: promptText,
                apiKey: cleanKey,
                endpoint: ollamaEndpoint.isEmpty ? "https://api.deepseek.com/v1/chat/completions" : ollamaEndpoint,
                modelName: modelName.isEmpty ? "deepseek-chat" : modelName
            )
        case .localOllama:
            return try await callOllama(
                promptText: promptText,
                endpoint: ollamaEndpoint,
                modelName: modelName.isEmpty ? "llama3" : modelName
            )
        case .localCompiler:
            return PromptCompiler.compileBlueprint(
                title: title,
                concept: concept,
                platform: platform,
                style: style
            )
        }
    }

    /// Same as `generateSpecification`, but delivers the text piece by piece.
    /// Providers without streaming deliver the whole answer as one piece.
    public static func generateSpecificationStream(
        title: String,
        concept: String,
        platform: String,
        style: String,
        apiKey: String,
        provider: AIProvider = .gemini,
        modelName: String = GeminiClient.defaultModel,
        ollamaEndpoint: String = "http://localhost:11434/api/generate",
        mode: String = "full",
        skills: [String] = ["/site-md", "/design-md", "/taste-design", "/impeccable", "/emil-design-eng"]
    ) -> AsyncThrowingStream<String, Error> {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if provider == .gemini && !cleanKey.isEmpty {
            let promptText = AIPrompts.translator(
                mode: mode,
                rawPrompt: ideaText(title: title, concept: concept),
                platform: platform,
                style: style,
                skills: skills
            )
            let payload: [String: Any] = [
                "contents": [["parts": [["text": promptText]]]],
                "generationConfig": generationConfig(thinking: thinkingLevel(forMode: mode))
            ]
            return GeminiClient.stream(payload: payload, apiKey: cleanKey, model: modelName)
        }
        return singleShot {
            try await generateSpecification(
                title: title, concept: concept, platform: platform, style: style,
                apiKey: apiKey, provider: provider, modelName: modelName,
                ollamaEndpoint: ollamaEndpoint, mode: mode, skills: skills
            )
        }
    }

    /// Two or three clarifying questions for a rough idea. Returns none when there is no model to ask
    /// or the answer cannot be read, so the caller can go straight to generating.
    public static func interviewQuestions(
        idea: String,
        platform: String,
        style: String,
        apiKey: String,
        modelName: String = GeminiClient.defaultModel
    ) async throws -> [AIPrompts.InterviewQuestion] {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { return [] }
        let payload: [String: Any] = [
            "contents": [["parts": [["text": AIPrompts.interview(idea: idea, platform: platform, style: style)]]]],
            "generationConfig": generationConfig(thinking: "low")
        ]
        let text = try await GeminiClient.generate(payload: payload, apiKey: cleanKey, model: modelName)
        return AIPrompts.parseInterview(text)
    }

    /// Same as `chat`, but delivers the reply piece by piece.
    public static func chatStream(
        messages: [ChatMessageItem],
        apiKey: String,
        provider: AIProvider = .gemini,
        modelName: String = GeminiClient.defaultModel,
        ollamaEndpoint: String = "http://localhost:11434/api/chat",
        context: AIPrompts.ChatContext = .init(ideas: [])
    ) -> AsyncThrowingStream<String, Error> {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if provider == .gemini && !cleanKey.isEmpty {
            let contents: [[String: Any]] = messages.map { msg in
                ["role": msg.role == "user" ? "user" : "model", "parts": [["text": msg.content]]]
            }
            let payload: [String: Any] = [
                "system_instruction": ["parts": [["text": AIPrompts.chatSystem(context: context)]]],
                "contents": contents,
                "generationConfig": generationConfig(thinking: "low")
            ]
            return GeminiClient.stream(payload: payload, apiKey: cleanKey, model: modelName)
        }
        return singleShot {
            try await chat(
                messages: messages, apiKey: apiKey, provider: provider, modelName: modelName,
                ollamaEndpoint: ollamaEndpoint, context: context
            )
        }
    }

    private static func singleShot(_ operation: @escaping @Sendable () async throws -> String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    continuation.yield(try await operation())
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public static func chat(
        messages: [ChatMessageItem],
        apiKey: String,
        provider: AIProvider = .gemini,
        modelName: String = GeminiClient.defaultModel,
        ollamaEndpoint: String = "http://localhost:11434/api/chat",
        context: AIPrompts.ChatContext = .init(ideas: [])
    ) async throws -> String {
        let systemPrompt = AIPrompts.chatSystem(context: context)

        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if provider == .gemini && !cleanKey.isEmpty {
            return try await callGeminiChat(
                messages: messages,
                systemInstruction: systemPrompt,
                apiKey: cleanKey,
                modelName: modelName
            )
        } else if provider == .openAI {
            return try await callOpenAIChat(
                messages: messages,
                systemInstruction: systemPrompt,
                apiKey: cleanKey,
                endpoint: ollamaEndpoint.isEmpty ? "https://api.deepseek.com/v1/chat/completions" : ollamaEndpoint,
                modelName: modelName.isEmpty ? "deepseek-chat" : modelName
            )
        } else if provider == .localOllama {
            return try await callOllamaChat(
                messages: messages,
                systemInstruction: systemPrompt,
                endpoint: ollamaEndpoint,
                modelName: modelName.isEmpty ? "llama3" : modelName
            )
        } else {
            // No model behind this answer: say so, so a template is never mistaken for AI.
            return "**\(offlineNotice)**\n\n" + localArchitectReply(to: messages.last?.content ?? "")
        }
    }

    private static func localArchitectReply(to userText: String) -> String {
        let q = userText.lowercased()
        if q.contains("figma") || q.contains("stitch") || q.contains("дизайн") {
            return """
            ### Рекомендация по дизайн-системе (Stitch & Figma)

            Для вашего интерфейса рекомендую гибридную архитектуру с экспортом токенов:
            - **Google Stitch:** используйте команду `/design-md` для генерации файла `DESIGN.md`. Он включает семантические токены (`surface`, `primary`, `headlineFont`, `roundness`).
            - **Figma Code Connect:** подключите плагин `/figma` для двусторонней связи компонентов с кодовой базой.

            **Рекомендуемый стек скиллов:**
            `/plan /design-md /taste-design /emil-design-eng /figma`

            Нажмите кнопку **«В Stitch»** или **«В Figma»** в тулбаре для генерации готовой спецификации.
            """
        } else if q.contains("mac") || q.contains("swift") || q.contains("меню") {
            return """
            ### Архитектурный план для macOS (SwiftUI)

            Для нативного приложения под macOS рекомендую:
            1. **Стек:** Swift 6, SwiftUI, SwiftData для SQLite-персистентности без ORM overhead.
            2. **Паттерн:** 2-колоночный `NavigationSplitView` с HSplitView в рабочей области (предотвращает черные провалы на скринкастах).
            3. **HIG Сетка:** строгая 4pt-сетка для отступов и скруглений (`padding(4, 8, 12, 16, 24)`).
            4. **Хоткеи:** Carbon Events API (`InstallEventHandler`) для глобального HUD без запроса прав доступности.

            **Рекомендуемые скиллы:**
            `/plan /new-mac-app /apple-design /swift-swiftui /impeccable`
            """
        } else {
            return """
            ### Архитектурный разбор Kite Copilot

            Анализ задачи: **«\(userText)»**

            **1. Архитектурный вектор:**
            - Рекомендуемый подход: декомпозиция на 3 волны (Wave 1: базовые модели и стор; Wave 2: интерфейс и моушн; Wave 3: интеграции и валидация).
            - Соблюдение принципа Zero AI Slop: отказ от безликих серых карточек в пользу выверенной типографики и тактильного отклика.

            **2. Рекомендуемые навыки Antigravity:**
            - `/site-md` — конституция и архитектурный контракт
            - `/design-md` — семантическая дизайн-система
            - `/impeccable` — чистота кода и строгая типизация
            - `/emil-design-eng` — пружинная физика микро-интеракций

            Вы можете нажать **«В идею»** ниже, чтобы превратить этот разбор в проект в вашем каталоге.
            """
        }
    }

    private static func callGeminiChat(
        messages: [ChatMessageItem],
        systemInstruction: String,
        apiKey: String,
        modelName: String
    ) async throws -> String {
        let contents: [[String: Any]] = messages.map { msg in
            ["role": msg.role == "user" ? "user" : "model", "parts": [["text": msg.content]]]
        }
        let payload: [String: Any] = [
            "system_instruction": ["parts": [["text": systemInstruction]]],
            "contents": contents,
            "generationConfig": generationConfig
        ]
        return try await GeminiClient.generate(payload: payload, apiKey: apiKey, model: modelName)
    }

    private static func callOllamaChat(
        messages: [ChatMessageItem],
        systemInstruction: String,
        endpoint: String,
        modelName: String
    ) async throws -> String {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }

        var ollamaMsgs: [[String: Any]] = [
            ["role": "system", "content": systemInstruction]
        ]
        for m in messages {
            ollamaMsgs.append([
                "role": m.role == "user" ? "user" : "assistant",
                "content": m.content
            ])
        }

        let payload: [String: Any] = [
            "model": modelName,
            "messages": ollamaMsgs,
            "stream": false
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw NSError(domain: "Ollama", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось распарсить ответ Ollama."])
        }

        return text
    }

    /// The author's idea as one text: the title plus the concept, without repeating the title.
    static func ideaText(title: String, concept: String) -> String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanConcept.isEmpty { return cleanTitle }
        if cleanTitle.isEmpty || cleanConcept.lowercased().hasPrefix(cleanTitle.lowercased()) { return cleanConcept }
        return "\(cleanTitle). \(cleanConcept)"
    }

    private static func callGeminiAPI(
        promptText: String,
        apiKey: String,
        modelName: String
    ) async throws -> String {
        let payload: [String: Any] = [
            "contents": [["parts": [["text": promptText]]]],
            "generationConfig": generationConfig
        ]
        return try await GeminiClient.generate(payload: payload, apiKey: apiKey, model: modelName)
    }

    private static func callOllama(
        promptText: String,
        endpoint: String,
        modelName: String
    ) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        let payload: [String: Any] = [
            "model": modelName,
            "prompt": promptText,
            "stream": false,
            "options": ["temperature": 0.8]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw NSError(domain: "Ollama", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama response format"])
        }

        return responseText
    }

    private static func callOpenAIAPI(
        promptText: String,
        apiKey: String,
        endpoint: String,
        modelName: String
    ) async throws -> String {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        let payload: [String: Any] = [
            "model": modelName.isEmpty ? "deepseek-chat" : modelName,
            "messages": [
                ["role": "user", "content": promptText]
            ],
            "temperature": 0.7
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let msg = choices.first?["message"] as? [String: Any],
              let text = msg["content"] as? String else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось распарсить ответ API."])
        }
        return text
    }

    private static func callOpenAIChat(
        messages: [ChatMessageItem],
        systemInstruction: String,
        apiKey: String,
        endpoint: String,
        modelName: String
    ) async throws -> String {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": systemInstruction]
        ]
        for m in messages {
            apiMessages.append([
                "role": m.role == "user" ? "user" : "assistant",
                "content": m.content
            ])
        }
        let payload: [String: Any] = [
            "model": modelName.isEmpty ? "deepseek-chat" : modelName,
            "messages": apiMessages,
            "temperature": 0.7
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let msg = choices.first?["message"] as? [String: Any],
              let text = msg["content"] as? String else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось распарсить ответ API."])
        }
        return text
    }
}
