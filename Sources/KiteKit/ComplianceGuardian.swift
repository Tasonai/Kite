import Foundation

public struct CompliancePolicy: Identifiable, Sendable, Equatable {
    public var id: String { article }
    public var article: String
    public var title: String
    public var implementationPattern: String
    public var retentionDays: Int

    public init(article: String, title: String, implementationPattern: String, retentionDays: Int) {
        self.article = article
        self.title = title
        self.implementationPattern = implementationPattern
        self.retentionDays = retentionDays
    }
}

public enum ComplianceGuardian {
    public static var starterPolicies: [CompliancePolicy] {
        [
            CompliancePolicy(
                article: "GDPR Art. 17",
                title: "Право на забвение (Right to Erasure)",
                implementationPattern: "Каскадное удаление личных данных или их безвозвратная анонимизация по запросу пользователя.",
                retentionDays: 30
            ),
            CompliancePolicy(
                article: "GDPR Art. 20",
                title: "Право на переносимость данных (Data Portability)",
                implementationPattern: "Выгрузка всех созданных пользователем записей в виде структурированного JSON/ZIP архива.",
                retentionDays: 7
            ),
            CompliancePolicy(
                article: "ePrivacy / Cookie Consent",
                title: "Управление согласием на аналитические cookies",
                implementationPattern: "Блокировка инициализации трекеров аналитики до явного согласия пользователя через баннер.",
                retentionDays: 365
            ),
            CompliancePolicy(
                article: "Audit Log Retention",
                title: "Политика хранения журналов безопасности",
                implementationPattern: "Хранение логов доступа и изменений в защищенном WORM-хранилище с автоматическим TTL удалением.",
                retentionDays: 90
            )
        ]
    }

    public static func generateComplianceMarkdown(title: String, policies: [CompliancePolicy]) -> String {
        var lines: [String] = [
            "# PRIVACY & COMPLIANCE SPECIFICATION: \(title.uppercased())",
            "This document establishes GDPR, CCPA, and data privacy mandates for Google DeepMind Antigravity.",
            "All storage layers, APIs, and analytics MUST comply with these data handling policies.",
            ""
        ]

        for (idx, p) in policies.enumerated() {
            lines.append("## \(idx + 1). [\(p.article)] \(p.title)")
            lines.append("- Implementation Pattern: \(p.implementationPattern)")
            lines.append("- Retention Policy: \(p.retentionDays) days")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateDeletionHandlerSnippet() -> String {
        let lines: [String] = [
            "// app/api/account/delete-data/route.ts",
            "// GDPR Article 17 compliant user erasure route",
            "import { NextResponse } from 'next/server';",
            "",
            "export async function POST(req: Request) {",
            "  try {",
            "    const { userId } = await req.json();",
            "    if (!userId) return NextResponse.json({ error: 'User ID required' }, { status: 400 });",
            "",
            "    // 1. Transactionally cascade delete user records",
            "    // await db.$transaction([",
            "    //   db.auditLog.updateMany({ where: { userId }, data: { ip: '[ANONYMIZED]' } }),",
            "    //   db.userItems.deleteMany({ where: { userId } }),",
            "    //   db.user.delete({ where: { id: userId } }),",
            "    // ]);",
            "",
            "    console.log('[GDPR Erasure] User data permanently removed:', userId);",
            "    return NextResponse.json({ success: true, message: 'User data purged successfully' });",
            "  } catch (error) {",
            "    return NextResponse.json({ error: 'Erasure failed' }, { status: 500 });",
            "  }",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(policies: [CompliancePolicy]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY COMPLIANCE & PRIVACY DIRECTIVE]",
            "Do NOT store personal identifiable information (PII) without user consent and erasure endpoints.",
            "Implement mandatory privacy compliance features:",
            ""
        ]

        for p in policies {
            lines.append("- [\(p.article)] \(p.title): \(p.implementationPattern)")
        }

        lines.append("")
        lines.append("Provide `/api/account/delete-data` and cookie consent gates before initializing telemetry.")
        return lines.joined(separator: "\n")
    }
}
