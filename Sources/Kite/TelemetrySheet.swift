import SwiftUI
import KiteKit

struct TelemetrySheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (EVENTS.md)"
        case client = "Клиент аналитики (telemetry.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var events: [TelemetryEvent] {
        TelemetrySpecifier.starterEvents
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return TelemetrySpecifier.generateTelemetryMarkdown(title: title, events: events)
        case .client:
            return TelemetrySpecifier.generateTypeScriptClient(events: events)
        case .prompt:
            return TelemetrySpecifier.generatePromptDirective(events: events)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Спецификатор телеметрии и аналитики (Telemetry & Events)")
                        .font(.headline)
                    Text("Реестр продуктовых событий, строгие типы payload, защита от утечек PII и type-safe клиент")
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
                    Text("События продукта (\(events.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(events) { event in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(event.name)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text(event.category)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text(event.description)
                                        .font(.caption2)
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.shield")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                        Text("Без PII")
                                            .font(.caption2)
                                            .foregroundStyle(.green)

                                        Spacer()

                                        Text("\(event.properties.count) свойств")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
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
