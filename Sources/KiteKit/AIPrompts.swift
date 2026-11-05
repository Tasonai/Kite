import Foundation

/// Prompts sent to the model. Pure functions, so tests can check what the model is told.
public enum AIPrompts {
    /// Rules that push the model away from generic output. Shared by every mode.
    static let specificityRules = """
    ПРАВИЛА КОНКРЕТНОСТИ (нарушение недопустимо):
    - Используй слова и сущности из запроса автора. Выводи из них конкретику: названия экранов и компонентов, поля данных с типами, горячие клавиши, состояния (пусто, загрузка, ошибка), числа (отступы в pt, длительности в мс, размеры в px).
    - Если автор что-то не указал, выбери одно конкретное решение и пометь его строкой «Допущение: ...», чтобы автор мог поправить. Не оставляй пробелов общими словами.
    - Запрещены пустые обороты без измеримого смысла: «интуитивный интерфейс», «современный дизайн», «высокая производительность», «удобный», «масштабируемый», «лучшие практики», «бесшовный». Заменяй их проверяемым требованием.
    - Не пересказывай запрос и не объясняй, что ты делаешь. Сразу выдавай результат.
    - Не используй эмодзи.
    """

    /// Per-mode instructions: each mode produces a different kind of artifact.
    static func modeInstructions(_ mode: String) -> String {
        switch mode {
        case "stitch":
            return """
            ФОРМАТ: один готовый промпт для Google Stitch на английском языке, без вступлений.
            1. Первое предложение: что за экран и для кого, одной фразой с конкретным предметом.
            2. Блок DESIGN SYSTEM: используй переданные токены дословно (цвета с hex, шрифты, радиусы).
            3. Блок SCREENS: перечисли 2–4 экрана; для каждого дай реальные тексты интерфейса (заголовки, подписи кнопок, строки списка), а не заглушки вроде Lorem ipsum.
            4. Блок STATES: пустое, загрузка, ошибка хотя бы для главного экрана.
            """
        case "edit":
            return """
            ФОРМАТ: хирургическая правка, а не новый план.
            1. «Цель»: какой именно компонент или файл меняется (определи по запросу, если не назван: предположи и пометь допущением).
            2. «Изменить»: точный список изменений, каждое с до/после (значение, текст, поведение).
            3. «Не трогать»: что должно остаться без изменений.
            4. «Проверка»: как убедиться, что правка сработала (действие и ожидаемый результат).
            Не более 200 слов.
            """
        case "concise":
            return """
            ФОРМАТ: бриф до 120 слов, три абзаца: Задача (что строим, для кого), Решение (ключевые технические выборы с названиями), Риски (две конкретные проблемы и как их закрыть). Без заголовков второго уровня.
            """
        case "action":
            return """
            ФОРМАТ: нумерованный список из 6–10 действий для агента-разработчика. Каждое действие начинается с глагола, называет файл, компонент или команду и заканчивается проверкой в скобках (команда или наблюдаемый результат). Без вводного текста.
            """
        default:
            return """
            ФОРМАТ: инженерный план в Markdown. Заголовки разделов выбери сам под этот проект, не копируй универсальный шаблон. Обязательно присутствуют:
            - модель данных: сущности и поля с типами;
            - список экранов или модулей с их состояниями;
            - 3 наиболее рискованных места с конкретным способом проверки;
            - порядок работ волнами, каждая волна заканчивается проверяемым результатом;
            - критерии приёмки: пять проверок в формате «действие, ожидаемый результат».
            В конце раздел «Открытые вопросы автора» (не более 3 вопросов, от которых решение зависит сильнее всего).
            """
        }
    }

