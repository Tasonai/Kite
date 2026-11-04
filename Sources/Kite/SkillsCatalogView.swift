import AppKit
import SwiftData
import SwiftUI
import KiteKit

enum CatalogTab: String, CaseIterable, Sendable {
    case skills = "Навыки"
    case plugins = "Плагины"
}

struct SkillsCatalogView: View {
    @Environment(AppModel.self) private var model

    @State private var selectedTab: CatalogTab = .skills
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "Все"
    @State private var selectedSkill: AntigravitySkillInfo? = SkillsRepository.curated.first
    @State private var selectedPlugin: AntigravityPluginInfo? = PluginsRepository.installed.first
    @State private var copiedCommand: String?

    private var skillCategories: [String] {
        var set = Set<String>()
        for s in SkillsRepository.curated {
            set.insert(s.category)
        }
        return ["Все"] + set.sorted()
    }

    private var pluginCategories: [String] {
        var set = Set<String>()
        for p in PluginsRepository.installed {
            set.insert(p.category)
        }
        return ["Все"] + set.sorted()
    }

    private var currentCategories: [String] {
        selectedTab == .skills ? skillCategories : pluginCategories
    }

    private var filteredSkills: [AntigravitySkillInfo] {
        SkillsRepository.curated.filter { s in
            let matchesCat = selectedCategory == "Все" || s.category == selectedCategory
            if !matchesCat { return false }
            if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty { return true }
            let q = searchQuery.lowercased()
            return s.name.lowercased().contains(q) ||
                   s.command.lowercased().contains(q) ||
                   s.summary.lowercased().contains(q) ||
                   s.description.lowercased().contains(q) ||
                   (s.pluginId?.lowercased().contains(q) ?? false) ||
                   s.triggers.contains { $0.lowercased().contains(q) }
        }
    }

