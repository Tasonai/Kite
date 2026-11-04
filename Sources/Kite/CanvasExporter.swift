import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import KiteKit

@MainActor
enum CanvasExporter {
    static func exportSVG(
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky],
        connections: [CanvasConnection]
    ) -> String {
        // Calculate canvas bounds
        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude

        for (idx, item) in items.enumerated() {
            let pos = itemPositions[item.uuid] ?? CGPoint(x: 160 + (idx % 3) * 320, y: 160 + (idx / 3) * 240)
            minX = min(minX, pos.x - 140)
            minY = min(minY, pos.y - 70)
            maxX = max(maxX, pos.x + 140)
            maxY = max(maxY, pos.y + 70)
        }

        for sticky in stickies {
            minX = min(minX, sticky.position.x)
            minY = min(minY, sticky.position.y)
            maxX = max(maxX, sticky.position.x + 200)
            maxY = max(maxY, sticky.position.y + 160)
        }

        if minX > maxX {
            minX = 0; minY = 0; maxX = 1200; maxY = 800
        }

        let pad: CGFloat = 64
        let originX = minX - pad
        let originY = minY - pad
        let totalW = max(800, maxX - minX + pad * 2)
        let totalH = max(600, maxY - minY + pad * 2)

        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="\(Int(totalW))" height="\(Int(totalH))" viewBox="\(Int(originX)) \(Int(originY)) \(Int(totalW)) \(Int(totalH))" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
              <path d="M 0 1 L 9 5 L 0 9 z" fill="#D97757"/>
            </marker>
            <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
              <feDropShadow dx="0" dy="4" stdDeviation="6" flood-opacity="0.25"/>
            </filter>
          </defs>
          <style>
            text { font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", Roboto, sans-serif; }
            .card-title { font-weight: 700; font-size: 15px; fill: #FFFFFF; }
            .card-desc { font-size: 12px; fill: #A09D95; } // grid: ok svg style
            .sticky-text { font-family: -apple-system, BlinkMacSystemFont, "SF Pro Rounded", sans-serif; font-weight: 600; font-size: 13px; fill: #1C1B18; }
            .tag { font-family: "SF Mono", monospace; font-size: 10px; fill: #8C8980; }
          </style>

          <!-- Canvas Background -->
          <rect x="\(Int(originX))" y="\(Int(originY))" width="\(Int(totalW))" height="\(Int(totalH))" fill="#141413" />

          <!-- Connection Lines -->
          <g id="connections">
        """

        for conn in connections {
            if let (start, end) = resolvePoints(conn: conn, items: items, itemPositions: itemPositions, stickies: stickies) {
                let dx = end.x - start.x
                let c1x = start.x + dx * 0.5
                let c2x = end.x - dx * 0.5
                svg += """

            <path d="M \(Int(start.x)) \(Int(start.y)) C \(Int(c1x)) \(Int(start.y)), \(Int(c2x)) \(Int(end.y)), \(Int(end.x)) \(Int(end.y))" stroke="#D97757" stroke-width="2.5" fill="none" stroke-dasharray="6,4" marker-end="url(#arrow)" />
        """
                if !conn.label.isEmpty {
                    let midX = (start.x + end.x) / 2
                    let midY = (start.y + end.y) / 2
                    svg += """

            <rect x="\(Int(midX - 40))" y="\(Int(midY - 12))" width="80" height="24" rx="12" fill="#232321" stroke="#D97757" stroke-width="1" />
            <text x="\(Int(midX))" y="\(Int(midY + 4))" font-size="11" font-weight="600" fill="#FAF9F5" text-anchor="middle">\(escapeXml(conn.label))</text>
        """
                }
            }
        }

        svg += "\n  </g>\n\n  <!-- Stickies -->\n  <g id=\"stickies\">"

        for sticky in stickies {
            let sx = Int(sticky.position.x)
            let sy = Int(sticky.position.y)
            svg += """

            <g transform="translate(\(sx), \(sy))" filter="url(#shadow)">
              <rect width="200" height="160" rx="8" fill="\(sticky.colorHex)" />
              <text x="16" y="32" class="sticky-text" width="168">
                \(escapeXml(sticky.text))
              </text>
            </g>
        """
        }

        svg += "\n  </g>\n\n  <!-- Idea Cards -->\n  <g id=\"ideas\">"

        for (idx, item) in items.enumerated() {
            let pos = itemPositions[item.uuid] ?? CGPoint(x: 160 + (idx % 3) * 320, y: 160 + (idx / 3) * 240)
            let cardX = Int(pos.x - 140)
            let cardY = Int(pos.y - 70)
            svg += """

            <g transform="translate(\(cardX), \(cardY))" filter="url(#shadow)">
              <rect width="280" height="140" rx="12" fill="#1C1B18" stroke="#33322E" stroke-width="1" />
              <circle cx="24" cy="28" r="5" fill="\(item.status == "completed" ? "#10B981" : (item.status == "in_progress" ? "#3B82F6" : "#8C8980"))" />
              <text x="40" y="32" class="card-title">\(escapeXml(item.title))</text>
              <text x="24" y="64" class="card-desc">\(escapeXml(String(item.concept.prefix(70))))</text>
              <rect x="24" y="104" width="60" height="20" rx="10" fill="#292824" />
              <text x="54" y="118" class="tag" text-anchor="middle">\(escapeXml(item.platform))</text>
              <text x="100" y="118" class="tag">\(escapeXml(item.style))</text>
            </g>
        """
        }

        svg += "\n  </g>\n</svg>"
        return svg
    }

    static func exportPNG(
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky],
        connections: [CanvasConnection]
    ) -> NSImage? {
        let svgString = exportSVG(items: items, itemPositions: itemPositions, stickies: stickies, connections: connections)
        guard let data = svgString.data(using: .utf8) else { return nil }
        return NSImage(data: data)
    }

    static func exportPDF(
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky],
        connections: [CanvasConnection]
    ) -> Data? {
        guard let image = exportPNG(items: items, itemPositions: itemPositions, stickies: stickies, connections: connections) else { return nil }
        let pdfData = NSMutableData()
        var rect = CGRect(origin: .zero, size: image.size)
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &rect, nil) else { return nil }
        context.beginPDFPage(nil)
        if let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) {
            context.draw(cgImage, in: rect)
        }
        context.endPDFPage()
        context.closePDF()
        return pdfData as Data
    }

    static func saveWithPanel(data: Data, defaultFilename: String, fileExtension: String) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultFilename
        panel.allowedContentTypes = [
            fileExtension == "pdf" ? .pdf : (fileExtension == "svg" ? .svg : .png)
        ]

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    static func copyPNGToClipboard(
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky],
        connections: [CanvasConnection]
    ) {
        if let image = exportPNG(items: items, itemPositions: itemPositions, stickies: stickies, connections: connections) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }
    }

    private static func resolvePoints(
        conn: CanvasConnection,
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky]
    ) -> (CGPoint, CGPoint)? {
        guard let start = centerFor(id: conn.fromId, items: items, itemPositions: itemPositions, stickies: stickies),
              let end = centerFor(id: conn.toId, items: items, itemPositions: itemPositions, stickies: stickies) else {
            return nil
        }
        return (start, end)
    }

    private static func centerFor(
        id: String,
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky]
    ) -> CGPoint? {
        if id.hasPrefix("sticky-") {
            let raw = String(id.dropFirst("sticky-".count))
            guard let uuid = UUID(uuidString: raw),
                  let sticky = stickies.first(where: { $0.id == uuid }) else { return nil }
            return sticky.position
        } else if id.hasPrefix("item-") {
            let raw = String(id.dropFirst("item-".count))
            guard let uuid = UUID(uuidString: raw),
                  let item = items.first(where: { $0.uuid == uuid }) else { return nil }
            let index = items.firstIndex(where: { $0.uuid == item.uuid }) ?? 0
            let pos = itemPositions[item.uuid] ?? CGPoint(x: 160 + (index % 3) * 320, y: 160 + (index / 3) * 240)
            return pos
        }
        return nil
    }

    private static func escapeXml(_ str: String) -> String {
        str.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
