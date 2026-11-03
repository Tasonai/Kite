import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct SkillsCatalogView: View {
    @Environment(AppModel.self) private var model

    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "Все"
    @State private var selectedSkill: AntigravitySkillInfo? = SkillsRepository.curated.first
    @State private var copiedCommand: String?

    private let categories = ["Все", "Design", "Architecture", "Engineering", "Quality"]

    private var filteredSkills: [AntigravitySkillInfo] {
        SkillsRepository.curated.filter { s in
            let matchesCat = selectedCategory == "Все" || s.category == selectedCategory
            if !matchesCat { return false }
            if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty { return true }
            let q = searchQuery.lowercased()
            return s.name.lowercased().contains(q) ||
                   s.command.lowercased().contains(q) ||
                   s.description.lowercased().contains(q) ||
                   s.triggers.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        HSplitView {
            // Left List
            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat)
                                    .font(.caption.weight(selectedCategory == cat ? .semibold : .regular))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedCategory == cat ? Color.accentColor : Color.secondary.opacity(0.12))
                                    .foregroundStyle(selectedCategory == cat ? Color.white : Color.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                Divider()

                List(filteredSkills, selection: $selectedSkill) { skill in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(skill.command)
                                .font(.system(.subheadline, design: .monospaced).bold())
                                .foregroundStyle(Color.accentColor)

                            if skill.isCore {
                                Text("CORE")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Text(skill.category)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }

                        Text(skill.name)
                            .font(.caption)
                            .fontWeight(.medium)

                        Text(skill.summary)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .tag(skill)
                }
            }
            .frame(minWidth: 300, idealWidth: 360)
            .searchable(text: $searchQuery, prompt: "Поиск скиллов (@design-md)...")

            // Right Detail
            if let skill = selectedSkill {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title Bar
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(skill.name)
                                    .font(.title2.bold())
                                HStack(spacing: 8) {
                                    Text(skill.command)
                                        .font(.system(.body, design: .monospaced).bold())
                                        .foregroundStyle(Color.accentColor)
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    Text(skill.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()

                            Button {
                                copyCommand(skill.command)
                            } label: {
                                Label(copiedCommand == skill.command ? "Скопировано!" : "Копировать", systemImage: copiedCommand == skill.command ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }

                        Divider()

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Назначение и возможности")
                                .font(.headline)
                            Text(skill.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        // Triggers
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Триггеры активации")
                                .font(.headline)
                            HStack(spacing: 8) {
                                ForEach(skill.triggers, id: \.self) { t in
                                    Text(t)
                                        .font(.system(size: 10, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        // Principles
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ключевые принципы крафта")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(skill.principles, id: \.self) { p in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.green)
                                            .font(.caption)
                                        Text(p)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }

                        Divider()

                        // Action
                        Button {
                            model.sidebar = .translator
                        } label: {
                            Label("Использовать в Промпт-переводчике 🪄", systemImage: "wand.and.stars")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(24)
                }
            } else {
                ContentUnavailableView("Выберите скилл", systemImage: "cpu", description: Text("Выберите скилл в списке слева для просмотра деталей."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func copyCommand(_ cmd: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
        copiedCommand = cmd
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedCommand == cmd {
                copiedCommand = nil
            }
        }
    }
}
