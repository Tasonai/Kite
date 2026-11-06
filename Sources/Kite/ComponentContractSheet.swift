import SwiftUI
import KiteKit

struct ComponentContractSheet: View {
    let onDismiss: () -> Void

    @State private var selectedComponentId: String = ComponentContractMatrix.starterPack.first?.id ?? ""
    @State private var activeTab: OutputMode = .typescript
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case typescript = "TypeScript (components.d.ts)"
        case directive = "Директива Antigravity"

        var id: String { rawValue }
    }

    private var components: [UIComponentContract] {
        ComponentContractMatrix.starterPack
    }

    private var selectedComponent: UIComponentContract? {
        components.first(where: { $0.id == selectedComponentId })
    }

    private var currentText: String {
        switch activeTab {
        case .typescript:
            return ComponentContractMatrix.generateTypeScriptDefinitions(components: components)
        case .directive:
            return ComponentContractMatrix.generatePromptDirective(components: components)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "square.split.2x2.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Матрица UI-компонентов (Component Contracts)")
                        .font(.headline)
                    Text("Строгие интерфейсы пропсов, состояний и доступности без галлюцинаций ИИ")
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

            // Main Content: List + Code
            HSplitView {
                // Left: Components List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Компоненты системы:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(components) { comp in
                                Button {
                                    selectedComponentId = comp.id
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "cube")
                                            .foregroundStyle(Color.accentColor)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(comp.name)
                                                .font(.subheadline.bold())
                                            Text(comp.description)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(selectedComponentId == comp.id ? Color.accentColor.opacity(0.12) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if let sel = selectedComponent {
                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Обязательные состояния:")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                ForEach(sel.requiredStates, id: \.self) { st in
                                    Text(st)
                                        .font(.caption2.monospaced())
                                        .padding(.horizontal, 6) // grid: ok
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }

                            Text("ARIA Role: \(sel.a11yRole)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 260, idealWidth: 280)

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
                            .font(.system(size: 11, design: .monospaced)) // grid: ok
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
