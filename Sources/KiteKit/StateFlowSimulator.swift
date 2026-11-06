import Foundation

public struct StateNode: Identifiable, Sendable, Codable, Equatable {
    public var id: String
    public var name: String
    public var uiDescription: String
    public var allowedTransitions: [StateTransition]

    public init(id: String, name: String, uiDescription: String, allowedTransitions: [StateTransition] = []) {
        self.id = id
        self.name = name
        self.uiDescription = uiDescription
        self.allowedTransitions = allowedTransitions
    }
}

public struct StateTransition: Identifiable, Sendable, Codable, Equatable {
    public var id: UUID
    public var event: String
    public var targetStateId: String

    public init(id: UUID = UUID(), event: String, targetStateId: String) {
        self.id = id
        self.event = event
        self.targetStateId = targetStateId
    }
}

public struct StateFlowDefinition: Sendable, Codable, Equatable {
    public var name: String
    public var initialStateId: String
    public var states: [StateNode]

    public init(name: String, initialStateId: String, states: [StateNode]) {
        self.name = name
        self.initialStateId = initialStateId
        self.states = states
    }
}

public enum StateFlowSimulator {
    public static var defaultFlow: StateFlowDefinition {
        StateFlowDefinition(
            name: "DataFetchFlow",
            initialStateId: "idle",
            states: [
                StateNode(
                    id: "idle",
                    name: "Ожидание (Idle)",
                    uiDescription: "Форма ввода готова, кнопка активна, списки пусты",
                    allowedTransitions: [
                        StateTransition(event: "SUBMIT", targetStateId: "loading")
                    ]
                ),
                StateNode(
                    id: "loading",
                    name: "Загрузка (Loading)",
                    uiDescription: "Скелетон-лоадер, кнопка заблокирована со спиннером",
                    allowedTransitions: [
                        StateTransition(event: "RESOLVE_SUCCESS", targetStateId: "success"),
                        StateTransition(event: "RESOLVE_EMPTY", targetStateId: "empty"),
                        StateTransition(event: "REJECT_ERROR", targetStateId: "error")
                    ]
                ),
                StateNode(
                    id: "success",
                    name: "Успех (Success)",
                    uiDescription: "Список данных, баннер успешного сохранения, фильтры",
                    allowedTransitions: [
                        StateTransition(event: "REFRESH", targetStateId: "loading"),
                        StateTransition(event: "RESET", targetStateId: "idle")
                    ]
                ),
                StateNode(
                    id: "empty",
                    name: "Пустой результат (Empty)",
                    uiDescription: "Тактильный Empty State с иллюстрацией и кнопкой 'Создать первый'",
                    allowedTransitions: [
                        StateTransition(event: "CREATE_FIRST", targetStateId: "idle")
                    ]
                ),
                StateNode(
                    id: "error",
                    name: "Ошибка (Error)",
                    uiDescription: "Баннер с описанием ошибки и тактильной кнопкой 'Повторить'",
                    allowedTransitions: [
                        StateTransition(event: "RETRY", targetStateId: "loading"),
                        StateTransition(event: "DISMISS", targetStateId: "idle")
                    ]
                )
            ]
        )
    }

    public static func generateSwiftUIStateMachine(flow: StateFlowDefinition) -> String {
        var lines: [String] = [
            "import SwiftUI",
            "",
            "// Auto-generated State Machine from Kite for \(flow.name)",
            "@Observable",
            "final class \(flow.name)Store {",
            "    enum AppState: String, CaseIterable {",
        ]

        for s in flow.states {
            lines.append("        case \(s.id) // \(s.name)")
        }

        lines.append("    }\n")
        lines.append("    var currentState: AppState = .\(flow.initialStateId)\n")
        lines.append("    func send(event: String) {")
        lines.append("        switch (currentState, event) {")

        for s in flow.states {
            for t in s.allowedTransitions {
                lines.append("        case (.\(s.id), \"\(t.event)\"): currentState = .\(t.targetStateId)")
            }
        }

        lines.append("        default:")
        lines.append("            break // Ignore illegal transition")
        lines.append("        }")
        lines.append("    }")
        lines.append("}")

        return lines.joined(separator: "\n")
    }

    public static func generateTypeScriptXState(flow: StateFlowDefinition) -> String {
        var lines: [String] = [
            "// Auto-generated State Machine from Kite for \(flow.name)",
            "export const \(flow.name)Config = {",
            "  id: '\(flow.name.lowercased())',",
            "  initial: '\(flow.initialStateId)',",
            "  states: {"
        ]

        for (idx, s) in flow.states.enumerated() {
            let isLast = idx == flow.states.count - 1
            lines.append("    \(s.id): {")
            lines.append("      meta: { uiDescription: \"\(s.uiDescription)\" },")
            if !s.allowedTransitions.isEmpty {
                lines.append("      on: {")
                for t in s.allowedTransitions {
                    lines.append("        \(t.event): '\(t.targetStateId)',")
                }
                lines.append("      }")
            }
            lines.append("    }\(isLast ? "" : ",")")
        }

        lines.append("  }")
        lines.append("};")
        return lines.joined(separator: "\n")
    }
}
