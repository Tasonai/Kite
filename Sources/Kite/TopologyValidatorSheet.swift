import SwiftUI
import KiteKit

struct TopologyValidatorSheet: View {
    let title: String
    let report: TopologyReport
    let onDismiss: () -> Void

    @State private var isCopied: Bool = false
    @State private var copiedNotice: String? = nil

    private var markdownContent: String {
        CanvasTopologyValidator.generateTopologyMarkdown(title: title, report: report)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 12) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Валидатор топологии архитектуры")
                            .font(.headline)

                        Text("\(report.healthScore)/100")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(report.isSecure ? Color.green.opacity(0.16) : Color.red.opacity(0.16))
                            .foregroundStyle(report.isSecure ? Color.green : Color.red)
                            .clipShape(Capsule())
                    }

                    Text("Анализ связей: циклические зависимости, утечки БД и шлюзы")
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

            // Metrics summary strip
            HStack(spacing: 12) {
                metricCard(title: "Компоненты", value: "\(report.totalNodes)", icon: "square.grid.2x2")
                metricCard(title: "Связи", value: "\(report.totalConnections)", icon: "arrow.triangle.swap")
                metricCard(
                    title: "Уязвимости",
                    value: "\(report.issues.count)",
                    icon: "exclamationmark.shield",
                    isWarning: !report.issues.isEmpty
                )
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Issues and recommendations list
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if report.issues.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 40)) // grid: ok icon size
                                .foregroundStyle(Color.green)
                            Text("Топология безопасна")
                                .font(.headline)
                            Text("Прямой доступ к базам данных отсутствует, циклических синхронных блокировок не обнаружено.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        ForEach(report.issues) { issue in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    severityBadge(issue.severity)
                                    Text(issue.title)
                                        .font(.subheadline.bold())
                                    Spacer()
                                }

                                Text(issue.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .font(.caption2)
                                    Text(issue.recommendation)
                                        .font(.caption.bold())
                                        .foregroundStyle(.primary)
                                }
                                .padding(8)
                                .background(Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColor(for: issue.severity), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            // Bottom bar
            HStack(spacing: 12) {
                Button {
                    copyToClipboard(markdownContent)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Скопировано" : "Скопировать TOPOLOGY.md")
                    }
                    .font(.body.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)

                if let notice = copiedNotice {
                    Text(notice)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.green)
                }

                Spacer()

                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 680, idealWidth: 760, minHeight: 480, idealHeight: 560)
    }

    private func metricCard(title: String, value: String, icon: String, isWarning: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(isWarning ? Color.orange : Color.accentColor)
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body.bold())
                    .foregroundStyle(isWarning ? Color.orange : Color.primary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func severityBadge(_ severity: TopologySeverity) -> some View {
        let (bg, fg) = switch severity {
        case .critical: (Color.red.opacity(0.16), Color.red)
        case .warning: (Color.orange.opacity(0.16), Color.orange)
        case .info: (Color.blue.opacity(0.16), Color.blue)
        }

        return Text(severity.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold)) // grid: ok font
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(Capsule())
    }

    private func borderColor(for severity: TopologySeverity) -> Color {
        switch severity {
        case .critical: return Color.red.opacity(0.3)
        case .warning: return Color.orange.opacity(0.3)
        case .info: return Color.clear
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        isCopied = true
        copiedNotice = "Скопировано в буфер"
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
            copiedNotice = nil
        }
    }
}
