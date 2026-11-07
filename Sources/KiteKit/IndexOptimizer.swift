import Foundation

public struct QueryIndexRecommendation: Identifiable, Sendable, Equatable {
    public var id: String { "\(tableName)_\(indexName)" }
    public var tableName: String
    public var indexName: String
    public var columns: [String]
    public var indexType: String
    public var queryPattern: String
    public var estimatedImpact: String
    public var ddlStatement: String

    public init(
        tableName: String,
        indexName: String,
        columns: [String],
        indexType: String,
        queryPattern: String,
        estimatedImpact: String,
        ddlStatement: String
    ) {
        self.tableName = tableName
        self.indexName = indexName
        self.columns = columns
        self.indexType = indexType
        self.queryPattern = queryPattern
        self.estimatedImpact = estimatedImpact
        self.ddlStatement = ddlStatement
    }
}

public enum IndexOptimizer {
    public static var starterRecommendations: [QueryIndexRecommendation] {
        [
            QueryIndexRecommendation(
                tableName: "workspaces",
                indexName: "idx_workspaces_user_updated",
                columns: ["user_id", "updated_at DESC"],
                indexType: "Composite B-Tree",
                queryPattern: "SELECT * FROM workspaces WHERE user_id = $1 ORDER BY updated_at DESC LIMIT 20;",
                estimatedImpact: "98% latency reduction (410ms -> 3.2ms) via Index Scan",
                ddlStatement: "CREATE INDEX CONCURRENTLY idx_workspaces_user_updated ON workspaces (user_id, updated_at DESC);"
            ),
            QueryIndexRecommendation(
                tableName: "canvas_nodes",
                indexName: "idx_canvas_nodes_tags_gin",
                columns: ["tags"],
                indexType: "GIN (Generalized Inverted Index)",
                queryPattern: "SELECT * FROM canvas_nodes WHERE tags @> ARRAY['gemini', 'vibe'];",
                estimatedImpact: "Replaces table scan with Bitmap Index Scan (320ms -> 2.1ms on 500k rows)",
                ddlStatement: "CREATE INDEX CONCURRENTLY idx_canvas_nodes_tags_gin ON canvas_nodes USING GIN (tags);"
            ),
            QueryIndexRecommendation(
                tableName: "telemetry_events",
                indexName: "idx_telemetry_created_brin",
                columns: ["created_at"],
                indexType: "BRIN (Block Range Index)",
                queryPattern: "SELECT COUNT(*) FROM telemetry_events WHERE created_at >= NOW() - INTERVAL '7 days';",
                estimatedImpact: "95% smaller index storage footprint than standard B-Tree for append-only logs",
                ddlStatement: "CREATE INDEX CONCURRENTLY idx_telemetry_created_brin ON telemetry_events USING BRIN (created_at);"
            )
        ]
    }

    public static func generateIndexMarkdown(title: String, indexes: [QueryIndexRecommendation]) -> String {
        var lines: [String] = [
            "# DATABASE INDEXING & QUERY PLAN SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in applying zero-downtime indexes and optimizing query performance.",
            "All PostgreSQL indexes MUST use CREATE INDEX CONCURRENTLY to prevent table write locks.",
            ""
        ]

        for (idx, item) in indexes.enumerated() {
            lines.append("## \(idx + 1). Index `\(item.indexName)` on `\(item.tableName)`")
            lines.append("- Type: \(item.indexType)")
            lines.append("- Indexed Columns: `\(item.columns.joined(separator: ", "))`")
            lines.append("- Target Query Pattern: `\(item.queryPattern)`")
            lines.append("- Estimated Performance Gain: \(item.estimatedImpact)")
            lines.append("- DDL:")
            lines.append("```sql")
            lines.append(item.ddlStatement)
            lines.append("```")
            lines.append("")
        }

        lines.append("## EXPLAIN ANALYZE Optimization Rules")
        lines.append("1. Always check for Sequential Scans (Seq Scan) on tables exceeding 5,000 rows.")
        lines.append("2. Guard against missing composite indexes when queries use WHERE ... ORDER BY.")
        lines.append("3. For JSONB or array columns, always utilize GIN or expression indexes.")

        return lines.joined(separator: "\n")
    }

    public static func generateSqlMigration(indexes: [QueryIndexRecommendation]) -> String {
        var lines: [String] = [
            "-- Migration: optimize_database_query_indexes.sql",
            "-- Zero-downtime concurrent index creations",
            ""
        ]

        for item in indexes {
            lines.append("-- \(item.tableName): \(item.estimatedImpact)")
            lines.append(item.ddlStatement)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(indexes: [QueryIndexRecommendation]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY DATABASE INDEXING DIRECTIVE]",
            "Apply the following index optimizations to PostgreSQL / Supabase schemas.",
            "Never create indexes synchronously in production; always use CONCURRENTLY:",
            ""
        ]

        for item in indexes {
            lines.append("- [\(item.tableName)]: `\(item.ddlStatement)`")
        }

        lines.append("")
        lines.append("Verify query plan speedups with EXPLAIN (ANALYZE, BUFFERS) after migration.")
        return lines.joined(separator: "\n")
    }
}
