import Foundation

/// Tokenized, ranked search. Every query token must match at least one field;
/// a field's weight, a whole-word hit and a prefix hit raise the score.
public enum ItemSearch {
    public struct Field: Sendable {
        public let text: String
        public let weight: Int

        public init(_ text: String, weight: Int) {
            self.text = text
            self.weight = weight
        }
    }

    /// Lowercased, diacritic-folded word tokens. Punctuation separates tokens.
    public static func tokens(_ text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    /// Returns nil when any token has no match, otherwise a score (higher is better).
    public static func score(query: String, fields: [Field]) -> Int? {
        let queryTokens = tokens(query)
        guard !queryTokens.isEmpty else { return 0 }

        let indexed = fields.map { (words: tokens($0.text), weight: $0.weight) }
        var total = 0
        for token in queryTokens {
            var best = 0
            for field in indexed {
                for word in field.words {
                    if word == token {
                        best = max(best, field.weight * 3)
                    } else if word.hasPrefix(token) {
                        best = max(best, field.weight * 2)
                    } else if word.contains(token) {
                        best = max(best, field.weight)
                    }
                }
            }
            if best == 0 { return nil }
            total += best
        }
        return total
    }

    /// Splits text into runs so a view can emphasize the parts that matched.
    public static func highlightRanges(in text: String, query: String) -> [Range<String.Index>] {
        let needles = tokens(query)
        guard !needles.isEmpty else { return [] }
        var ranges: [Range<String.Index>] = []
        for needle in needles {
            var searchStart = text.startIndex
            while let found = text.range(
                of: needle,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchStart..<text.endIndex
            ) {
                ranges.append(found)
                searchStart = found.upperBound
            }
        }
        return ranges.sorted { $0.lowerBound < $1.lowerBound }
    }
}
