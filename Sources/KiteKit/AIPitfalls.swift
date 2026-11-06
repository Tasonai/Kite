import Foundation

public struct PitfallWarning: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let warning: String
    public let recommendation: String
    public let category: String

    public init(id: String, title: String, warning: String, recommendation: String, category: String) {
        self.id = id
        self.title = title
        self.warning = warning
        self.recommendation = recommendation
        self.category = category
    }
}

public enum AIPitfallProtector {
    /// Offline heuristic analysis for common beginner / vibe-coding traps.
    public static func analyze(concept: String, platform: String) -> [PitfallWarning] {
        var warnings: [PitfallWarning] = []
        let lower = concept.lowercased()

        // 1. Backend / Database complexity
        if lower.contains("баз") || lower.contains("данны") || lower.contains("сохран") || lower.contains("database") || lower.contains("бэкенд") {
            warnings.append(
                PitfallWarning(
                    id: "data-persistence",
                    title: "Хранение данных без сервера",
                    warning: "Сложный сервер и PostgreSQL на первом этапе перегрузят разработку и потребуют платного хостинга.",
                    recommendation: "Для MVP начните с локального хранилища (LocalStorage в браузере или SQLite на устройстве). Это бесплатно и работает без интернета.",
                    category: "Архитектура"
                )
            )
        }

        // 2. Auth / Multi-user complexity
        if lower.contains("логин") || lower.contains("парол") || lower.contains("профил") || lower.contains("авториз") || lower.contains("аккаунт") || lower.contains("auth") {
            warnings.append(
                PitfallWarning(
                    id: "auth-complexity",
                    title: "Авторизация пользователей",
                    warning: "Самостоятельное написание системы паролей и JWT-токенов — частый источник критических уязвимостей.",
                    recommendation: "Для версии 1.0 начните с однопользовательского режима, либо используйте готовые SDK без написания серверного кода (Supabase Auth / Firebase).",
                    category: "Безопасность"
                )
            )
        }

        // 3. Media / Image storage
        if lower.contains("фото") || lower.contains("картинк") || lower.contains("изображен") || lower.contains("видео") || lower.contains("файл") || lower.contains("image") {
            warnings.append(
                PitfallWarning(
                    id: "media-hosting",
                    title: "Загрузка медиа и изображений",
                    warning: "Сохранение картинок прямо в базу данных или репозиторий приводит к зависанию приложения.",
                    recommendation: "Используйте ссылки на изображения или локальную папку документов на устройстве без раздувания базы.",
                    category: "Хранилище"
                )
            )
        }

        // 4. Payments & Billing
        if lower.contains("оплат") || lower.contains("подписк") || lower.contains("купить") || lower.contains("тариф") || lower.contains("деньг") || lower.contains("payment") {
            warnings.append(
                PitfallWarning(
                    id: "payment-setup",
                    title: "Платежи и эквайринг",
                    warning: "Подключение платежных шлюзов требует юридического лица, модерации и сложной серверной проверки вебхуков.",
                    recommendation: "Для проверки спроса начните с ручной оплаты по QR-коду или кнопки «Оставить заявку», чтобы не тратить недели на интеграцию до первых продаж.",
                    category: "Бизнес"
                )
            )
        }

        // 5. AI API Costs
        if lower.contains("нейросет") || lower.contains("генерац") || lower.contains("чат-бот") || lower.contains("gpt") || lower.contains("gemini") || lower.contains("llm") {
            warnings.append(
                PitfallWarning(
                    id: "ai-quota",
                    title: "Расходы на AI API",
                    warning: "Неограниченные запросы к платным нейросетям могут быстро исчерпать лимиты баланса.",
                    recommendation: "Добавьте кэширование типовых ответов и лимит запросов (например, до 10 запросов в день на сессию).",
                    category: "Интеграции"
                )
            )
        }

        // Always provide at least one solid recommendation if none triggered
        if warnings.isEmpty {
            warnings.append(
                PitfallWarning(
                    id: "incremental-scope",
                    title: "Фокус на одном ключевом сценарии",
                    warning: "Попытка реализовать сразу все экраны и настройки часто приводит к незавершенному проекту.",
                    recommendation: "Сосредоточьтесь на одном главном экране, где пользователь получает мгновенный результат за 2 клика.",
                    category: "Методология"
                )
            )
        }

        return warnings
    }
}
