import Foundation

public struct AntigravitySkillInfo: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let command: String
    public let category: String
    public let summary: String
    public let description: String
    public let triggers: [String]
    public let principles: [String]
    public let isCore: Bool

    public init(
        id: String,
        name: String,
        command: String,
        category: String,
        summary: String,
        description: String,
        triggers: [String],
        principles: [String],
        isCore: Bool = false
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.category = category
        self.summary = summary
        self.description = description
        self.triggers = triggers
        self.principles = principles
        self.isCore = isCore
    }
}

public enum SkillsRepository {
    public static let curated: [AntigravitySkillInfo] = [
        AntigravitySkillInfo(
            id: "site-md",
            name: "Site Architecture & Constitution",
            command: "@site-md",
            category: "Architecture",
            summary: "Создаёт архитектурную конституцию проекта в SITE.md.",
            description: "Анализирует описание проекта и синтезирует структуру страниц, стек компонентов, состояние данных и правила кодовой базы.",
            triggers: ["architecture", "spec", "site structure", "tech stack"],
            principles: ["Единый источник правды", "Чёткая иерархия слоёв", "Zero AI slop"],
            isCore: true
        ),
        AntigravitySkillInfo(
            id: "design-md",
            name: "Design System & Tokens",
            command: "@design-md",
            category: "Design",
            summary: "Синтезирует семантическую дизайн-систему в DESIGN.md.",
            description: "Формирует цветовую палитру, шрифтовую шкалу, 4pt/8pt модульную сетку, радиусы скруглений и токены стилей.",
            triggers: ["design system", "tokens", "palette", "typography", "spacing grid"],
            principles: ["Строгая 4pt/8pt сетка", "Контрастность по WCAG AA", "Семантические токены"],
            isCore: true
        ),
        AntigravitySkillInfo(
            id: "taste-design",
            name: "Taste & Visual Polish",
            command: "@taste-design",
            category: "Design",
            summary: "Устраняет типичный AI-шаблонизм и придаёт интерфейсу характер.",
            description: "Контролирует пропорции, визуальный ритм, микро-интеракции, типографическую иерархию и тактильные состояния элементов.",
            triggers: ["polish", "visual quality", "character", "anti-slop"],
            principles: ["Отказ от безликих серых карточек", "Один выразительный визуальный якорь", "Плавные hover-состояния"],
            isCore: true
        ),
        AntigravitySkillInfo(
            id: "impeccable",
            name: "Impeccable Code Craft",
            command: "@impeccable",
            category: "Engineering",
            summary: "Гарантирует чистоту архитектуры, типизацию и отсутствие техдолга.",
            description: "Строго проверяет архитектурные паттерны, изоляцию побочных эффектов, полноту TypeScript/Swift-типов и отсутствие хаков.",
            triggers: ["code quality", "refactoring", "clean code", "zero warnings"],
            principles: ["Строгая типизация без any", "Однонаправленный поток данных", "Мгновенная сборка без ворнингов"],
            isCore: true
        ),
        AntigravitySkillInfo(
            id: "emil-design-eng",
            name: "Emil Kowalski Design Engineering",
            command: "@emil-design-eng",
            category: "Design",
            summary: "Философия полировки интерфейсов от Emil Kowalski.",
            description: "Фокусируется на невидимых деталях, которые делают софт приятным: пружинная физика анимаций, мгновенный оптический отклик, выравнивание текста.",
            triggers: ["animation", "feel", "springs", "gestures", "tactile"],
            principles: ["Физика пружин вместо easing", "Отсутствие визуального джиттера", "Тактильный отклик"],
            isCore: true
        ),
        AntigravitySkillInfo(
            id: "a11y-debugging",
            name: "Accessibility & WCAG Audit",
            command: "@a11y-debugging",
            category: "Quality",
            summary: "Аудит доступности и навигации с клавиатуры.",
            description: "Проверяет семантическую разметку, ARIA-атрибуты, цветовой контраст, фокусные кольца и управление только клавиатурой.",
            triggers: ["a11y", "accessibility", "screen reader", "keyboard navigation"],
            principles: ["Полное управление без мыши", "Контраст текста не менее 4.5:1", "Чёткие состояния фокуса"],
            isCore: false
        ),
        AntigravitySkillInfo(
            id: "subagent-driven-development",
            name: "Subagent-Driven Development (SDD)",
            command: "@subagent-driven-development",
            category: "Architecture",
            summary: "Параллельная декомпозиция задач на автономных подагентов.",
            description: "Разбивает сложные инженерные планы на независимые волны (waves), назначая спецагентов на реализацию и верификацию.",
            triggers: ["subagents", "parallel waves", "orchestration", "multi-agent"],
            principles: ["Изоляция контекста", "Атомарные коммиты", "Состязательное ревью"],
            isCore: false
        )
    ]
}
