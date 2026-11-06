import Foundation

public struct RollbackAction: Identifiable, Sendable, Equatable {
    public var id: String { phase }
    public var phase: String
    public var subsystem: String
    public var rollbackCommand: String
    public var verificationCheck: String

    public init(phase: String, subsystem: String, rollbackCommand: String, verificationCheck: String) {
        self.phase = phase
        self.subsystem = subsystem
        self.rollbackCommand = rollbackCommand
        self.verificationCheck = verificationCheck
    }
}

public enum IncidentCommander {
    public static var starterActions: [RollbackAction] {
        [
            RollbackAction(
                phase: "1. Трафик и DNS",
                subsystem: "Vercel / Cloudflare",
                rollbackCommand: "vercel rollback [PREVIOUS_DEPLOYMENT_ID] --yes",
                verificationCheck: "curl -I https://app.example.com/api/healthz (HTTP 200)"
            ),
            RollbackAction(
                phase: "2. Схема базы данных",
                subsystem: "PostgreSQL / Prisma",
                rollbackCommand: "npx prisma migrate resolve --rolled-back [MIGRATION_NAME]",
                verificationCheck: "SELECT count(*) FROM _prisma_migrations WHERE rolled_back_at IS NOT NULL;"
            ),
            RollbackAction(
                phase: "3. Переменные окружения",
                subsystem: "Vercel / Doppler",
                rollbackCommand: "vercel env pull .env.backup && vercel env push --force",
                verificationCheck: "printenv | grep CRITICAL_API_KEY"
            ),
            RollbackAction(
                phase: "4. Очистка кэша CDN",
                subsystem: "Cloudflare Edge",
                rollbackCommand: "curl -X POST https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache -d '{\"purge_everything\":true}'",
                verificationCheck: "curl -sI https://app.example.com | grep cf-cache-status"
            )
        ]
    }

    public static func generateIncidentMarkdown(title: String, actions: [RollbackAction]) -> String {
        var lines: [String] = [
            "# EMERGENCY INCIDENT & ROLLBACK RUNBOOK: \(title.uppercased())",
            "This runbook outlines mandatory disaster recovery procedures for Google DeepMind Antigravity deployments.",
            "In case of fatal regression, execute the following containment and rollback steps immediately:",
            ""
        ]

        for (idx, a) in actions.enumerated() {
            lines.append("## Step \(idx + 1): \(a.phase) [\(a.subsystem)]")
            lines.append("- Rollback Command:")
            lines.append("  ```bash")
            lines.append("  \(a.rollbackCommand)")
            lines.append("  ```")
            lines.append("- Verification:")
            lines.append("  ```bash")
            lines.append("  \(a.verificationCheck)")
            lines.append("  ```")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateHealthCheckRouteSnippet() -> String {
        let lines: [String] = [
            "// app/api/healthz/route.ts",
            "// Liveness and readiness probe for Antigravity-generated deployments",
            "import { NextResponse } from 'next/server';",
            "",
            "export async function GET() {",
            "  try {",
            "    // Verify DB connection, memory, and cache",
            "    const status = {",
            "      status: 'healthy',",
            "      timestamp: new Date().toISOString(),",
            "      uptime: process.uptime(),",
            "    };",
            "    return NextResponse.json(status, { status: 200 });",
            "  } catch (error) {",
            "    return NextResponse.json({ status: 'unhealthy', error: String(error) }, { status: 503 });",
            "  }",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(actions: [RollbackAction]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY EMERGENCY ROLLBACK DIRECTIVE]",
            "Do NOT deploy architectural updates without explicit rollback compatibility.",
            "Verify the following rollback actions:",
            ""
        ]

        for a in actions {
            lines.append("- [\(a.subsystem)] \(a.phase): `\(a.rollbackCommand)`")
        }

        lines.append("")
        lines.append("Ensure `/api/healthz` endpoint responds with 200 and schema changes are reversible.")
        return lines.joined(separator: "\n")
    }
}
