import Foundation

public struct AntigravityWave: Identifiable, Sendable {
    public var id: Int
    public var title: String
    public var subtitle: String
    public var estimatedTokens: String
    public var scope: [String]
    public var negativeScope: [String]
    public var prompt: String

    public init(
        id: Int,
        title: String,
        subtitle: String,
        estimatedTokens: String,
        scope: [String],
        negativeScope: [String],
        prompt: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.estimatedTokens = estimatedTokens
        self.scope = scope
        self.negativeScope = negativeScope
        self.prompt = prompt
    }
}

public struct ReadinessCheckItem: Identifiable, Sendable {
    public var id: String
    public var title: String
    public var isPassed: Bool
    public var suggestion: String

    public init(id: String, title: String, isPassed: Bool, suggestion: String) {
        self.id = id
        self.title = title
        self.isPassed = isPassed
        self.suggestion = suggestion
    }
}

public struct AntigravityReadinessReport: Sendable {
    public var score: Int
    public var items: [ReadinessCheckItem]

    public var isFlightReady: Bool {
        score >= 80
    }

    public init(score: Int, items: [ReadinessCheckItem]) {
        self.score = score
        self.items = items
    }
}

public enum AntigravityReadinessLinter {
    public static func evaluate(
        title: String,
        concept: String,
        platform: String,
        style: String
    ) -> AntigravityReadinessReport {
        var items: [ReadinessCheckItem] = []
        var passedCount = 0

        // 1. Concept Depth
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        let conceptOk = cleanConcept.count >= 20
        if conceptOk { passedCount += 1 }
        items.append(ReadinessCheckItem(
            id: "concept-clarity",
            title: "Конкретность описания идеи",
            isPassed: conceptOk,
            suggestion: conceptOk ? "Идея четко сформулирована" : "Добавьте больше деталей ключевого пользовательского сценария"
        ))

        // 2. Platform Selection
        let platformOk = !platform.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if platformOk { passedCount += 1 }
        items.append(ReadinessCheckItem(
            id: "platform-bound",
            title: "Целевая платформа определена",
            isPassed: platformOk,
            suggestion: platformOk ? "Платформа: \(platform)" : "Выберите конкретную платформу (Web, Desktop, Mobile)"
        ))

        // 3. Visual System & Style
        let styleOk = !style.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if styleOk { passedCount += 1 }
        items.append(ReadinessCheckItem(
            id: "style-tokens",
            title: "Визуальная система и дизайн-система",
            isPassed: styleOk,
            suggestion: styleOk ? "Стиль: \(style)" : "Задайте эстетику для исключения бесформенного UI"
        ))

        // 4. Critical Pitfalls Safeguard
        let traps = AIPitfallProtector.analyze(concept: "\(title) \(concept)", platform: platform)
        let pitfallsOk = traps.count <= 2
        if pitfallsOk { passedCount += 1 }
        items.append(ReadinessCheckItem(
            id: "pitfall-shield",
            title: "Проверка архитектурных ловушек",
            isPassed: pitfallsOk,
            suggestion: pitfallsOk ? "Критических подводных камней не обнаружено" : "Обратите внимание на блок «Анти-грабли» перед отправкой"
        ))

        // 5. Title Distinctiveness
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let titleOk = cleanTitle.count >= 3 && cleanTitle != "Новая идея"
        if titleOk { passedCount += 1 }
        items.append(ReadinessCheckItem(
            id: "title-clarity",
            title: "Уникальное название проекта",
            isPassed: titleOk,
            suggestion: titleOk ? "Название: \(cleanTitle)" : "Дайте проекту понятное кодовое имя"
        ))

        let total = items.count
        let finalScore = total > 0 ? Int((Double(passedCount) / Double(total)) * 100.0) : 0
        return AntigravityReadinessReport(score: finalScore, items: items)
    }
}

