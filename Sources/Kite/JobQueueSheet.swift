import SwiftUI
import KiteKit

struct JobQueueSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (JOBS.md)"
        case inngest = "Воркеры (functions.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var jobs: [BackgroundJob] {
        JobQueueStrategist.starterJobs
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return JobQueueStrategist.generateJobsMarkdown(title: title, jobs: jobs)
        case .inngest:
            return JobQueueStrategist.generateInngestWorkerSnippet(jobs: jobs)
        case .prompt:
            return JobQueueStrategist.generatePromptDirective(jobs: jobs)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Стратег фоновых задач и очередей (Job Queue Strategist)")
                        .font(.headline)
                    Text("Вынос тяжелых операций из HTTP-хендлеров: cron-расписания, очереди событий и DLQ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Закрыть", action: onDismiss)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            HSplitView {
                // Left: Jobs List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Фоновые воркеры (\(jobs.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(jobs) { j in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(j.jobName)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text(j.triggerType)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    HStack(spacing: 8) {
                                        Text("Повторов: \(j.retryLimit)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("Параллелизм: \(j.concurrencyLimit)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("Таймаут: \(j.executionTimeoutSec)с")
                                            .font(.caption2)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 280, idealWidth: 300)

                // Right: Generated Spec
                VStack(spacing: 12) {
                    HStack {
                        Picker("", selection: $activeTab) {
                            ForEach(OutputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(currentText, forType: .string)
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                isCopied = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано!" : "Копировать")
                            }
                            .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isCopied ? .green : .accentColor)
                    }

                    ScrollView {
                        Text(currentText)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 740, idealWidth: 800, minHeight: 520, idealHeight: 560)
    }
}
