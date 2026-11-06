import SwiftUI
import KiteKit

struct ContextOptimizerSheet: View {
    var title: String = "Kite App"
    var concept: String = "Архитектурная концепция"
    var platform: String = "Web"
    var style: String = "Apple HIG & Modern Minimal"
    let onDismiss: () -> Void

    @State private var isCopied: Bool = false

    private var entities: [SchemaEntity] {
        DataSchemaDesigner.starterPack
    }

    private var routes: [APIRoute] {
        APIContractBuilder.starterPack
    }

    private var metrics: ContextOptimizerMetrics {
        ContextOptimizer.estimateMetrics(
            title: title,
            concept: concept,
            entities: entities,
            routes: routes
        )
    }

    private var compiledDigest: String {
        ContextOptimizer.compileDigest(
            title: title,
            concept: concept,
            platform: platform,
            style: style,
            entities: entities,
            routes: routes
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "gauge.with.needle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Оптимизатор контекста (Context Optimizer)")
                        .font(.headline)
                    Text("Сверхплотный дайджест архитектуры: экономия до 95% токенов за запрос к ИИ")
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

            // Metrics Banner
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Исходный размер контекста:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("~\(metrics.rawTokensEstimated) токенов")
                        .font(.title3.monospaced().bold())
                        .foregroundStyle(Color.red)
                }

                Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Сжатый дайджест Kite:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("~\(metrics.compressedTokensEstimated) токенов")
                        .font(.title3.monospaced().bold())
                        .foregroundStyle(Color.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Экономия бюджета:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("-\(metrics.savedPercentage)% токенов")
                        .font(.headline.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.16))
                        .foregroundStyle(Color.green)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06))

            Divider()

            // Main Editor / Preview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Скомпилированный CONTEXT.md для Antigravity:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(compiledDigest, forType: .string)
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isCopied = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Скопировано!" : "Копировать для Antigravity")
                        }
                        .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isCopied ? .green : .accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    Text(compiledDigest)
                        .font(.system(size: 11, design: .monospaced)) // grid: ok
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(minWidth: 700, idealWidth: 760, minHeight: 520, idealHeight: 560)
    }
}
