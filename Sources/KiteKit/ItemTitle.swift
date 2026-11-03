import Foundation

/// Rules for item titles. Logic lives in this library so tests can run it
/// without the app. Put parsers, date rules, and data rules here too.
public enum ItemTitle {
    /// Trims spaces and line breaks, collapses inner runs of spaces, and
    /// falls back to "Новая идея" for an empty title.
    public static func clean(_ text: String) -> String {
        let words = text.split(whereSeparator: \.isWhitespace)
        return words.isEmpty ? "Новая идея" : words.joined(separator: " ")
    }
}

public enum PromptCompiler {
    public static func compileBlueprint(
        title: String,
        concept: String,
        platform: String,
        style: String,
        skills: [String] = ["@site-md", "@design-md", "@taste-design", "@impeccable", "@emil-design-eng"]
    ) -> String {
        let skillsLine = skills.joined(separator: " ")
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveConcept = cleanConcept.isEmpty ? "Реализация проекта без лишнего шума и шаблонов." : cleanConcept

        return """
        /plan \(skillsLine)

        # ПОЛНЕЙШИЙ АРХИТЕКТУРНЫЙ ПЛАН И СПЕЦИФИКАЦИЯ ПРОЕКТА
        > **Концепция:** \(cleanTitle) — \(effectiveConcept)
        > **Целевая платформа:** \(platform)
        > **Визуальная система:** \(style)
        > **Подход:** Zero AI Slop Architecture // High Density & Polish

        ## РАЗДЕЛ 1. JTBD И ГРАНИЦЫ MVP
        - **Главная цель продукта:** Автоматизировать ключевой сценарий пользователя, устранить трение и предоставить результат за минимальное число действий.
        - **Ключевой сценарий:** Быстрый ввод, наглядная визуализация и локальное хранилище данных без блокировок интерфейса.

        ## РАЗДЕЛ 2. ТЕХНИЧЕСКИЙ СТЕК И ДИЗАЙН-СИСТЕМА
        - **Платформа:** \(platform)
        - **Стиль интерфейса:** \(style)
        - **Сетка и отступы:** Строгая 4pt/8pt модульная система, выверенная иерархия шрифтов.
        - **Принципы крафта:** Поддержка клавиатурных шорткатов, тактильная обратная связь, мгновенный поиск.

        ## РАЗДЕЛ 3. ПОШАГОВЫЙ ПЛАН РЕАЛИЗАЦИИ
        1. Создать локальную модель данных и персистентный слой.
        2. Скомпоновать трёхуровневую навигацию и списочные представления.
        3. Реализовать мгновенный экспорт и хоткеи (Cmd+K, Cmd+N, Escape).
        4. Провести аудит доступности (a11y) и состязательное код-ревью.
        """
    }
}
