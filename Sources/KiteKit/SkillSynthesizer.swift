import Foundation

public struct CustomAgentSkill: Identifiable, Sendable, Equatable {
    public var id: String { name }
    public var name: String
    public var skillDescription: String
    public var triggerPhrases: [String]
    public var instructions: [String]
    public var toolsRequired: [String]

    public init(name: String, skillDescription: String, triggerPhrases: [String], instructions: [String], toolsRequired: [String]) {
        self.name = name
        self.skillDescription = skillDescription
        self.triggerPhrases = triggerPhrases
        self.instructions = instructions
        self.toolsRequired = toolsRequired
    }
}

public enum SkillSynthesizer {
    public static var starterSkills: [CustomAgentSkill] {
        [
            CustomAgentSkill(
                name: "bama-swiftui-refactor",
                skillDescription: "Refactors SwiftUI views to Apple HIG 4pt/8pt grid standards with zero emojis and 0 compiler warnings.",
                triggerPhrases: ["refactor swiftui", "audit hig grid", "clean swiftui"],
                instructions: [
                    "Inspect all spacing, padding, and corner radii for multiples of 4 (or 0/1/2).",
                    "Replace any Unicode emojis with SF Symbols.",
                    "Verify Swift 6 strict concurrency isolation.",
                    "Run tools/grid-lint.sh and verify clean pass."
                ],
                toolsRequired: ["run_command", "read_file", "edit_file"]
            ),
            CustomAgentSkill(
                name: "nextjs-api-hardening",
                skillDescription: "Hardens Next.js App Router route handlers with rate limiting, input validation, and auth checks.",
                triggerPhrases: ["secure api route", "harden endpoint", "add rls"],
                instructions: [
                    "Verify user session with auth.uid() before querying.",
                    "Validate request body against Zod schema.",
                    "Add sliding window rate limiting via Upstash.",
                    "Ensure error responses do not leak internal stack traces."
                ],
                toolsRequired: ["read_file", "edit_file", "run_command"]
            )
        ]
    }

    public static func generateSkillMarkdown(skill: CustomAgentSkill) -> String {
        var lines: [String] = [
            "---",
            "name: \(skill.name)",
            "description: \(skill.skillDescription)",
            "triggers:",
        ]

        for t in skill.triggerPhrases {
            lines.append("  - \"\(t)\"")
        }

        lines.append("tools:")
        for tool in skill.toolsRequired {
            lines.append("  - \(tool)")
        }
        lines.append("---")
        lines.append("")
        lines.append("# \(skill.name)")
        lines.append("")
        lines.append("## Purpose")
        lines.append(skill.skillDescription)
        lines.append("")
        lines.append("## Workflow Steps")
        for (idx, step) in skill.instructions.enumerated() {
            lines.append("\(idx + 1). \(step)")
        }
        lines.append("")

        return lines.joined(separator: "\n")
    }

    public static func generateMcpToolSchema(skill: CustomAgentSkill) -> String {
        let toolsList = skill.toolsRequired.map { "\"\($0)\"" }.joined(separator: ", ")
        let lines: [String] = [
            "{",
            "  \"name\": \"\(skill.name)\",",
            "  \"description\": \"\(skill.skillDescription)\",",
            "  \"inputSchema\": {",
            "    \"type\": \"object\",",
            "    \"properties\": {",
            "      \"targetPath\": {",
            "        \"type\": \"string\",",
            "        \"description\": \"Absolute or relative path to file or directory to process.\"",
            "      },",
            "      \"options\": {",
            "        \"type\": \"object\",",
            "        \"description\": \"Optional execution parameters for \(skill.name).\"",
            "      }",
            "    },",
            "    \"required\": [\"targetPath\"]",
            "  },",
            "  \"requiredTools\": [\(toolsList)]",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(skill: CustomAgentSkill) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY CUSTOM SKILL DIRECTIVE: \(skill.name.uppercased())]",
            "When executing tasks matching: \(skill.triggerPhrases.joined(separator: ", "))",
            "Follow these mandatory steps:",
            ""
        ]

        for (idx, inst) in skill.instructions.enumerated() {
            lines.append("\(idx + 1). \(inst)")
        }

        lines.append("")
        lines.append("Adhere strictly to tools: \(skill.toolsRequired.joined(separator: ", ")).")
        return lines.joined(separator: "\n")
    }
}
