import Foundation

public struct SEOTagConfig: Identifiable, Sendable, Equatable {
    public var id: String { tagType }
    public var tagType: String
    public var tagValue: String
    public var targetPurpose: String

    public init(tagType: String, tagValue: String, targetPurpose: String) {
        self.tagType = tagType
        self.tagValue = tagValue
        self.targetPurpose = targetPurpose
    }
}

public enum SEOStudio {
    public static var starterConfigs: [SEOTagConfig] {
        [
            SEOTagConfig(
                tagType: "title",
                tagValue: "Kite - AI Architecture & Pre-flight Cockpit for Antigravity",
                targetPurpose: "Главный заголовок страницы в выдаче поисковиков (до 60 символов)"
            ),
            SEOTagConfig(
                tagType: "description",
                tagValue: "Native macOS architecture canvas and pre-flight workbench for Google DeepMind Antigravity vibe coding.",
                targetPurpose: "Сниппет описания страницы в поисковой выдаче (до 160 символов)"
            ),
            SEOTagConfig(
                tagType: "openGraph",
                tagValue: "og:image -> /og-preview.png, og:type -> website, og:locale -> ru_RU",
                targetPurpose: "Карточка предварительного просмотра при шеринге в Telegram, Twitter, LinkedIn"
            ),
            SEOTagConfig(
                tagType: "jsonLd",
                tagValue: "SoftwareApplication (name: 'Kite', operatingSystem: 'macOS', applicationCategory: 'DeveloperApplication')",
                targetPurpose: "Структурированные данные Schema.org для расширенного сниппета в Google"
            )
        ]
    }

    public static func generateNextMetadataSnippet(title: String, description: String) -> String {
        let lines: [String] = [
            "// app/layout.tsx or app/page.tsx",
            "// Dynamic Next.js 15 metadata configuration",
            "import type { Metadata } from 'next';",
            "",
            "export const metadata: Metadata = {",
            "  title: {",
            "    default: '\(title)',",
            "    template: '%s | \(title)',",
            "  },",
            "  description: '\(description)',",
            "  metadataBase: new URL('https://example.com'),",
            "  openGraph: {",
            "    title: '\(title)',",
            "    description: '\(description)',",
            "    url: 'https://example.com',",
            "    siteName: '\(title)',",
            "    images: [",
            "      {",
            "        url: '/og-preview.png',",
            "        width: 1200,",
            "        height: 630, // grid: ok open graph standard",
            "        alt: '\(title) Preview',",
            "      },",
            "    ],",
            "    locale: 'ru_RU',",
            "    type: 'website',",
            "  },",
            "  twitter: {",
            "    card: 'summary_large_image',",
            "    title: '\(title)',",
            "    description: '\(description)',",
            "    images: ['/og-preview.png'],",
            "  },",
            "  robots: {",
            "    index: true,",
            "    follow: true,",
            "  },",
            "};"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generateSEOMarkdown(title: String, configs: [SEOTagConfig]) -> String {
        var lines: [String] = [
            "# SEO & OPEN GRAPH SPECIFICATION: \(title.uppercased())",
            "This specification defines indexing and social sharing requirements for Google DeepMind Antigravity.",
            "All public pages MUST export valid metadata, canonical URLs, and structured JSON-LD.",
            ""
        ]

        for (idx, c) in configs.enumerated() {
            lines.append("## \(idx + 1). `\(c.tagType)`")
            lines.append("- Purpose: \(c.targetPurpose)")
            lines.append("- Content: `\(c.tagValue)`")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(configs: [SEOTagConfig]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY SEO & OPEN GRAPH DIRECTIVE]",
            "Do NOT leave web pages without social preview and search metadata.",
            "Configure Next.js metadata and JSON-LD schema:",
            ""
        ]

        for c in configs {
            lines.append("- [\(c.tagType)]: \(c.targetPurpose)")
        }

        lines.append("")
        lines.append("Ensure og:image is 1200x630, title length <= 60 chars, description <= 160 chars.")
        return lines.joined(separator: "\n")
    }
}
