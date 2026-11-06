import Foundation

public struct ContextOptimizerMetrics: Sendable, Equatable {
    public var rawTokensEstimated: Int
    public var compressedTokensEstimated: Int
    public var savedPercentage: Int

    public init(rawTokensEstimated: Int, compressedTokensEstimated: Int, savedPercentage: Int) {
        self.rawTokensEstimated = rawTokensEstimated
        self.compressedTokensEstimated = compressedTokensEstimated
        self.savedPercentage = savedPercentage
    }
}

public enum ContextOptimizer {
    public static func estimateMetrics(title: String, concept: String, entities: [SchemaEntity], routes: [APIRoute]) -> ContextOptimizerMetrics {
        let rawTokens = 12000 + (entities.count * 1500) + (routes.count * 800)
        let compressedTokens = 350 + (entities.count * 45) + (routes.count * 30)
        let saved = max(1, 100 - (compressedTokens * 100 / max(1, rawTokens)))
        return ContextOptimizerMetrics(
            rawTokensEstimated: rawTokens,
            compressedTokensEstimated: compressedTokens,
            savedPercentage: saved
        )
    }

    public static func compileDigest(
        title: String,
        concept: String,
        platform: String,
        style: String,
        entities: [SchemaEntity],
        routes: [APIRoute]
    ) -> String {
        var lines: [String] = [
            "<!-- ANTIGRAVITY CONTEXT DIGEST (Ultra-Dense Token Spec) -->",
            "# SYSTEM: \(title.uppercased())",
            "PLATFORM: \(platform) | AESTHETIC: \(style)",
            "CONCEPT: \(concept.replacingOccurrences(of: "\n", with: " "))",
            "",
            "## 1. DATA ENTITIES & TYPES"
        ]

        if entities.isEmpty {
            lines.append("- (Entities managed in-memory or by static state)")
        } else {
            for entity in entities {
                let fieldsStr = entity.fields.map { "\($0.name):\($0.type.rawValue)" }.joined(separator: ", ")
                lines.append("- \(entity.name) { \(fieldsStr) }")
            }
        }

        lines.append("")
        lines.append("## 2. API ENDPOINTS & SIGNATURES")

        if routes.isEmpty {
            lines.append("- (Direct local state calls without REST layer)")
        } else {
            for route in routes {
                lines.append("- \(route.method.rawValue) \(route.path) -> \(route.responseBodySample.replacingOccurrences(of: "\n", with: "").prefix(60))...")
            }
        }

        lines.append("")
        lines.append("## 3. STRICT WORKING DIRECTIVE")
        lines.append("1. Do not ask for architectural clarification; implement according to this digest.")
        lines.append("2. Rely solely on these signatures to prevent schema drift.")
        lines.append("3. Keep responses compact and diff-focused to minimize token expenditure.")

        return lines.joined(separator: "\n")
    }
}
