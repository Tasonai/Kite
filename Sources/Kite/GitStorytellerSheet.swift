import SwiftUI
import KiteKit

struct GitStorytellerSheet: View {
    let title: String
    let concept: String
    let platform: String
    let style: String
    let onDismiss: () -> Void

    @State private var storyReport: GitStoryReport
    @State private var isCopiedPR: Bool = false
    @State private var isCopiedCommits: Bool = false

    init(title: String, concept: String, platform: String, style: String, onDismiss: @escaping () -> Void) {
        self.title = title
        self.concept = concept
        self.platform = platform
        self.style = style
        self.onDismiss = onDismiss
        self._storyReport = State(initialValue: GitStoryteller.craftStory(
            title: title,
            concept: concept,
            platform: platform,
            style: style
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Генератор коммитов и Pull Request (Git Storyteller)")
                        .font(.headline)
                    Text("Формирование истории версий по стандарту Conventional Commits и готового PR для GitHub")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Main Layout
            HSplitView {
                // Left Column: Conventional Commits Sequence
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Рекомендуемая цепочка коммитов:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            copyCommits()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isCopiedCommits ? "checkmark" : "doc.on.doc")
                                Text(isCopiedCommits ? "Скопировано" : "Скопировать")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(storyReport.suggestedCommits.enumerated()), id: \.offset) { idx, commit in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(idx + 1)")
                                        .font(.caption2.monospaced().bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.16))
                                        .clipShape(Capsule())

                                    Text(commit)
                                        .font(.system(.caption, design: .monospaced)) // grid: ok font
                                        .textSelection(.enabled)

                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 380, idealWidth: 420)

                // Right Column: PR Markdown Description
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pull Request для GitHub:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(storyReport.prTitle)
                                .font(.caption.monospaced().bold())
                        }

                        Spacer()

                        Button {
                            copyPR()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCopiedPR ? "checkmark" : "doc.on.doc")
                                Text(isCopiedPR ? "Скопировано" : "Скопировать PR")
                            }
                            .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                    }

                    ScrollView {
                        Text(storyReport.prBodyMarkdown)
                            .font(.system(.body, design: .monospaced)) // grid: ok font
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(16)
                .frame(minWidth: 400, idealWidth: 480)
            }

            Divider()

            // Footer
            HStack {
                Text("Совет: вставляйте это описание в GitHub Pull Request для наглядного отчета.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 840, idealWidth: 940, minHeight: 520, idealHeight: 640)
    }

    private func copyCommits() {
        let text = storyReport.suggestedCommits.map { "git commit -m \"\($0)\"" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        isCopiedCommits = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopiedCommits = false
        }
    }

    private func copyPR() {
        let full = "# \(storyReport.prTitle)\n\n\(storyReport.prBodyMarkdown)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(full, forType: .string)
        isCopiedPR = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopiedPR = false
        }
    }
}
