import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct InspirationGalleryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context

    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "Все"
    @State private var inspectingCard: InspirationCard?
    @State private var copiedId: String?
    @State private var createdId: String?

    private let categories = [
        "Все",
        "Editorial & Swiss Modern",
        "Linear & DevTool Cockpit",
        "Neo-Brutalism & Tactical",
        "Voxel & 3D Isometric",
        "Glassmorphism & Spatial"
    ]

    private var filteredCards: [InspirationCard] {
        InspirationRepository.curated.filter { card in
            let matchesCategory = selectedCategory == "Все" || card.category == selectedCategory
            if !matchesCategory { return false }
            if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty { return true }
            let q = searchQuery.lowercased()
            return card.title.lowercased().contains(q) ||
                   card.description.lowercased().contains(q) ||
                   card.keywords.contains { $0.lowercased().contains(q) } ||
                   card.displayFont.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header & Filter Bar
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Галерея дизайн-вдохновения 🎨")
                            .font(.title2.bold())
                        Text("Курированная коллекция визуальных систем, палитр и типографических сеток.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Category filter pills
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
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320, maximum: 440), spacing: 16)], spacing: 16) {
                    ForEach(filteredCards) { card in
                        InspirationCardView(
                            card: card,
                            onInspect: { inspectingCard = card },
                            onUseAsProject: { createProject(from: card) },
                            onCopyPrompt: { copyPrompt(for: card) },
                            isCopied: copiedId == card.id,
                            isCreated: createdId == card.id
                        )
                    }
                }
                .padding(20)
            }
        }
        .searchable(text: $searchQuery, prompt: "Поиск по стилям, шрифтам или тегам...")
        .sheet(item: $inspectingCard) { card in
            InspirationInspectorSheet(
                card: card,
                onUseAsProject: {
                    createProject(from: card)
                    inspectingCard = nil
                },
                onDismiss: { inspectingCard = nil }
            )
        }
    }

    private func createProject(from card: InspirationCard) {
        let item = Item(title: "Проект: \(card.title)")
        item.concept = card.description
        item.platform = "Web"
        item.style = card.category
        item.status = "backlog"
        item.tags = card.keywords.joined(separator: ", ")
        item.generatedPrompt = PromptCompiler.compileBlueprint(
            title: item.title,
            concept: item.concept,
            platform: item.platform,
            style: item.style
        )
        context.insert(item)
        try? context.save()
        model.selection = item.id
        createdId = card.id
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            createdId = nil
        }
    }

    private func copyPrompt(for card: InspirationCard) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(card.promptBlueprint, forType: .string)
        copiedId = card.id
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedId = nil
        }
    }
}

private struct InspirationCardView: View {
    let card: InspirationCard
    let onInspect: () -> Void
    let onUseAsProject: () -> Void
    let onCopyPrompt: () -> Void
    let isCopied: Bool
    let isCreated: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Preview
            AsyncImage(url: URL(string: card.thumbnail)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.16))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary))
                default:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.12))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(ProgressView().controlSize(.small))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.16), lineWidth: 1))

            // Meta
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(card.category)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    Text("by \(card.creator)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(card.title)
                    .font(.headline)

                Text(card.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Colors
            HStack(spacing: 8) {
                ForEach(card.colors) { c in
                    Circle()
                        .fill(Color(hex: c.hex))
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                        .help("\(c.name) (\(c.hex))")
                }
                Spacer()
                Text(card.displayFont)
                    .font(.system(size: 9, design: .serif))
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Actions
            HStack(spacing: 8) {
                Button {
                    onUseAsProject()
                } label: {
                    Label(isCreated ? "Создано!" : "В проект 💡", systemImage: isCreated ? "checkmark" : "plus.circle")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    onCopyPrompt()
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Скопировать блупринт стиля")

                Spacer()

                Button("Инспектор") {
                    onInspect()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.16), lineWidth: 1))
    }
}

private struct InspirationInspectorSheet: View {
    let card: InspirationCard
    let onUseAsProject: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack {
                Text(card.title)
                    .font(.headline)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Big Image
                    AsyncImage(url: URL(string: card.thumbnail)) { phase in
                        if let img = phase.image {
                            img.resizable().aspectRatio(contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Description
                    Text(card.description)
                        .font(.body)

                    // Palette Breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Семантическая палитра токенов")
                            .font(.subheadline.bold())

                        ForEach(card.colors) { c in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: c.hex))
                                    .frame(width: 24, height: 24)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.1), lineWidth: 1))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.name).font(.caption.bold())
                                    Text(c.role).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(c.hex).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Typography
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Типографика").font(.subheadline.bold())
                        Text("Акцидентный шрифт: \(card.displayFont)").font(.caption)
                        Text("Основной текст: \(card.bodyFont)").font(.caption)
                    }

                    // Prompt Blueprint
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Промпт-блупринт для Antigravity").font(.subheadline.bold())
                        Text(card.promptBlueprint)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Закрыть") { onDismiss() }
                    .buttonStyle(.bordered)
                Button("Создать проект на основе референса 💡") { onUseAsProject() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .frame(width: 600, height: 680)
    }
}

// Color Hex Helper
private extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (128, 128, 128, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
