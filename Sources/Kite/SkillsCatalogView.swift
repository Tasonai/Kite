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

    /// Tokenized once; searching 355 long descriptions on every keystroke would lag otherwise.
    private static let skillIndex: [String: ItemSearch.Document] = Dictionary(
        SkillsRepository.curated.map { skill in
            (skill.id, ItemSearch.Document(fields: [
                .init(skill.name, weight: 6),
                .init(skill.command, weight: 6),
                .init(skill.triggers.joined(separator: " "), weight: 4),
                .init(skill.pluginId ?? "", weight: 2),
                .init(skill.summary, weight: 2),
                .init(skill.description, weight: 1)
            ]))
        },
        uniquingKeysWith: { first, _ in first }
    )

    private var filteredSkills: [AntigravitySkillInfo] {
        let inCategory = SkillsRepository.curated.filter { selectedCategory == "Все" || $0.category == selectedCategory }
        let queryTokens = ItemSearch.tokens(searchQuery)
        if queryTokens.isEmpty { return inCategory }
        let ranked: [(skill: AntigravitySkillInfo, score: Int)] = inCategory.compactMap { skill in
            guard let score = Self.skillIndex[skill.id]?.score(queryTokens: queryTokens) else { return nil }
            return (skill, score)
        }
        return ranked.sorted { $0.score > $1.score }.map(\.skill)
    }

    private var filteredPlugins: [AntigravityPluginInfo] {
        let inCategory = PluginsRepository.installed.filter { selectedCategory == "Все" || $0.category == selectedCategory }
        let queryTokens = ItemSearch.tokens(searchQuery)
        if queryTokens.isEmpty { return inCategory }
        let ranked: [(plugin: AntigravityPluginInfo, score: Int)] = inCategory.compactMap { plugin in
            let document = ItemSearch.Document(fields: [
                .init(plugin.name, weight: 6),
                .init(plugin.id, weight: 5),
                .init(plugin.skills.joined(separator: " "), weight: 3),
                .init(plugin.cliCommand ?? "", weight: 2),
                .init(plugin.mcpServer ?? "", weight: 2),
                .init(plugin.author, weight: 2),
                .init(plugin.summary, weight: 2)
            ])
            guard let score = document.score(queryTokens: queryTokens) else { return nil }
            return (plugin, score)
        }
        return ranked.sorted { $0.score > $1.score }.map(\.plugin)
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
                                Text(searchHighlighted(skill.command, query: searchQuery))
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

                            Text(searchHighlighted(skill.summary, query: searchQuery))
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
                                    Text(searchHighlighted(plugin.name, query: searchQuery))
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

                            Text(searchHighlighted(plugin.summary, query: searchQuery))
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
            .searchable(text: $searchQuery, prompt: selectedTab == .skills ? "Поиск скиллов (/design-md)..." : "Поиск плагинов (Figma, Vercel)...")

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
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Обзор и назначение")
                                    .font(.headline)

                                Text(skill.summary)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                if !skill.description.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Архитектура и рабочий процесс")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)

                                        Text(skill.description)
                                            .font(.callout)
                                            .foregroundStyle(.primary)
                                            .lineSpacing(4)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.secondary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }

                            // When to use
                            if !skill.whenToUse.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                        Text("Когда применять")
                                            .font(.headline)
                                    }

                                    Text(skill.whenToUse)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.accentColor.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }

                            // Capabilities
                            if !skill.capabilities.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Ключевые возможности")
                                        .font(.headline)
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(skill.capabilities, id: \.self) { cap in
                                            HStack(alignment: .top, spacing: 8) {
                                                Image(systemName: "arrow.right.circle")
                                                    .foregroundStyle(Color.accentColor)
                                                    .font(.caption)
                                                    .padding(.top, 2)
                                                Text(cap)
                                                    .font(.subheadline)
                                            }
                                        }
                                    }
                                }
                            }

                            // Example Prompt
                            if !skill.examplePrompt.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Пример готового промпта")
                                            .font(.headline)
                                        Spacer()
                                        Button {
                                            copyText(skill.examplePrompt)
                                        } label: {
                                            Label("Копировать промпт", systemImage: "doc.on.doc")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.borderless)
                                    }

                                    Text(skill.examplePrompt)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.secondary.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .textSelection(.enabled)
                                }
                            }

                            // Triggers
                            if !skill.triggers.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Триггеры активации")
                                        .font(.headline)
                                    FlowLayout(spacing: 8) {
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
                                                    Text("/\(skillName)")
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
