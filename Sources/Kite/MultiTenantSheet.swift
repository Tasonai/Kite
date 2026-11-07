import SwiftUI
import KiteKit

struct MultiTenantSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (TENANCY.md)"
        case middleware = "Мидлвар (tenantContext.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var roles: [TenantRole] {
        MultiTenantArchitect.starterRoles
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return MultiTenantArchitect.generateTenancyMarkdown(title: title, roles: roles)
        case .middleware:
            return MultiTenantArchitect.generateTenantMiddlewareSnippet()
        case .prompt:
            return MultiTenantArchitect.generatePromptDirective(roles: roles)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Архитектор мульти-тенантности и RBAC (Multi-Tenant Architect)")
                        .font(.headline)
                    Text("Изоляция данных организаций, роли доступа (Owner/Admin/Member/Viewer) и проверка тенанта")
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
                // Left: Roles List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Роли доступа (\(roles.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(roles) { r in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(r.roleName)
                                            .font(.caption.bold())
                                        Spacer()
                                        if r.canManageBilling {
                                            Text("Биллинг")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.12))
                                                .foregroundStyle(Color.green)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                    }

                                    Text("Права: \(r.permissions.joined(separator: ", "))")
                                        .font(.caption2.monospaced())
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)

                                    Text("Инвайты участников: \(r.canInviteMembers ? "Да" : "Нет")")
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
                .frame(minWidth: 280, idealWidth: 300)

                // Right: Generated Output
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
