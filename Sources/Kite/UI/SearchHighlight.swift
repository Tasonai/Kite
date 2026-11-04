import SwiftUI
import KiteKit

/// Emphasizes the parts of `text` that matched the search query.
func searchHighlighted(_ text: String, query: String) -> AttributedString {
    var result = AttributedString(text)
    for range in ItemSearch.highlightRanges(in: text, query: query) {
        guard let attributedRange = Range(range, in: result) else { continue }
        result[attributedRange].backgroundColor = Color.accentColor.opacity(0.28)
        result[attributedRange].inlinePresentationIntent = .stronglyEmphasized
    }
    return result
}
