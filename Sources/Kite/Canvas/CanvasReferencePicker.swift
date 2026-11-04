import SwiftUI

struct ReferenceOptionItem: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let source: String
    let url: String
    let colorHex: String
    let tags: [String]
    let desc: String
}

struct CanvasReferencePickerSheet: View {
    var onSelect: (CanvasReferenceCard) -> Void
    var onDismiss: () -> Void

    private let presetOptions: [ReferenceOptionItem] = [
        ReferenceOptionItem(
            title: "Linear: Navigation & Fast Command Palette",
            source: "Mobbin",
            url: "https://mobbin.com",
            colorHex: "#10B981",
            tags: ["Keyboard", "Speed", "Cockpit UX"],
            desc: "Компактная эргономика меню и мгновенный поиск через ⌘K."
        ),
        ReferenceOptionItem(
            title: "Apple HIG: iOS 18 Modular Grid & Haptics",
            source: "Mobbin",
            url: "https://mobbin.com",
            colorHex: "#3B82F6",
            tags: ["Apple HIG", "44px Targets", "Spring Motion"],
            desc: "Строгое следование 4pt модульной сетке и нативным анимациям."
        ),
        ReferenceOptionItem(
            title: "Figma Community: W3C Design Tokens System",
            source: "Figma",
            url: "https://figma.com",
            colorHex: "#8B5CF6",
            tags: ["Tokens Studio", "Variables", "Multi-Theme"],
            desc: "Архитектура дизайн-токенов с семантическими алиасами для dark/light."
        ),
        ReferenceOptionItem(
            title: "Recent Design: Swiss Modern Editorial Layout",
            source: "Recent Design",
            url: "https://recent.design",
            colorHex: "#D97757",
            tags: ["Anti-Slop", "Editorial", "Serif Typography"],
            desc: "Асимметричные журнальные сплиты и акцидентная типографика."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(Color.accentColor)
                    Text("Каталог референсов на холст")
                        .font(.headline)
                }

                Spacer()

                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }

            Text("Выберите готовый паттерн из Mobbin или Figma для добавления на холст:")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(presetOptions) { opt in
                        referenceOptionCard(opt)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(24)
        .frame(width: 540, height: 480)
    }

    private func referenceOptionCard(_ opt: ReferenceOptionItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(opt.source)
                        .font(.system(size: 9, weight: .bold, design: .monospaced)) // grid: ok font
                        .foregroundStyle(Color(hex: opt.colorHex))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: opt.colorHex).opacity(0.16))
                        .clipShape(Capsule())

                    Text(opt.title)
                        .font(.subheadline.bold())
                }

                Text(opt.desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button("+ На холст") {
                let card = CanvasReferenceCard(
                    title: opt.title,
                    source: opt.source,
                    url: opt.url,
                    colorHex: opt.colorHex,
                    position: CGPoint(x: 240, y: 220),
                    tags: opt.tags,
                    description: opt.desc
                )
                onSelect(card)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: opt.colorHex))
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
    }
}
