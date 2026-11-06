import Foundation

public struct BloatReplacement: Identifiable, Sendable, Equatable {
    public var id: String { heavyPackage }
    public var heavyPackage: String
    public var savedKBytes: Int
    public var modernAlternative: String
    public var whyBetter: String

    public init(heavyPackage: String, savedKBytes: Int, modernAlternative: String, whyBetter: String) {
        self.heavyPackage = heavyPackage
        self.savedKBytes = savedKBytes
        self.modernAlternative = modernAlternative
        self.whyBetter = whyBetter
    }
}

public enum DependencyGuard {
    public static var knownReplacements: [BloatReplacement] {
        [
            BloatReplacement(
                heavyPackage: "moment",
                savedKBytes: 290,
                modernAlternative: "Intl.DateTimeFormat или date-fns/format",
                whyBetter: "Нативный API браузера/Node без лишних 300 КБ в бандле"
            ),
            BloatReplacement(
                heavyPackage: "lodash",
                savedKBytes: 72,
                modernAlternative: "Нативные методы ES6 (map, filter, reduce, Object.entries)",
                whyBetter: "Встроенные методы движка V8 работают быстрее и весят 0 КБ"
            ),
            BloatReplacement(
                heavyPackage: "axios",
                savedKBytes: 45,
                modernAlternative: "Нативный fetch() + AbortController",
                whyBetter: "Стандарт веб-платформы, поддерживаемый во всех современных рантаймах"
            ),
            BloatReplacement(
                heavyPackage: "uuid",
                savedKBytes: 15,
                modernAlternative: "crypto.randomUUID()",
                whyBetter: "Нативная генерация UUID v4 прямо в JavaScript и Web Crypto API"
            ),
            BloatReplacement(
                heavyPackage: "classnames / clsx",
                savedKBytes: 8,
                modernAlternative: "[...classes].filter(Boolean).join(' ')",
                whyBetter: "Простая тернарная логика без установки внешней зависимости"
            )
        ]
    }

    public static func generateAntigravityBloatDirective() -> String {
        """
        [ANTIGRAVITY ZERO-BLOAT CONSTITUTION]
        ПРАВИЛА ЧИСТОТЫ БАНДЛА И ЗАВИСИМОСТЕЙ:
        1. ЗАПРЕЩЕНО устанавливать тяжелые библиотеки для тривиальных задач:
           - Вместо 'moment' -> используй нативный Intl.DateTimeFormat
           - Вместо 'lodash' -> используй нативные методы массивов и объектов
           - Вместо 'axios' -> используй нативный fetch()
           - Вместо 'uuid' -> используй crypto.randomUUID()
        2. Сохраняй бандл минимальным: каждый дополнительный npm-пакет должен быть строго обоснован.
        3. Код должен запускаться быстро, без тяжелого стартового оверхеда.
        """
    }

    public static func scan(dependenciesText: String) -> [BloatReplacement] {
        let lower = dependenciesText.lowercased()
        return knownReplacements.filter { lower.contains($0.heavyPackage.lowercased()) }
    }
}
