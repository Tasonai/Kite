import Foundation

public struct ExtractedDesignSystem: Sendable {
    public let name: String
    public let primaryColor: String
    public let surfaceColor: String
    public let textColor: String
    public let typography: String
    public let referenceScreens: [CanvasReferenceCard]
}

public enum FigmaStitchBridge {
    public static func parseDesignTokens(from text: String) -> ExtractedDesignSystem {
        var primary = "#3B82F6"
        var surface = "#1E293B"
        var textCol = "#F8FAFC"
        var typo = "Inter / SF Pro"
        var screens: [CanvasReferenceCard] = []

        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("primary") || lower.contains("accent") {
                if let hex = extractHex(from: line) { primary = hex }
            } else if lower.contains("surface") || lower.contains("card") {
                if let hex = extractHex(from: line) { surface = hex }
            } else if lower.contains("text") || lower.contains("foreground") {
                if let hex = extractHex(from: line) { textCol = hex }
            } else if lower.contains("font") || lower.contains("typography") {
                typo = line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
            } else if lower.contains("screen") || lower.contains("frame") || lower.contains("view") {
                let card = CanvasReferenceCard(
                    title: line.trimmingCharacters(in: CharacterSet(charactersIn: "#*- ")),
                    source: "Figma / Stitch",
                    url: "https://stitch.design",
                    colorHex: primary,
                    position: CGPoint(x: 150, y: 150 + (screens.count * 140)),
                    tags: ["UI", "Token", "Figma"],
                    description: "Imported from design system specification."
                )
                screens.append(card)
            }
        }

        if screens.isEmpty {
            screens.append(CanvasReferenceCard(
                title: "Primary Dashboard Screen",
                source: "Figma Spec",
                url: "https://figma.com",
                colorHex: primary,
                position: CGPoint(x: 150, y: 150),
                tags: ["Figma", "Design System"],
                description: "Design system screen layout with extracted color tokens."
            ))
        }

        return ExtractedDesignSystem(
            name: "Imported Design System",
            primaryColor: primary,
            surfaceColor: surface,
            textColor: textCol,
            typography: typo,
            referenceScreens: screens
        )
    }

    private static func extractHex(from line: String) -> String? {
        let pattern = "#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsString = line as NSString
            if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length)) {
                return nsString.substring(with: match.range)
            }
        }
        return nil
    }
}
