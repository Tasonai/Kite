import Foundation

public struct MigrationStep: Identifiable, Sendable, Equatable {
    public var id: String { phaseName }
    public var phaseName: String
    public var description: String
    public var sqlUp: String
    public var sqlDown: String
    public var isZeroDowntimeSafe: Bool

    public init(phaseName: String, description: String, sqlUp: String, sqlDown: String, isZeroDowntimeSafe: Bool) {
        self.phaseName = phaseName
        self.description = description
        self.sqlUp = sqlUp
        self.sqlDown = sqlDown
        self.isZeroDowntimeSafe = isZeroDowntimeSafe
    }
}

public enum MigrationStrategist {
    public static var starterSteps: [MigrationStep] {
        [
            MigrationStep(
                phaseName: "1. Expand: Добавление новой nullable колонки",
                description: "Добавляем новое поле без блокировки таблицы и без требования заполненности",
                sqlUp: "ALTER TABLE items ADD COLUMN status_v2 VARCHAR(32) NULL;",
                sqlDown: "ALTER TABLE items DROP COLUMN IF EXISTS status_v2;",
                isZeroDowntimeSafe: true
            ),
            MigrationStep(
                phaseName: "2. Backfill: Фоновое заполнение данных",
                description: "Порционная миграция существующих строк батчами во избежание блокировки блокирующих блокировок",
                sqlUp: "UPDATE items SET status_v2 = LOWER(status) WHERE status_v2 IS NULL;",
                sqlDown: "-- No rollback required for data backfill",
                isZeroDowntimeSafe: true
            ),
            MigrationStep(
                phaseName: "3. Dual Write: Двойная запись в приложении",
                description: "Приложение читает из старого поля, но одновременно пишет и в старое, и в новое",
                sqlUp: "-- Handled in application logic layer (Prisma / Drizzle dual-write)",
                sqlDown: "-- Handled in application rollback",
                isZeroDowntimeSafe: true
            ),
            MigrationStep(
                phaseName: "4. Contract: Удаление старого поля",
                description: "После полного перехода чтения на новое поле старая колонка безопасно удаляется",
                sqlUp: "ALTER TABLE items DROP COLUMN status;",
                sqlDown: "ALTER TABLE items ADD COLUMN status VARCHAR(32) NULL;",
                isZeroDowntimeSafe: true
            )
        ]
    }

    public static func generateMigrationsMarkdown(title: String, steps: [MigrationStep]) -> String {
        var lines: [String] = [
            "# ZERO-DOWNTIME DATABASE MIGRATION SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in performing non-destructive schema migrations.",
            "NEVER execute immediate rename or destructive DROP commands on active production tables.",
            ""
        ]

        for (idx, step) in steps.enumerated() {
            lines.append("## Phase \(idx + 1): \(step.phaseName)")
            lines.append("- Description: \(step.description)")
            lines.append("- Zero-Downtime Safe: `\(step.isZeroDowntimeSafe)`")
            lines.append("- Migration UP:")
            lines.append("```sql")
            lines.append(step.sqlUp)
            lines.append("```")
            lines.append("- Migration DOWN:")
            lines.append("```sql")
            lines.append(step.sqlDown)
            lines.append("```")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(steps: [MigrationStep]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY SAFE MIGRATION DIRECTIVE]",
            "Do NOT run destructive migrations (ALTER TABLE RENAME, DROP COLUMN without dual-write).",
            "Follow the Expand & Contract methodology:",
            ""
        ]

        for s in steps {
            lines.append("- \(s.phaseName): \(s.description)")
        }

        lines.append("")
        lines.append("Always provide reversible UP and DOWN scripts and ensure backwards compatibility.")
        return lines.joined(separator: "\n")
    }
}