    private var filteredPlugins: [AntigravityPluginInfo] {
        PluginsRepository.installed.filter { p in
            let matchesCat = selectedCategory == "Все" || p.category == selectedCategory
            if !matchesCat { return false }
            if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty { return true }
            let q = searchQuery.lowercased()
            return p.name.lowercased().contains(q) ||
                   p.id.lowercased().contains(q) ||
                   p.summary.lowercased().contains(q) ||
                   p.author.lowercased().contains(q) ||
                   (p.mcpServer?.lowercased().contains(q) ?? false) ||
                   (p.cliCommand?.lowercased().contains(q) ?? false) ||
                   p.skills.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        HSplitView {
            // Left List
            VStack(spacing: 0) {
                // Top Segmented Picker: Skills vs Plugins
                HStack(spacing: 8) {
                    Picker("Режим каталога", selection: $selectedTab) {
                        Text("Скиллы (\(SkillsRepository.curated.count))").tag(CatalogTab.skills)
                        Text("Плагины (\(PluginsRepository.installed.count))").tag(CatalogTab.plugins)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTab) { _, _ in
                        selectedCategory = "Все"
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider()

                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(currentCategories, id: \.self) { cat in
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

                if selectedTab == .skills {
                    List(filteredSkills, selection: $selectedSkill) { skill in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(skill.command)
                                    .font(.system(.subheadline, design: .monospaced).bold())
                                    .foregroundStyle(Color.accentColor)

                                if let pluginId = skill.pluginId {
                                    Text(pluginId)
                                        .font(.system(size: 8, weight: .semibold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(Color.blue)
                                        .clipShape(Capsule())
                                }

                                if skill.isCore {
                                    Text("CORE")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                }

                                Spacer()

                                Text(skill.category)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }

                            Text(skill.summary)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                        .tag(skill)
                    }
                } else {
                    List(filteredPlugins, selection: $selectedPlugin) { plugin in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: plugin.icon)
                                    .font(.title3)
                                    .foregroundStyle(Palette.accentText)
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plugin.name)
                                        .font(.subheadline.bold())

                                    HStack(spacing: 8) {
                                        Text("v\(plugin.version)")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundStyle(.secondary)

                                        Text("•")
                                            .foregroundStyle(.secondary)

                                        Text(plugin.category)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Text("\(plugin.skillsCount) скиллов")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Text(plugin.summary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                        .tag(plugin)
                    }
                }
            }
            .frame(minWidth: 320, idealWidth: 380)
            .searchable(text: $searchQuery, prompt: selectedTab == .skills ? "Поиск скиллов (@design-md)..." : "Поиск плагинов (Figma, Vercel)...")

            // Right Detail
            if selectedTab == .skills {
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

                                        if let pId = skill.pluginId {
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            Text("Плагин: \(pId)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                Spacer()

                                Button {
                                    copyText(skill.command)
                                } label: {
                                    Label(copiedCommand == skill.command ? "Скопировано!" : "Копировать", systemImage: copiedCommand == skill.command ? "checkmark" : "doc.on.doc")
                                }
                                .buttonStyle(.bordered)
                            }

                            Divider()

                            // Summary & Details
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Назначение и возможности")
                                    .font(.headline)
                                Text(skill.summary)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                if !skill.description.isEmpty && skill.description != skill.summary {
                                    Text(skill.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.secondary.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }

                            // Triggers
                            if !skill.triggers.isEmpty {
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
                            }

                            // Principles
                            if !skill.principles.isEmpty {
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
                            }

                            Divider()

                            // Action
                            Button {
                                model.sidebar = .translator
                            } label: {
                                Label("Использовать в Промпт-переводчике", systemImage: "wand.and.stars")
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
            } else {
                // PLUGIN DETAIL VIEW
                if let plugin = selectedPlugin {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Title Bar
                            HStack(alignment: .top) {
                                HStack(spacing: 12) {
                                    Image(systemName: plugin.icon)
                                        .font(.system(size: 28))
                                        .foregroundStyle(Palette.accentText)
                                        .frame(width: 48, height: 48)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plugin.name)
                                            .font(.title2.bold())
                                        HStack(spacing: 8) {
                                            Text("v\(plugin.version)")
                                                .font(.system(.body, design: .monospaced))
                                                .foregroundStyle(.secondary)
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            Text(plugin.author)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            Text(plugin.category)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                Spacer()

                                if let cli = plugin.cliCommand {
                                    Button {
                                        copyText(cli)
                                    } label: {
                                        Label(copiedCommand == cli ? "Скопировано!" : "CLI: \(cli.split(separator: " ").first.map(String.init) ?? cli)", systemImage: copiedCommand == cli ? "checkmark" : "terminal")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }

                            Divider()

                            // Plugin Summary
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Описание плагина")
                                    .font(.headline)
                                Text(plugin.summary)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }

                            // Capabilities
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Возможности интеграции")
                                    .font(.headline)

                                HStack(spacing: 8) {
                                    if let mcp = plugin.mcpServer {
                                        HStack(spacing: 4) {
                                            Image(systemName: "server.rack")
                                                .font(.caption)
                                            Text("MCP: \(mcp)")
                                                .font(.caption.bold())
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundStyle(Color.orange)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    if let cli = plugin.cliCommand {
                                        HStack(spacing: 4) {
                                            Image(systemName: "terminal")
                                                .font(.caption)
                                            Text("CLI: \(cli)")
                                                .font(.caption.bold())
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.indigo.opacity(0.15))
                                        .foregroundStyle(Color.indigo)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    HStack(spacing: 4) {
                                        Image(systemName: "cpu")
                                            .font(.caption)
                                        Text("\(plugin.skillsCount) навыков")
                                            .font(.caption.bold())
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }

                            // Included Skills
                            if !plugin.skills.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Входящие скиллы (\(plugin.skills.count))")
                                            .font(.headline)
                                        Spacer()
                                        Text("кликните для перехода")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                                        ForEach(plugin.skills, id: \.self) { skillName in
                                            Button {
                                                selectedTab = .skills
                                                selectedCategory = "Все"
                                                searchQuery = skillName
                                                if let found = SkillsRepository.curated.first(where: { $0.id == skillName }) {
                                                    selectedSkill = found
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text("@\(skillName)")
                                                        .font(.system(size: 11, design: .monospaced))
                                                        .lineLimit(1)
                                                    Spacer()
                                                    Image(systemName: "arrow.right")
                                                        .font(.system(size: 8))
                                                        .foregroundStyle(.secondary)
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.secondary.opacity(0.08))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
                    }
                } else {
                    ContentUnavailableView("Выберите плагин", systemImage: "shippingbox", description: Text("Выберите плагин в списке слева для просмотра деталей."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private func copyText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copiedCommand = text
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedCommand == text {
                copiedCommand = nil
            }
        }
    }
}
