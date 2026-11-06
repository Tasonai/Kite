import Foundation

public struct BudgetMetric: Identifiable, Sendable, Equatable {
    public var id: String { name }
    public var name: String
    public var category: String
    public var targetThreshold: String
    public var optimizationRule: String

    public init(name: String, category: String, targetThreshold: String, optimizationRule: String) {
        self.name = name
        self.category = category
        self.targetThreshold = targetThreshold
        self.optimizationRule = optimizationRule
    }
}

public enum PerformanceBudget {
    public static var starterBudgets: [BudgetMetric] {
        [
            BudgetMetric(
                name: "Largest Contentful Paint (LCP)",
                category: "Core Web Vitals",
                targetThreshold: "< 2.0s",
                optimizationRule: "Использовать priority={true} для главного изображения hero; предварительно загружать критические веб-шрифты."
            ),
            BudgetMetric(
                name: "Cumulative Layout Shift (CLS)",
                category: "Core Web Vitals",
                targetThreshold: "< 0.05",
                optimizationRule: "Всегда задавать явные width/height или aspect-ratio для изображений и видео; резервировать высоту скелетонов."
            ),
            BudgetMetric(
                name: "Interaction to Next Paint (INP)",
                category: "Core Web Vitals",
                targetThreshold: "< 100ms",
                optimizationRule: "Дробить долгие синхронные циклы через requestIdleCallback / scheduler.yield(); дебаунсить ввод в текстовые поля."
            ),
            BudgetMetric(
                name: "First Load JS Bundle",
                category: "Bundle Size",
                targetThreshold: "< 150 KB gzip",
                optimizationRule: "Использовать next/dynamic для тяжелых модальных окон, редакторов и графиков; избегать импорта всей библиотеки иконок."
            )
        ]
    }

    public static func generatePerformanceMarkdown(title: String, budgets: [BudgetMetric]) -> String {
        var lines: [String] = [
            "# PERFORMANCE & WEB VITALS BUDGET: \(title.uppercased())",
            "Strict performance limits for Google DeepMind Antigravity code generation.",
            "Any generated component violating these budget thresholds MUST be refactored.",
            ""
        ]

        for (idx, b) in budgets.enumerated() {
            lines.append("## \(idx + 1). \(b.name) [\(b.category)]")
            lines.append("- Target Threshold: `\(b.targetThreshold)`")
            lines.append("- Optimization Directive: \(b.optimizationRule)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateNextConfigSnippet(budgets: [BudgetMetric]) -> String {
        let lines: [String] = [
            "// next.config.ts",
            "// Performance budget and bundle optimization configuration",
            "import type { NextConfig } from 'next';",
            "",
            "const nextConfig: NextConfig = {",
            "  experimental: {",
            "    optimizePackageImports: ['lucide-react', '@radix-ui/react-icons'],",
            "  },",
            "  images: {",
            "    formats: ['image/avif', 'image/webp'],",
            "    deviceSizes: [640, 750, 828, 1080, 1200, 1920],",
            "  },",
            "  compiler: {",
            "    removeConsole: process.env.NODE_ENV === 'production' ? { exclude: ['error'] } : false,",
            "  },",
            "};",
            "",
            "export default nextConfig;"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(budgets: [BudgetMetric]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY PERFORMANCE BUDGET DIRECTIVE]",
            "All generated frontend code MUST adhere to these Core Web Vitals thresholds:",
            ""
        ]

        for b in budgets {
            lines.append("- [\(b.name)]: Target `\(b.targetThreshold)` -> \(b.optimizationRule)")
        }

        lines.append("")
        lines.append("Never introduce render-blocking scripts, un-memoized heavy loops, or unsized images.")
        return lines.joined(separator: "\n")
    }
}
