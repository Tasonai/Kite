import SwiftUI
import KiteKit

struct EventBusSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (EVENT_BUS.md)"
        case busClient = "Шина событий (eventBus.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var events: [DomainEventConfig] {
        EventBusStudio.starterEvents
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return EventBusStudio.generateEventBusMarkdown(title: title, events: events)
        case .busClient:
            return EventBusStudio.generateEventBusClientSnippet(events: events)
        case .prompt:
            return EventBusStudio.generatePromptDirective(events: events)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Студия распределенной шины событий (Event Bus Studio)")
                        .font(.headline)
                    Text("Доменные события, Zod-типизация, асинхронный Pub/Sub и очереди ошибок DLQ")
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
                // Left: Events List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Доменные события (\(events.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(events) { e in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(e.eventName)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text(e.deliveryGuarantee)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Подписчики: \(e.subscribers.joined(separator: ", "))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)

                                    HStack {
                                        Text("DLQ: \(e.retryPolicy)")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
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
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 360)

                // Right: Generated Spec & Snippets
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("Режим просмотра", selection: $activeTab) {
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isCopied = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано" : "Копировать")
                            }
                        }
                    }

                    TextEditor(text: .constant(currentText))
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(16)
                .frame(minWidth: 460, idealWidth: 500)
            }
        }
        .frame(minWidth: 760, idealWidth: 800, minHeight: 520, idealHeight: 560)
    }
}
