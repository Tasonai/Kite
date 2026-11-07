import SwiftUI
import KiteKit

struct ModelRouterSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (MODEL_ROUTING.md)"
        case client = "Клиент (lib/modelRouter.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var routes: [ModelRouteRule] {
        ModelRouter.starterRoutes
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return ModelRouter.generateRoutingMarkdown(title: title, routes: routes)
        case .client:
            return ModelRouter.generateTypeScriptRouter(routes: routes)
        case .prompt:
            return ModelRouter.generatePromptDirective(routes: routes)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "cpu.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Мульти-модельный оркестратор Gemini 3.8 (Model Router)")
                        .font(.headline)
                    Text("Динамический роутинг задач (Flash 3.8, Pro 3.8, Ultra 3.8), цепочки фолбэков и контроль задержек")
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
                // Left: Routes List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Маршруты моделей (\(routes.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(routes) { r in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(r.taskType)
                                            .font(.caption.bold())
                                        Spacer()
                                        Text(r.primaryModel)
                                            .font(.caption2.bold().monospaced())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Фолбэк: \(r.fallbackModel)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)

                                    HStack {
                                        Text("SLA: <\(r.targetLatencyMs)ms")
                                            .font(.caption2)
                                        Spacer()
                                        Text("\(r.maxTokens) tok")
                                            .font(.caption2.monospaced())
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
