import SwiftUI
import KiteKit

struct StateFlowSheet: View {
    let onDismiss: () -> Void

    @State private var flow: StateFlowDefinition = StateFlowSimulator.defaultFlow
    @State private var activeStateId: String = "idle"
    @State private var codeTab: CodeTarget = .swiftUI
    @State private var isCopied: Bool = false

    enum CodeTarget: String, CaseIterable, Identifiable {
        case swiftUI = "SwiftUI State Store"
        case xstate = "TypeScript (XState)"

        var id: String { rawValue }
    }

    private var currentStateNode: StateNode? {
        flow.states.first(where: { $0.id == activeStateId })
    }

    private var generatedCode: String {
        switch codeTab {
        case .swiftUI:
            return StateFlowSimulator.generateSwiftUIStateMachine(flow: flow)
        case .xstate:
            return StateFlowSimulator.generateTypeScriptXState(flow: flow)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Симулятор стейт-машины (State Flow)")
                        .font(.headline)
                    Text("Моделирование состояний интерфейса и исключение невозможных состояний")
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

            // Main Content
            HSplitView {
                // Left Column: Interactive Simulation
                VStack(alignment: .leading, spacing: 16) {
                    Text("Интерактивный симулятор состояний:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    // Current Active State Card
                    if let current = currentStateNode {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(stateColor(current.id))
                                    .frame(width: 8, height: 8)
                                Text(current.name)
                                    .font(.title3.bold())
                                Spacer()
                                Text("ID: \(current.id)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            Text(current.uiDescription)
                                .font(.body)
                                .foregroundStyle(.secondary)

                            Divider()

                            Text("Доступные переходы (События):")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            if current.allowedTransitions.isEmpty {
                                Text("Терминальное состояние: нет исходящих переходов")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                HStack(spacing: 8) {
                                    ForEach(current.allowedTransitions) { t in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                activeStateId = t.targetStateId
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.right.circle.fill")
                                                Text(t.event)
                                            }
                                            .font(.caption.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(stateColor(t.targetStateId))
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // All States Map
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Карта всех состояний:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        VStack(spacing: 8) {
                            ForEach(flow.states) { node in
                                Button {
                                    activeStateId = node.id
                                } label: {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(stateColor(node.id))
                                            .frame(width: 8, height: 8)
                                        Text(node.name)
                                            .font(.caption.weight(node.id == activeStateId ? .bold : .regular))
                                        Spacer()
                                        Text("\(node.allowedTransitions.count) переходов")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(8)
                                    .background(node.id == activeStateId ? Color.accentColor.opacity(0.12) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(16)
                .frame(minWidth: 380, idealWidth: 420)

                // Right Column: Generated Code
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("", selection: $codeTab) {
                            ForEach(CodeTarget.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 320)

                        Spacer()

                        Button {
                            copyCode()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано" : "Копировать код")
                            }
                            .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                    }

                    ScrollView {
                        Text(generatedCode)
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
                Button("Сбросить в начальное состояние") {
                    activeStateId = flow.initialStateId
                }
                .font(.caption)
                .buttonStyle(.plain)
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

    private func stateColor(_ stateId: String) -> Color {
        switch stateId {
        case "idle": return .blue
        case "loading": return .orange
        case "success": return .green
        case "empty": return .purple
        case "error": return .red
        default: return .secondary
        }
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedCode, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
