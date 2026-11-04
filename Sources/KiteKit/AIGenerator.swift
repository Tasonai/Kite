import Foundation

public enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    case gemini = "Gemini API"
    case localOllama = "Local Ollama"
    case localCompiler = "Local Blueprint (Offline)"

    public var id: String { rawValue }
}

public struct ChatMessageItem: Sendable, Identifiable {
    public let id: UUID
    public let role: String // "user" or "assistant" / "model"
    public let content: String
    public let timestamp: Date

    public init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public enum AIGenerator {
    public static func generateSpecification(
        title: String,
        concept: String,
        platform: String,
        style: String,
        apiKey: String,
        provider: AIProvider = .gemini,
        modelName: String = "gemini-2.5-flash",
        ollamaEndpoint: String = "http://localhost:11434/api/generate"
    ) async throws -> String {
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
                title: title,
                concept: concept,
                platform: platform,
                style: style,
                apiKey: apiKey,
                modelName: modelName
            )
        case .localOllama:
            return try await callOllama(
                title: title,
                concept: concept,
                platform: platform,
                style: style,
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

    public static func chat(
        messages: [ChatMessageItem],
        apiKey: String,
        provider: AIProvider = .gemini,
        modelName: String = "gemini-2.5-flash",
        ollamaEndpoint: String = "http://localhost:11434/api/chat"
    ) async throws -> String {
        let systemPrompt = """
        Ты — Kite AI-Архитектор и Principal Software Engineer экосистемы Antigravity на macOS.
        Твоя специализация:
        1. Проектирование современных архитектур (React 19, Vite, Next.js, SwiftUI, Flutter, Tailwind CSS, SwiftData).
        2. Подбор и рекомендация системных навыков Antigravity (@site-md, @design-md, @taste-design, @impeccable, @emil-design-eng, @a11y-debugging, @gsd-execute-phase, @superpowers, @vercel-plugin, @figma, @bama).
        3. Дизайн-системы, точные токены и экспорт в Google Stitch (DESIGN.md) и Figma.
        4. Практические советы по устранению AI-слопа (Zero AI Slop), соблюдению 4pt-сетки Apple HIG и оптимизации UX.

        Отвечай строго по существу, профессионально, на русском языке, используя структурированный Markdown с кодовыми блоками.
        """

        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if provider == .gemini && !cleanKey.isEmpty {
            return try await callGeminiChat(
                messages: messages,
                systemInstruction: systemPrompt,
                apiKey: cleanKey,
                modelName: modelName.isEmpty ? "gemini-2.5-flash" : modelName
            )
        } else if provider == .localOllama {
            return try await callOllamaChat(
                messages: messages,
                systemInstruction: systemPrompt,
                endpoint: ollamaEndpoint,
                modelName: modelName.isEmpty ? "llama3" : modelName
            )
        } else {
            // Intelligent local architectural assistant
            return localArchitectReply(to: messages.last?.content ?? "")
        }
    }

    private static func localArchitectReply(to userText: String) -> String {
        let q = userText.lowercased()
        if q.contains("figma") || q.contains("stitch") || q.contains("дизайн") {
            return """
            ### Рекомендация по дизайн-системе (Stitch & Figma)

            Для вашего интерфейса рекомендую гибридную архитектуру с экспортом токенов:
            - **Google Stitch:** используйте команду `@design-md` для генерации файла `DESIGN.md`. Он включает семантические токены (`surface`, `primary`, `headlineFont`, `roundness`).
            - **Figma Code Connect:** подключите плагин `@figma` для двусторонней связи компонентов с кодовой базой.

            **Рекомендуемый стек скиллов:**
            `/plan @design-md @taste-design @emil-design-eng @figma`

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
            `/plan @new-mac-app @apple-design @swift-swiftui @impeccable`
            """
        } else {
            return """
            ### Архитектурный разбор Kite Copilot

            Анализ задачи: **«\(userText)»**

            **1. Архитектурный вектор:**
            - Рекомендуемый подход: декомпозиция на 3 волны (Wave 1: базовые модели и стор; Wave 2: интерфейс и моушн; Wave 3: интеграции и валидация).
            - Соблюдение принципа Zero AI Slop: отказ от безликих серых карточек в пользу выверенной типографики и тактильного отклика.

            **2. Рекомендуемые навыки Antigravity:**
            - `@site-md` — конституция и архитектурный контракт
            - `@design-md` — семантическая дизайн-система
            - `@impeccable` — чистота кода и строгая типизация
            - `@emil-design-eng` — пружинная физика микро-интеракций

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
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var contentsJson: [[String: Any]] = []
        for msg in messages {
            let roleStr = (msg.role == "user") ? "user" : "model"
            contentsJson.append([
                "role": roleStr,
                "parts": [["text": msg.content]]
            ])
        }

        let payload: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemInstruction]]
            ],
            "contents": contentsJson
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let err = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка Gemini: \(err)"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Пустой ответ Gemini."])
        }

        return text
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

    private static func buildPrompt(title: String, concept: String, platform: String, style: String) -> String {
        """
        Ты — ведущий AI-архитектор и Principal Software Engineer, специализирующийся на методологии Antigravity.
        Составь исчерпывающий, профессиональный инженерный план и спецификацию (/plan) для следующего проекта:

        ПРОЕКТ: \(title)
        КОНЦЕПЦИЯ: \(concept.isEmpty ? "Инновационный продукт с высокой отзывчивостью и чистой архитектурой." : concept)
        ЦЕЛЕВАЯ ПЛАТФОРМА: \(platform)
        ДИЗАЙН-СИСТЕМА: \(style)

        ТРЕБОВАНИЯ К ОТВЕТУ:
        1. В первой строке ОБЯЗАТЕЛЬНО укажи команду Antigravity с релевантными скиллами:
           /plan @site-md @design-md @taste-design @impeccable @emil-design-eng
        2. Формат: Строгий Markdown, профессиональный технический тон, Zero AI Slop.
        3. Разделы плана:
           # ПОЛНЫЙ АРХИТЕКТУРНЫЙ ПЛАН: \(title)
           ## 1. JTBD И КЛЮЧЕВЫЕ ПОЛЬЗОВАТЕЛЬСКИЕ СЦЕНАРИИ
           ## 2. АРХИТЕКТУРА ДАННЫХ И КОМПОНЕНТОВ
           ## 3. ДИЗАЙН-СИСТЕМА, ТОКЕНЫ И A11Y (доступность, 4pt/8pt сетка)
           ## 4. КРАЕВЫЕ СЛУЧАИ И ОТКАЗОУСТОЙЧИВОСТЬ
           ## 5. ПОШАГОВЫЙ ПЛАН РЕАЛИЗАЦИИ (WAVE 1, WAVE 2, WAVE 3)
           ## 6. КРИТЕРИИ ПРИЁМКИ И ТЕСТЫ (UAT)
        """
    }

    private static func callGeminiAPI(
        title: String,
        concept: String,
        platform: String,
        style: String,
        apiKey: String,
        modelName: String
    ) async throws -> String {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveModel = modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "gemini-2.5-flash" : modelName
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(effectiveModel):generateContent?key=\(cleanKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let promptText = buildPrompt(title: title, concept: concept, platform: platform, style: style)
        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GeminiAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Gemini API error (\(httpResponse.statusCode)): \(errorText)"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось распарсить ответ от Gemini API."])
        }

        return text
    }

    private static func callOllama(
        title: String,
        concept: String,
        platform: String,
        style: String,
        endpoint: String,
        modelName: String
    ) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        let promptText = buildPrompt(title: title, concept: concept, platform: platform, style: style)
        let payload: [String: Any] = [
            "model": modelName,
            "prompt": promptText,
            "stream": false
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
}
