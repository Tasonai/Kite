import SwiftUI
import KiteKit

struct TranslatorOutputView: View {
    @Binding var generatedBlueprint: String
    let selectedMode: String
    let qualityScore: Int
    let isCopied: Bool
    let onCopy: () -> Void

    private var qualityColor: Color {
        if qualityScore >= 80 { return .green }
        if qualityScore >= 50 { return .orange }
        return .red
    }

    private var qualityDescription: String {
        if qualityScore >= 80 { return "Высокая точность: стек, дизайн-система и скиллы сбалансированы." }
        if qualityScore >= 50 { return "Базовая спецификация: рекомендуется уточнить детали идеи." }
        return "Минимальный ввод: добавьте описание ключевого сценария."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quality Gauge Banner
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(qualityColor)
                            .frame(width: 8, height: 8)
                        Text(selectedMode == "stitch" ? "Google Stitch Спецификация" : selectedMode == "edit" ? "Таргетированный эдит" : "Индекс плотности плана:")
                            .font(.caption.bold())
                        Text("\(qualityScore)%")
                            .font(.caption.monospaced().bold())
                            .foregroundStyle(qualityColor)
                    }
                    Text(selectedMode == "stitch" ? "Спецификация по стандарту enhance-prompt + design-md." : (selectedMode == "edit" ? "Хирургическое изменение конкретного узла без регрессий." : qualityDescription))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if !generatedBlueprint.isEmpty {
                    Button {
                        onCopy()
                    } label: {
                        Label(isCopied ? "Скопировано" : (selectedMode == "stitch" ? "Копировать для Stitch" : "Скопировать план"), systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Output Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Инженерный план Antigravity")
                    .font(.headline)

                if generatedBlueprint.isEmpty {
                    ContentUnavailableView(
                        "Готовый план появится здесь",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Введите идею слева и нажмите «Скомпилировать /plan».")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    TextEditor(text: $generatedBlueprint)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
            }
        }
        .padding(20)
        .frame(minWidth: 360, idealWidth: 440)
    }
}
