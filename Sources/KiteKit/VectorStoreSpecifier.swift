import Foundation

public struct VectorIndexConfig: Identifiable, Sendable, Equatable {
    public var id: String { collectionName }
    public var collectionName: String
    public var embeddingModel: String
    public var dimensions: Int
    public var chunkSizeTokens: Int
    public var chunkOverlapTokens: Int
    public var distanceMetric: String

    public init(collectionName: String, embeddingModel: String, dimensions: Int, chunkSizeTokens: Int, chunkOverlapTokens: Int, distanceMetric: String) {
        self.collectionName = collectionName
        self.embeddingModel = embeddingModel
        self.dimensions = dimensions
        self.chunkSizeTokens = chunkSizeTokens
        self.chunkOverlapTokens = chunkOverlapTokens
        self.distanceMetric = distanceMetric
    }
}

public enum VectorStoreSpecifier {
    public static var starterConfigs: [VectorIndexConfig] {
        [
            VectorIndexConfig(
                collectionName: "document_chunks",
                embeddingModel: "text-embedding-004",
                dimensions: 768,
                chunkSizeTokens: 512,
                chunkOverlapTokens: 64,
                distanceMetric: "cosine"
            ),
            VectorIndexConfig(
                collectionName: "code_snippets",
                embeddingModel: "text-embedding-004",
                dimensions: 768,
                chunkSizeTokens: 256,
                chunkOverlapTokens: 32,
                distanceMetric: "inner_product"
            )
        ]
    }

    public static func generateVectorStoreMarkdown(title: String, configs: [VectorIndexConfig]) -> String {
        var lines: [String] = [
            "# VECTOR STORE & RAG RETRIEVAL SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in implementing grounded vector search.",
            "All embeddings, chunking pipelines, and vector indices MUST adhere to these schema definitions.",
            ""
        ]

        for (idx, c) in configs.enumerated() {
            lines.append("## \(idx + 1). `\(c.collectionName)`")
            lines.append("- Model: `\(c.embeddingModel)` (\(c.dimensions) dimensions)")
            lines.append("- Chunk Size: \(c.chunkSizeTokens) tokens (Overlap: \(c.chunkOverlapTokens) tokens)")
            lines.append("- Metric: `\(c.distanceMetric)`")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePgVectorDDL(configs: [VectorIndexConfig]) -> String {
        var lines: [String] = [
            "-- PostgreSQL pgvector DDL schema",
            "CREATE EXTENSION IF NOT EXISTS vector;",
            ""
        ]

        for c in configs {
            lines.append("CREATE TABLE IF NOT EXISTS \(c.collectionName) (")
            lines.append("  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),")
            lines.append("  tenant_id UUID NOT NULL,")
            lines.append("  content TEXT NOT NULL,")
            lines.append("  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,")
            lines.append("  embedding vector(\(c.dimensions)) NOT NULL,")
            lines.append("  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()")
            lines.append(");")
            lines.append("")
            lines.append("CREATE INDEX IF NOT EXISTS idx_\(c.collectionName)_hnsw ON \(c.collectionName)")
            lines.append("  USING hnsw (embedding vector_cosine_ops);")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(configs: [VectorIndexConfig]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY VECTOR STORE & RAG DIRECTIVE]",
            "Do NOT store unbounded raw documents without deterministic chunking.",
            "Implement vector retrieval adhering strictly to these index specifications:",
            ""
        ]

        for c in configs {
            lines.append("- Collection `\(c.collectionName)`: \(c.embeddingModel) (\(c.dimensions) dims), Chunk: \(c.chunkSizeTokens), Overlap: \(c.chunkOverlapTokens).")
        }

        lines.append("")
        lines.append("Always filter vectors by tenant_id to prevent cross-tenant information disclosure.")
        return lines.joined(separator: "\n")
    }
}
