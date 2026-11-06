import SwiftUI
import KiteKit

struct NegativeScopeSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: FirewallMode = .manifest
    @State private var isCopied: Bool = false

    enum FirewallMode: String, CaseIterable, Identifiable {
        case manifest = "Манифест (OUT_OF_SCOPE.md)"
        case prompt = "Firewall-промпт"

        var id: String { rawValue }
    }

    private var constraints: [ScopeConstraint] {
        NegativeScopeFirewall.defaultConstraints
    }

    private var currentText: String {
        switch activeTab {
        case .manifest:
            return NegativeScopeFirewall.generateManifest(title: title, constraints: constraints)
        case .prompt:
            return NegativeScopeFirewall.generateFirewallPrompt(constraints: constraints)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "shield.slash.fill")
                    .font(.title2)
                    .foregroundStyle(Color.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Барьер от оверинжиниринга (Negative Scope Firewall)")
                        .font(.headline)
                    Text("Жесткий список запретов для ИИ: предотвращает лишний код, чужие базы и сгорание кредитов")
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

            HSplitView {
                // Left: Constraints List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Запрещенные действия (\(constraints.count)):")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Строгий блок")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6) // grid: ok
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.14))
                            .foregroundStyle(Color.red)
                            .clipShape(Capsule())
                    }

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(constraints) { c in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(c.category)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6) // grid: ok
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.12))
                                            .clipShape(Capsule())

                                        Spacer()
                                    }

                                    Text(c.title)
                                        .font(.caption.bold())
                                        .foregroundStyle(Color.red)

                                    Text(c.rationale)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
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
                .frame(minWidth: 260, idealWidth: 280)

                // Right: Generated Spec
                VStack(spacing: 12) {
                    HStack {
                        Picker("", selection: $activeTab) {
                            ForEach(FirewallMode.allCases) { mode in
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
