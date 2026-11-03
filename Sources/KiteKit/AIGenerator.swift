import Foundation

public enum AIProvider: String, CaseIterable, Identifiable {
    case gemini = "Gemini API"
    case localOllama = "Local Ollama"
    case localCompiler = "Local Blueprint (Offline)"

    public var id: String { rawValue }
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
                // If no API key provided, fall back to rich local blueprint
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
            ],
            "generationConfig": [
                "temperature": 0.25,
                "maxOutputTokens": 4096
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