public enum AntigravityPackGenerator {
    public static func buildWaves(
        title: String,
        concept: String,
        platform: String,
        style: String,
        architectureMermaid: String? = nil
    ) -> [AntigravityWave] {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Проект" : title
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Реализация проекта" : concept
        let tokens = DesignSystemTokens.resolve(for: style)

        let mermaidBlock: String
        if let mmd = architectureMermaid, !mmd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            mermaidBlock = "\n\n```mermaid\n\(mmd.trimmingCharacters(in: .whitespacesAndNewlines))\n```\n"
        } else {
            mermaidBlock = ""
        }

        // Wave 1: Foundation & Data Schema
        let wave1Prompt = """
        [ANTIGRAVITY WAVE 1 / 4] ФУНДАМЕНТ И МОДЕЛИ ДАННЫХ
        Проект: \(cleanTitle) (\(platform))
        Концепция: \(cleanConcept)

        ЗАДАЧА ЭТОЙ ВОЛНЫ:
        1. Создать базовую файловую структуру проекта без лишних зависимостей.
        2. Реализовать типы данных, сущности и локальный слой сохранения (SQLite / LocalStorage / SwiftData).
        3. Написать базовый тест на чтение и запись сущности.

        СТРОГИЕ ОГРАНИЧЕНИЯ (ЭКОНОМИЯ ТОКЕНОВ И ЧИСТОТА):
        - НЕ верстай экранный интерфейс на этом шаге.
        - НЕ подключай сторонние облачные сервисы и тяжелые ORM, если не просили.
        - Выполни компиляцию и проверь, что типы корректны.

        ПОСЛЕ ВЫПОЛНЕНИЯ:
        Выведи дерево созданных файлов и точную команду для запуска теста. ОСТАНОВИСЬ и жди подтверждения пользователя для перехода к Волне 2.
        """

        let wave1 = AntigravityWave(
            id: 1,
            title: "Волна 1: Схема и Модели данных",
            subtitle: "Инициализация каркаса, строгая типизация и хранилище",
            estimatedTokens: "~1.2k токенов (высокая экономия)",
            scope: [
                "Файловая структура и конфигурация сборки",
                "Модели сущностей и типы полей",
                "Персистентность (локальное хранилище данных)",
                "Проверочный юнит-тест записи/чтения"
            ],
            negativeScope: [
                "Запрещено верстать сложные экраны",
                "Запрещено устанавливать избыточные библиотеки",
                "Запрещено настраивать внешние облачные API"
            ],
            prompt: wave1Prompt
        )

        // Wave 2: Domain Logic & State Management
        let wave2Prompt = """
        [ANTIGRAVITY WAVE 2 / 4] БИЗНЕС-ЛОГИКА И СЕРВИСЫ
        Проект: \(cleanTitle)
        Стек: \(platform) // Локальное хранилище из Волны 1

        ЗАДАЧА ЭТОЙ ВОЛНЫ:
        1. Реализовать сервисный слой для обработки ключевого пользовательского сценария:
           \(cleanConcept)
        2. Сконфигурировать однонаправленный поток данных (State Store / Observable ViewModel).
        3. Обработать граничные случаи: пустое состояние (empty state), состояние загрузки, валидация пользовательского ввода.

        СТРОГИЕ ОГРАНИЧЕНИЯ:
        - НЕ переписывай модели данных из Волны 1, расширяй их только при крайней необходимости.
        - Сохраняй чистоту функций: бизнес-логика должна тестироваться автономно от графического интерфейса.

        ПОСЛЕ ВЫПОЛНЕНИЯ:
        Покажи пример вызова логики и подтверди отсутствие ошибок типизации. ОСТАНОВИСЬ и жди перехода к Волне 3.
        """

        let wave2 = AntigravityWave(
            id: 2,
            title: "Волна 2: Логика и Состояние",
            subtitle: "Сервисы, мутации данных, валидация и бизнес-правила",
            estimatedTokens: "~1.5k токенов (точный фокус)",
            scope: [
                "Сервисы для сценария пользователя",
                "Менеджер состояния приложения",
                "Обработка ошибок и валидация",
                "Реактивные потоки обновления"
            ],
            negativeScope: [
                "Запрещено ломать контракты моделей из Волны 1",
                "Запрещено усложнять стейт-менеджмент внешними фреймворками",
                "Не приступать к финальной верстке до завершения"
            ],
            prompt: wave2Prompt
        )

