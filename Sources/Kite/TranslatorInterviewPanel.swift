import SwiftUI
import KiteKit

struct TranslatorInterviewPanel: View {
    let questions: [AIPrompts.InterviewQuestion]
    @Binding var answers: [UUID: String]
    let onSubmit: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Уточните, чтобы план вышел точным")
                .font(.headline)

            ForEach(questions) { question in
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.text)
                        .font(.subheadline.weight(.semibold))

                    HStack(spacing: 8) {
                        ForEach(question.options, id: \.self) { option in
                            let chosen = answers[question.id] == option
                            Button {
                                answers[question.id] = chosen ? "" : option
                            } label: {
                                Text(option)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(chosen ? Color.accentColor : Color.secondary.opacity(0.12))
                                    .foregroundStyle(chosen ? Color.white : Color.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextField("Свой ответ", text: Binding(
                        get: { answers[question.id] ?? "" },
                        set: { answers[question.id] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                }
            }

            HStack(spacing: 12) {
                Button("Сгенерировать с ответами") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)

                Button("Пропустить") {
                    onSkip()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