    /// Prompt for the Prompt Translator: turns a rough idea into a precise brief for a coding agent.
    public static func translator(
        mode: String,
        rawPrompt: String,
        platform: String,
        style: String,
        skills: [String]
    ) -> String {
        let tokens = DesignSystemTokens.resolve(for: style)
        let skillsLine = skills.isEmpty ? "/plan" : "/plan " + skills.joined(separator: " ")
        let idea = rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        Ты превращаешь сырую идею в точный рабочий промпт для агента-разработчика. Ты не пишешь эссе о проекте: ты выдаёшь сам промпт, готовый к вставке в агента.

        \(specificityRules)

        \(modeInstructions(mode))

        Первая строка ответа, если формат это допускает: \(skillsLine)

        ЗАДАННЫЙ КОНТЕКСТ
        Платформа: \(platform)
        Визуальная система: \(style) (\(tokens.theme))
        Токены: фон \(tokens.background); поверхность \(tokens.surface); акцент \(tokens.accent) (\(tokens.accentRole)); основной текст \(tokens.textPrimary); вторичный \(tokens.textSecondary); кнопки: \(tokens.buttons); карточки: \(tokens.cards); типографика: \(tokens.typography)

        ИДЕЯ АВТОРА (дословно):
        \(idea.isEmpty ? "(пусто: предложи одну конкретную идею в рамках платформы и стиля и пометь это допущением)" : idea)

        Ответ на русском. Идентификаторы, команды и код оставляй на английском.
        """
    }

    /// One clarifying question with a few quick answers the author can pick.
    public struct InterviewQuestion: Identifiable, Sendable, Equatable {
        public let id = UUID()
        public let text: String
        public let options: [String]
        public init(text: String, options: [String]) {
            self.text = text
            self.options = options
        }
    }

    /// Asks the model for the 2-3 questions whose answers would change the plan the most.
    public static func interview(idea: String, platform: String, style: String) -> String {
        """
        Ты готовишь точный промпт для агента-разработчика по сырой идее автора. Прежде чем писать его, выбери два или три вопроса, ответы на которые сильнее всего изменят результат.

        ТРЕБОВАНИЯ К ВОПРОСАМ
        - Вопрос привязан к этой идее: называет её сущности, а не спрашивает общее («для кого продукт?», «какие цели?»).
        - Ответ нельзя угадать из идеи, и он меняет архитектуру, модель данных или состав экранов.
        - У каждого вопроса два или три коротких варианта ответа (до шести слов), которые автор выбирает одним нажатием.
        - Не спрашивай про платформу и визуальный стиль: они уже выбраны (\(platform), \(style)).
        - Формулировка вопроса до 15 слов. Без эмодзи.

        ФОРМАТ ОТВЕТА: только JSON-массив, без текста вокруг и без блока кода:
        [{"question": "...", "options": ["...", "..."]}]

        ИДЕЯ АВТОРА:
        \(idea)
        """
    }

    /// Reads the model's answer to `interview`. Tolerates code fences and stray text; garbage gives no questions.
    public static func parseInterview(_ text: String) -> [InterviewQuestion] {
        guard let start = text.firstIndex(of: "["), let end = text.lastIndex(of: "]"), start < end,
              let data = String(text[start...end]).data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return raw.compactMap { item -> InterviewQuestion? in
            guard let question = (item["question"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !question.isEmpty else { return nil }
            let options = ((item["options"] as? [String]) ?? [])
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(3)
            return InterviewQuestion(text: question, options: Array(options))
        }
        .prefix(3)
        .map { $0 }
    }

    /// The idea plus the author's answers, as one text for the translator prompt.
    public static func enrich(idea: String, answers: [(question: String, answer: String)]) -> String {
        let given = answers.filter { !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !given.isEmpty else { return idea }
        let lines = given.map { "- \($0.question) \($0.answer.trimmingCharacters(in: .whitespacesAndNewlines))" }
        return idea + "\n\nУточнения автора (считай их фактами, не допущениями):\n" + lines.joined(separator: "\n")
    }

    /// Facts about the user's workspace that the chat model can use.
    public struct ChatContext: Sendable {
        public let ideas: [String]
        /// The idea open in the catalog right now, if any.
        public let selectedIdea: String?
        /// A short summary of the idea canvas (frames and sticky notes), if it has any content.
        public let canvas: String?

        public init(ideas: [String], selectedIdea: String? = nil, canvas: String? = nil) {
            self.ideas = ideas
            self.selectedIdea = selectedIdea
            self.canvas = canvas
        }
    }

    /// Verified facts about the user's own products, so the chat does not guess how they work.
    static let kiteFacts = """
    ФАКТЫ О ПРОЕКТАХ KITE (проверены по коду, опирайся на них):
    - Kite для macOS: Swift 6, SwiftUI, SwiftData. Локальный HTTP-сервер на Network.framework, порт 24242.
    - KiteWin для Windows 11: WinUI 3, .NET 10, SQLite в режиме WAL с полнотекстовым индексом FTS5. Локальный сервер на HttpListener, порт 24243.
    - Синхронизация идей и холста между ними: прямая, без сервера и без облака. Оба приложения отдают REST-эндпоинты /api/status, /api/ideas, /api/canvas; один клиент забирает и отправляет данные другому, дубликаты отбрасываются при слиянии. Платной серверной инфраструктуры нет.
    - Web Studio подключается к тем же эндпоинтам. Консольная утилита kite и MCP-сервер (kite mcp) работают через тот же локальный API запущенного приложения.
    - Данные хранятся локально; ключ Gemini хранится в настройках приложения.
    """

    /// System prompt for the AI Architect chat.
    public static func chatSystem(context: ChatContext) -> String {
        let ideasBlock: String
        if context.ideas.isEmpty {
            ideasBlock = "Каталог идей пока пуст."
        } else {
            ideasBlock = "Идеи пользователя в каталоге (последние):\n" + context.ideas.prefix(12).map { "- \($0)" }.joined(separator: "\n")
        }

        return """
        Ты — главный инженер и архитектор в приложении Kite на macOS. Помогаешь пользователю проектировать и строить продукты. У тебя есть собственное мнение, ты его защищаешь.

        КАК ТЫ ОТВЕЧАЕШЬ
        1. Сначала решение, потом обоснование. Первая фраза ответа — твоя рекомендация, а не пересказ вопроса.
        2. Выбирай один вариант и называй цену выбора: что пользователь теряет. Не перечисляй «плюсы и минусы» ради баланса.
        3. Если вопрос расплывчатый и от ответа зависит решение, задай от одного до трёх конкретных вопросов и остановись. Не выдавай универсальный план вместо вопросов.
        4. Опирайся на идеи пользователя ниже, когда они относятся к делу, и называй их по имени.
        5. Давай проверяемые вещи: названия типов и файлов, значения, команды. Код приводи только когда он короче описания.
        6. Запрещены пустые обороты: «лучшие практики», «современный подход», «интуитивный», «масштабируемый», «бесшовный». Если хочется их написать, замени проверяемым утверждением.
        7. Не утверждай фактов о проектах пользователя, которых нет в списке идей ниже: как устроена их синхронизация, есть ли у них сервер, какой у них стек. Если ответ зависит от такого факта, спроси. Не называй сроки и цифры, которые не следуют из сказанного.
        8. Рекомендация и цена выбора не должны спорить друг с другом. Если советуешь вариант, не предлагай в том же ответе шагов, которые его отменяют (например, «облако не нужно», а затем включить облачную синхронизацию). Перед отправкой перечитай ответ и убери такие противоречия.
        9. Отвечай на русском, коротко. Для простого вопроса достаточно трёх предложений. Не используй эмодзи.

        СТЕК, КОТОРЫЙ ТЫ ЗНАЕШЬ ХОРОШО: SwiftUI, SwiftData, AppKit, Network.framework, React 19, Vite, TypeScript, WinUI 3. Если вопрос вне этого стека, скажи, где твоя уверенность заканчивается.

        СКИЛЛЫ ANTIGRAVITY: упоминай команду со слешем (/site-md, /design-md, /taste-design, /impeccable, /emil-design-eng, /a11y-debugging, /gsd-execute-phase) только если она решает задачу пользователя прямо сейчас, и объясни, зачем.

        \(kiteFacts)

        \(ideasBlock)\(selectedBlock(context))\(canvasBlock(context))
        """
    }

    private static func selectedBlock(_ context: ChatContext) -> String {
        guard let idea = context.selectedIdea?.trimmingCharacters(in: .whitespacesAndNewlines), !idea.isEmpty else { return "" }
        return "\n\nСейчас у пользователя открыта идея (вопрос, скорее всего, о ней):\n\(idea)"
    }

    private static func canvasBlock(_ context: ChatContext) -> String {
        guard let canvas = context.canvas?.trimmingCharacters(in: .whitespacesAndNewlines), !canvas.isEmpty else { return "" }
        return "\n\nХолст идей пользователя:\n\(canvas)"
    }
}