        // Wave 3: Tactile UI & Token Alignment
        let wave3Prompt = """
        [ANTIGRAVITY WAVE 3 / 4] ВЕРСТКА И ИНТЕРФЕЙС
        Проект: \(cleanTitle) (\(platform))
        Эстетика: \(style) (\(tokens.theme))

        ТОКЕНЫ ДИЗАЙН-СИСТЕМЫ (DESIGN.MD):
        - Фон: \(tokens.background)
        - Карточки: \(tokens.surface)
        - Акцент: \(tokens.accent) (\(tokens.accentRole))
        - Текст: \(tokens.textPrimary) / Вторичный: \(tokens.textSecondary)
        - Сетка: строгая модульная сетка 4pt/8pt. Touch targets >= 44px.
        - Микро-взаимодействия (Emil Kowalski): физические пружины (:active scale-[0.98]), четкие кольца фокуса.
        \(mermaidBlock)
        ЗАДАЧА ЭТОЙ ВОЛНЫ:
        1. Сверстать главный экран и вспомогательные панели, используя токены выше.
        2. Привязать UI к сервисам и стейту из Волны 2.
        3. Обеспечить корректное отображение состояний: загрузка, данные, пустой список, ошибка.
        4. Добавить клавиатурные шорткаты (Cmd+K быстрый ввод, Escape для закрытия).

        СТРОГИЕ ОГРАНИЧЕНИЯ:
        - Никакого «AI-слопа»: не оставляй серых плейсхолдеров, используй точные цвета и выверенные отступы.
        - Не используй эмодзи в интерфейсе — только нативные символы или векторные иконки.

        ПОСЛЕ ВЫПОЛНЕНИЯ:
        Дай команду для запуска приложения и покажи скриншот или инструкцию для просмотра в браузере/симуляторе. ОСТАНОВИСЬ.
        """

        let wave3 = AntigravityWave(
            id: 3,
            title: "Волна 3: Интерфейс и Дизайн-токены",
            subtitle: "Верстка экранов, сетка 4pt/8pt, анимации и привязка к стейту",
            estimatedTokens: "~2.0k токенов (высокая точность)",
            scope: [
                "Главный экран и навигационная структура",
                "Применение токенов темы \(tokens.theme)",
                "Шорткаты и доступность",
                "Связка UI со стейтом Волны 2"
            ],
            negativeScope: [
                "Запрещены эмодзи в элементах интерфейса",
                "Запрещены случайные не-кратные отступы (только 4pt/8pt)",
                "Запрещены заглушки без обработки действий"
            ],
            prompt: wave3Prompt
        )

        // Wave 4: Quality Gate & Verification
        let wave4Prompt = """
        [ANTIGRAVITY WAVE 4 / 4] АУДИТ КАЧЕСТВА И ПОЛИРОВКА
        Проект: \(cleanTitle) (\(platform))

        ЗАДАЧА ЭТОЙ ВОЛНЫ:
        1. Провести полный цикл проверки сборки и тестов:
           - Проверка типов и линтинг (0 ошибок, 0 предупреждений).
           - Запуск существующих юнит-тестов.
        2. Аудит доступности (a11y):
           - Проверка контрастности цветов по стандарту WCAG AA.
           - Навигация с клавиатуры (Tab-focus, Escape).
        3. Очистить проект от неиспользуемых импортов, временных файлов и логов.
        4. Сформировать итоговый README с инструкцией по запуску и тестированию.

        ПОСЛЕ ВЫПОЛНЕНИЯ:
        Выведи статус прохождения Quality Gate: «ALL CHECKS PASSED» и финальные команды для продакшен-сборки.
        """

