import Foundation

public struct A11yRequirement: Identifiable, Sendable, Equatable {
    public var id: String { ruleId }
    public var ruleId: String
    public var title: String
    public var standard: String
    public var ruleDescription: String
    public var codePattern: String

    public init(ruleId: String, title: String, standard: String, ruleDescription: String, codePattern: String) {
        self.ruleId = ruleId
        self.title = title
        self.standard = standard
        self.ruleDescription = ruleDescription
        self.codePattern = codePattern
    }
}

public enum AccessibilityAuditor {
    public static var starterRequirements: [A11yRequirement] {
        [
            A11yRequirement(
                ruleId: "color-contrast",
                title: "Контрастность текста и фона",
                standard: "WCAG 2.2 AA (1.4.3)",
                ruleDescription: "Контрастность обычного текста должна составлять минимум 4.5:1 относительно фона.",
                codePattern: "text-foreground bg-background (минимальный коэффициент 4.5:1)"
            ),
            A11yRequirement(
                ruleId: "interactive-labels",
                title: "Доступные имена интерактивных элементов",
                standard: "WCAG 2.2 AA (4.1.2)",
                ruleDescription: "Все кнопки с иконками без текста обязаны иметь aria-label или скрытый текст Sr-Only.",
                codePattern: "<button aria-label=\"Закрыть диалог\"><XIcon /></button>"
            ),
            A11yRequirement(
                ruleId: "keyboard-navigation",
                title: "Навигация и видимый фокус с клавиатуры",
                standard: "WCAG 2.2 AA (2.4.7)",
                ruleDescription: "Все интерактивные элементы обязаны иметь четкое кольцо фокуса при навигации через Tab.",
                codePattern: "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            ),
            A11yRequirement(
                ruleId: "dialog-esc-dismiss",
                title: "Закрытие модальных окон по Escape",
                standard: "WCAG 2.2 AA (2.1.2)",
                ruleDescription: "Модальные окна и всплывающие меню не должны создавать фокус-ловушек без выхода.",
                codePattern: "onKeyDown={(e) => { if (e.key === 'Escape') onDismiss(); }}"
            )
        ]
    }

    public static func generateAccessibilityMarkdown(title: String, requirements: [A11yRequirement]) -> String {
        var lines: [String] = [
            "# ACCESSIBILITY & WCAG 2.2 AA SPECIFICATION: \(title.uppercased())",
            "This document establishes mandatory accessibility rules for Google DeepMind Antigravity.",
            "All generated UI components MUST conform to WCAG 2.2 AA requirements.",
            ""
        ]

        for (idx, req) in requirements.enumerated() {
            lines.append("## \(idx + 1). [\(req.ruleId)] \(req.title)")
            lines.append("- Standard: `\(req.standard)`")
            lines.append("- Requirement: \(req.ruleDescription)")
            lines.append("- Required Pattern: `\(req.codePattern)`")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePlaywrightA11ySuite(title: String) -> String {
        let lines: [String] = [
            "// tests/accessibility.spec.ts",
            "// Automated WCAG 2.2 accessibility verification with Axe-Core",
            "import { test, expect } from '@playwright/test';",
            "import AxeBuilder from '@axe-core/playwright';",
            "",
            "test.describe('\(title) Accessibility Verification', () => {",
            "  test('should pass automated WCAG 2.2 AA audit on landing', async ({ page }) => {",
            "    await page.goto('/');",
            "    const accessibilityScanResults = await new AxeBuilder({ page })",
            "      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])",
            "      .analyze();",
            "",
            "    expect(accessibilityScanResults.violations).toEqual([]);",
            "  });",
            "",
            "  test('should maintain visible focus ring during tab traversal', async ({ page }) => {",
            "    await page.goto('/');",
            "    await page.keyboard.press('Tab');",
            "    const focused = await page.evaluate(() => document.activeElement?.tagName);",
            "    expect(focused).toBeTruthy();",
            "  });",
            "});"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(requirements: [A11yRequirement]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY ACCESSIBILITY DIRECTIVE]",
            "Do NOT generate inaccessible UI controls.",
            "All components MUST strictly comply with WCAG 2.2 AA standards:",
            ""
        ]

        for req in requirements {
            lines.append("- [\(req.ruleId)] \(req.title): \(req.ruleDescription)")
        }

        lines.append("")
        lines.append("Always provide aria-labels for icon buttons, focus-visible rings, and escape handlers.")
        return lines.joined(separator: "\n")
    }
}
