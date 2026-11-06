import SwiftUI
import KiteKit

struct SkillSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .skillMd
    @State private var selectedSkillIndex: Int = 0
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case skillMd = "Навык (SKILL.md)"
        case mcpSchema = "MCP Схема (schema.json)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var skills: [CustomAgentSkill] {
        SkillSynthesizer.starterSkills
    }

    private var currentSkill: CustomAgentSkill {
        skills[min(selectedSkillIndex, skills.count - 1)]
    }

    private var currentText: String {
        switch activeTab {
        case .skillMd:
            return SkillSynthesizer.generateSkillMarkdown(skill: currentSkill)
        case .mcpSchema:
            return SkillSynthesizer.generateMcpToolSchema(skill: currentSkill)
        case .prompt:
            return SkillSynthesizer.generatePromptDirective(skill: currentSkill)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Синтезатор навыков ИИ и MCP инструментов (Skill Synthesizer)")
                        .font(.headline)
                    Text("Генерация валидных файлов SKILL.md с YAML frontmatter и JSON-схем инструментов MCP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Закрыть", action: onDismiss)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            HSplitView {
                // Left: Skills List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Шаблоны навыков (\(skills.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(skills.indices, id: \.self) { idx in
                                let s = skills[idx]
                                Button {
                                    selectedSkillIndex = idx
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(s.name)
                                                .font(.caption.bold().monospaced())
                                            Spacer()
                                            if selectedSkillIndex == idx {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(Color.accentColor)
                                            }
                                        }

                                        Text(s.skillDescription)
                                            .font(.caption2)
                                            .lineLimit(2)
                                            .foregroundStyle(.primary)

                                        HStack(spacing: 4) {
                                            Text("Инструменты: \(s.toolsRequired.count)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text("Триггеры: \(s.triggerPhrases.count)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(selectedSkillIndex == idx ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 280, idealWidth: 300)

                // Right: Generated Spec
                VStack(spacing: 12) {
                    HStack {
                        Picker("", selection: $activeTab) {
                            ForEach(OutputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(currentText, forType: .string)
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                isCopied = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано!" : "Копировать")
                            }
                            .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isCopied ? .green : .accentColor)
                    }

                    ScrollView {
                        Text(currentText)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 740, idealWidth: 800, minHeight: 520, idealHeight: 560)
    }
}