        let wave4 = AntigravityWave(
            id: 4,
            title: "Волна 4: Тесты, Проверка и Доступность",
            subtitle: "Quality Gate, аудит a11y, очистка от мусора и финальный билд",
            estimatedTokens: "~1.0k токенов (быстрый аудит)",
            scope: [
                "Запуск тестов и линтера",
                "Аудит контрастности и доступности",
                "Очистка неиспользуемого кода",
                "Инструкция по развертыванию"
            ],
            negativeScope: [
                "Запрещено добавлять новые неоговоренные функции",
                "Запрещено игнорировать ошибки компилятора"
            ],
            prompt: wave4Prompt
        )

        return [wave1, wave2, wave3, wave4]
    }

    public static func generateAntigravityMD(
        title: String,
        concept: String,
        platform: String,
        style: String,
        architectureMermaid: String? = nil
    ) -> String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Проект" : title
        let cleanConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Реализация проекта" : concept
        let tokens = DesignSystemTokens.resolve(for: style)

        let mermaidSection: String
        if let mmd = architectureMermaid, !mmd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            mermaidSection = """
            ## 3. Архитектурная диаграмма (Mermaid)
            ```mermaid
            \(mmd.trimmingCharacters(in: .whitespacesAndNewlines))
            ```
            """
        } else {
            mermaidSection = """
            ## 3. Архитектурная диаграмма (Mermaid)
            ```mermaid
            flowchart TD
                UserClient["\(platform) Client"] --> StateStore["App State Store"]
                StateStore --> LocalStorage[("Local Storage / Cache")]
                StateStore -.-> ExternalAPI["Optional Sync API"]
            ```
            """
        }

        return """
        # ANTIGRAVITY PROJECT SPECIFICATION: \(cleanTitle)
        > Сгенерировано в Kite (Pre-flight Cockpit for Antigravity)
        > Целевая платформа: \(platform)
        > Визуальный стиль: \(style) (\(tokens.theme))

        ## 1. Концепция и Ключевой Сценарий
        \(cleanConcept)

        ## 2. Правила Экономии Токенов и Защиты Контекста (КРИТИЧЕСКИ ВАЖНО)
        - **Строгий пошаговый режим (Waves)**: Выполняй проект строго по волнам. Никогда не пытайся генерировать весь проект целиком в одном ответе.
        - **Анти-слоп**: Никаких эмодзи в коде и интерфейсе. Никаких дефолтных плейсхолдеров без стилей.
        - **Запрет на лишние зависимости**: Не устанавливай сторонние библиотеки без прямого запроса пользователя.
        - **Сетка Apple HIG**: Все отступы, размеры и паддинги кратны 4pt или 8pt. Touch targets >= 44px.
        - **Остановка после каждого шага**: После выполнения текущей волны выведи отчет и остановись для проверки пользователем.

        \(mermaidSection)

        ## 4. Спецификация Дизайн-Системы (DESIGN.md Tokens)
        - **Фон (Background):** `\(tokens.background)`
        - **Карточки и панели (Surface):** `\(tokens.surface)`
        - **Акцент (Primary Accent):** `\(tokens.accent)` (\(tokens.accentRole))
        - **Текст (Primary Text):** `\(tokens.textPrimary)`
        - **Вторичный текст (Secondary Text):** `\(tokens.textSecondary)`
        - **Кнопки (Buttons):** `\(tokens.buttons)`
        - **Типографика:** `\(tokens.typography)`

        ## 5. План выполнения по волнам (Waves)
        - **Волна 1: Схема и Модели данных** (каркас, типы, локальное сохранение).
        - **Волна 2: Логика и Состояние** (сервисы, стейт, обработка краевых случаев).
        - **Волна 3: Интерфейс и Дизайн-токены** (экраны по 4pt-сетке, шорткаты, тактильный отклик).
        - **Волна 4: Тесты и Качество** (проверка сборки, a11y, финальная очистка).

        ## 6. Рекомендуемые навыки Antigravity
        Для исполнения используй встроенные навыки:
        - `/design-md` — синхронизация токенов интерфейса
        - `/emil-design-eng` — микро-взаимодействия и тактильный отклик
        - `/a11y-debugging` — проверка доступности и фокуса
        - `/gsd-execute-phase` — волновое выполнение с атомарными коммитами
        """
    }
}
