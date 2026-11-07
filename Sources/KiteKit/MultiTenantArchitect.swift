import Foundation

public struct TenantRole: Identifiable, Sendable, Equatable {
    public var id: String { roleName }
    public var roleName: String
    public var permissions: [String]
    public var canManageBilling: Bool
    public var canInviteMembers: Bool

    public init(roleName: String, permissions: [String], canManageBilling: Bool, canInviteMembers: Bool) {
        self.roleName = roleName
        self.permissions = permissions
        self.canManageBilling = canManageBilling
        self.canInviteMembers = canInviteMembers
    }
}

public enum MultiTenantArchitect {
    public static var starterRoles: [TenantRole] {
        [
            TenantRole(
                roleName: "Owner",
                permissions: ["*"],
                canManageBilling: true,
                canInviteMembers: true
            ),
            TenantRole(
                roleName: "Admin",
                permissions: ["items:read", "items:write", "members:manage", "settings:write"],
                canManageBilling: false,
                canInviteMembers: true
            ),
            TenantRole(
                roleName: "Member",
                permissions: ["items:read", "items:write"],
                canManageBilling: false,
                canInviteMembers: false
            ),
            TenantRole(
                roleName: "Viewer",
                permissions: ["items:read"],
                canManageBilling: false,
                canInviteMembers: false
            )
        ]
    }

    public static func generateTenancyMarkdown(title: String, roles: [TenantRole]) -> String {
        var lines: [String] = [
            "# MULTI-TENANT ISOLATION & RBAC SPEC: \(title.uppercased())",
            "This document establishes strict organizational tenancy barriers for Google DeepMind Antigravity.",
            "EVERY single query, table, mutation, and cache key MUST include `tenant_id` scoping.",
            ""
        ]

        for (idx, r) in roles.enumerated() {
            lines.append("## Role \(idx + 1): `\(r.roleName)`")
            lines.append("- Permissions: `\(r.permissions.joined(separator: ", "))`")
            lines.append("- Billing Access: `\(r.canManageBilling)`")
            lines.append("- Member Management: `\(r.canInviteMembers)`")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateTenantMiddlewareSnippet() -> String {
        let lines: [String] = [
            "// middleware/tenantContext.ts",
            "// Secure multi-tenant resolution and isolation middleware",
            "import { headers } from 'next/headers';",
            "",
            "export interface TenantContext {",
            "  tenantId: string;",
            "  role: string;",
            "}",
            "",
            "export async function getTenantContext(): Promise<TenantContext> {",
            "  const headerList = await headers();",
            "  const tenantId = headerList.get('x-tenant-id');",
            "  const role = headerList.get('x-tenant-role') || 'Viewer';",
            "",
            "  if (!tenantId) {",
            "    throw new Error('Missing Tenant Context: Cross-tenant operations are strictly prohibited');",
            "  }",
            "",
            "  return { tenantId, role };",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(roles: [TenantRole]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY MULTI-TENANT DIRECTIVE]",
            "Do NOT write single-tenant database queries or omit `tenant_id` in WHERE clauses.",
            "Enforce organizational tenancy across all operations:",
            ""
        ]

        for r in roles {
            lines.append("- Role `\(r.roleName)`: permissions [\(r.permissions.joined(separator: ", "))]")
        }

        lines.append("")
        lines.append("Always scope data by tenant_id and verify user roles before granting write or billing actions.")
        return lines.joined(separator: "\n")
    }
}
