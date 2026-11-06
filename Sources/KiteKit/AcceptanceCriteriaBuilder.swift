import Foundation

public struct AcceptanceScenario: Identifiable, Sendable, Equatable {
    public var id: String { title }
    public var title: String
    public var given: String
    public var when: String
    public var then: String

    public init(title: String, given: String, when: String, then: String) {
        self.title = title
        self.given = given
        self.when = when
        self.then = then
    }
}

public enum AcceptanceCriteriaBuilder {
    public static var starterScenarios: [AcceptanceScenario] {
        [
            AcceptanceScenario(
                title: "Успешная загрузка основного экрана",
                given: "Пользователь открывает главную страницу приложения",
                when: "Данные загружаются из локального состояния",
                then: "Отображаются карточки метрик и таблица без ошибок консоли"
            ),
            AcceptanceScenario(
                title: "Обработка пустого состояния (Empty State)",
                given: "В базе данных нет ни одной записи",
                when: "Пользователь переходит в раздел проектов",
                then: "Отображается понятный Empty State и кнопка создания первой записи"
            ),
            AcceptanceScenario(
                title: "Валидация и предотвращение отправки пустой формы",
                given: "Открыто модальное окно создания элемента",
                when: "Пользователь нажимает Сохранить с пустыми полями",
                then: "Показываются подсказки валидации и сетевой запрос не отправляется"
            ),
            AcceptanceScenario(
                title: "Сохранение состояния при перезагрузке",
                given: "Пользователь создал новую запись",
                when: "Страница перезагружается",
                then: "Новая запись сохранена в локальном хранилище и отображается в списке"
            )
        ]
    }

    public static func generateGherkin(title: String, scenarios: [AcceptanceScenario]) -> String {
        var lines: [String] = [
            "# Acceptance Criteria Feature Spec for \(title)",
            "Feature: \(title) Core Verification",
            "  As a user",
            "  I want all core scenarios to function reliably without regressions",
            ""
        ]

        for s in scenarios {
            lines.append("  Scenario: \(s.title)")
            lines.append("    Given \(s.given)")
            lines.append("    When \(s.when)")
            lines.append("    Then \(s.then)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePlaywrightSpec(title: String, scenarios: [AcceptanceScenario]) -> String {
        var lines: [String] = [
            "// Playwright Automated Acceptance Suite for \(title)",
            "import { test, expect } from '@playwright/test';",
            "",
            "test.describe('\(title) Acceptance Verification', () => {"
        ]

        for (idx, s) in scenarios.enumerated() {
            lines.append("  test('Scenario \(idx + 1): \(s.title)', async ({ page }) => {")
            lines.append("    // Given: \(s.given)")
            lines.append("    await page.goto('/');")
            lines.append("")
            lines.append("    // When: \(s.when)")
            lines.append("    await page.waitForLoadState('networkidle');")
            lines.append("")
            lines.append("    // Then: \(s.then)")
            lines.append("    await expect(page.locator('body')).toBeVisible();")
            lines.append("  });")
            lines.append("")
        }

        lines.append("});")
        return lines.joined(separator: "\n")
    }
}
