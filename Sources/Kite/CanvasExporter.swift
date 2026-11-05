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
        connections: [CanvasConnection],
        frames: [CanvasFrame] = [],
        referenceCards: [CanvasReferenceCard] = []
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
            minX = min(minX, sticky.position.x - 100)
            minY = min(minY, sticky.position.y - 80)
            maxX = max(maxX, sticky.position.x + 100)
            maxY = max(maxY, sticky.position.y + 80)
        }

        for ref in referenceCards {
            minX = min(minX, ref.position.x - 120)
            minY = min(minY, ref.position.y - 90)
            maxX = max(maxX, ref.position.x + 120)
            maxY = max(maxY, ref.position.y + 90)
        }

        for frame in frames {
            minX = min(minX, frame.x)
            minY = min(minY, frame.y)
            maxX = max(maxX, frame.x + frame.width)
            maxY = max(maxY, frame.y + frame.height)
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
            .frame-title { font-weight: 700; font-size: 12px; fill: #FAF9F5; }
          </style>

          <!-- Canvas Background -->
          <rect x="\(Int(originX))" y="\(Int(originY))" width="\(Int(totalW))" height="\(Int(totalH))" fill="#141413" />

          <!-- Canvas Frames (Sections) -->
          <g id="frames">
        """

        for frame in frames {
            let fx = Int(frame.x)
            let fy = Int(frame.y)
            let fw = Int(frame.width)
            let fh = Int(frame.height)
            svg += """

            <rect x="\(fx)" y="\(fy)" width="\(fw)" height="\(fh)" rx="16" fill="\(frame.colorHex)" fill-opacity="0.06" stroke="\(frame.colorHex)" stroke-width="1.5" stroke-dasharray="6,4" />
            <rect x="\(fx)" y="\(fy)" width="\(min(fw, 240))" height="28" rx="8" fill="\(frame.colorHex)" />
            <text x="\(fx + 12)" y="\(fy + 18)" class="frame-title">\(escapeXml(frame.title))</text>
        """
        }

        svg += "\n  </g>\n\n  <!-- Connection Lines -->\n  <g id=\"connections\">"

        for conn in connections {
            if let (start, end) = resolvePoints(conn: conn, items: items, itemPositions: itemPositions, stickies: stickies, refCards: referenceCards) {
                let dx = end.x - start.x
                let c1x = start.x + dx * 0.5
                let c2x = end.x - dx * 0.5
                svg += """

            <path d="M \(Int(start.x)) \(Int(start.y)) C \(Int(c1x)) \(Int(start.y)), \(Int(c2x)) \(Int(end.y)), \(Int(end.x)) \(Int(end.y))" stroke="\(conn.colorHex)" stroke-width="2.5" fill="none" stroke-dasharray="6,4" marker-end="url(#arrow)" />
        """
                if !conn.label.isEmpty {
                    let midX = (start.x + end.x) / 2
                    let midY = (start.y + end.y) / 2
                    svg += """

            <rect x="\(Int(midX - 40))" y="\(Int(midY - 12))" width="80" height="24" rx="12" fill="#232321" stroke="\(conn.colorHex)" stroke-width="1" />
            <text x="\(Int(midX))" y="\(Int(midY + 4))" font-size="11" font-weight="600" fill="#FAF9F5" text-anchor="middle">\(escapeXml(conn.label))</text>
        """
                }
            }
        }

        svg += "\n  </g>\n\n  <!-- Reference Cards (Mobbin / Figma) -->\n  <g id=\"references\">"

        for ref in referenceCards {
            let rx = Int(ref.position.x - 120)
            let ry = Int(ref.position.y - 80)
            svg += """

            <g transform="translate(\(rx), \(ry))" filter="url(#shadow)">
              <rect width="240" height="160" rx="12" fill="#1C1B18" stroke="#33322E" stroke-width="1" />
              <rect x="12" y="12" width="64" height="18" rx="9" fill="\(ref.colorHex)" fill-opacity="0.2" />
              <text x="44" y="24" font-size="9" font-weight="bold" fill="\(ref.colorHex)" text-anchor="middle">\(escapeXml(ref.source))</text>
              <text x="12" y="52" class="card-title" font-size="13">\(escapeXml(ref.title))</text>
              <text x="12" y="78" class="card-desc">\(escapeXml(String(ref.description.prefix(60))))</text>
              <rect x="12" y="124" width="216" height="24" rx="6" fill="#292824" />
              <text x="120" y="140" class="tag" text-anchor="middle">\(escapeXml(ref.tags.joined(separator: " • ")))</text>
            </g>
        """
        }

        svg += "\n  </g>\n\n  <!-- Stickies -->\n  <g id=\"stickies\">"

        for sticky in stickies {
            let sx = Int(sticky.position.x - 100)
            let sy = Int(sticky.position.y - 80)
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
        connections: [CanvasConnection],
        frames: [CanvasFrame] = [],
        referenceCards: [CanvasReferenceCard] = []
    ) -> NSImage? {
        let svgString = exportSVG(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        )
        guard let data = svgString.data(using: .utf8) else { return nil }
        return NSImage(data: data)
    }

    static func exportPDF(
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky],
        connections: [CanvasConnection],
        frames: [CanvasFrame] = [],
        referenceCards: [CanvasReferenceCard] = []
    ) -> Data? {
        guard let image = exportPNG(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        ) else { return nil }
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
        connections: [CanvasConnection],
        frames: [CanvasFrame] = [],
        referenceCards: [CanvasReferenceCard] = []
    ) {
        if let image = exportPNG(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        ) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }
    }

    private static func resolvePoints(
        conn: CanvasConnection,
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky],
        refCards: [CanvasReferenceCard]
    ) -> (CGPoint, CGPoint)? {
        guard let start = centerFor(id: conn.fromId, items: items, itemPositions: itemPositions, stickies: stickies, refCards: refCards),
              let end = centerFor(id: conn.toId, items: items, itemPositions: itemPositions, stickies: stickies, refCards: refCards) else {
            return nil
        }
        return (start, end)
    }

    private static func centerFor(
        id: String,
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky],
        refCards: [CanvasReferenceCard]
    ) -> CGPoint? {
        if id.hasPrefix("sticky-") {
            let raw = String(id.dropFirst("sticky-".count))
            guard let uuid = UUID(uuidString: raw),
                  let sticky = stickies.first(where: { $0.id == uuid }) else { return nil }
            return sticky.position
        } else if id.hasPrefix("ref-") {
            let raw = String(id.dropFirst("ref-".count))
            guard let uuid = UUID(uuidString: raw),
                  let ref = refCards.first(where: { $0.id == uuid }) else { return nil }
            return ref.position
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

    static func exportHTML(
        items: [Item],
        itemPositions: [UUID: CGPoint],
        stickies: [CanvasSticky],
        connections: [CanvasConnection],
        frames: [CanvasFrame] = [],
        referenceCards: [CanvasReferenceCard] = []
    ) -> String {
        let svg = exportSVG(
            items: items,
            itemPositions: itemPositions,
            stickies: stickies,
            connections: connections,
            frames: frames,
            referenceCards: referenceCards
        )

        return """
        <!DOCTYPE html>
        <html lang="ru">
        <head>
          <meta charset="utf-8">
          <title>Kite Infinite Canvas</title>
          <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { background: #141413; color: #FAF9F5; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; overflow: hidden; height: 100vh; width: 100vw; }
            #toolbar { position: fixed; top: 16px; left: 16px; z-index: 100; display: flex; gap: 8px; background: rgba(28,27,24,0.85); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.1); border-radius: 8px; padding: 8px 12px; }
            #search { background: #292824; border: 1px solid #3D3B35; color: #FAF9F5; padding: 6px 12px; border-radius: 6px; font-size: 13px; outline: none; }
            button { background: #292824; border: 1px solid #3D3B35; color: #FAF9F5; padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 13px; }
            button:hover { background: #383631; }
            #viewport { width: 100vw; height: 100vh; cursor: grab; }
            #viewport:active { cursor: grabbing; }
            .highlight { stroke: #D97757 !important; stroke-width: 3px !important; }
          </style>
        </head>
        <body>
          <div id="toolbar">
            <input type="text" id="search" placeholder="Поиск карточек..." oninput="onSearch(this.value)">
            <button onclick="resetZoom()">Сброс масштаба</button>
          </div>
          <div id="viewport">
            \(svg)
          </div>
          <script>
            let scale = 1, panX = 0, panY = 0, isPanning = false, startX = 0, startY = 0;
            const vp = document.getElementById('viewport');
            const svg = vp.querySelector('svg');
            
            vp.addEventListener('wheel', e => {
              e.preventDefault();
              const delta = e.deltaY < 0 ? 1.1 : 0.9;
              scale = Math.min(Math.max(0.2, scale * delta), 4);
              updateTransform();
            }, { passive: false });

            vp.addEventListener('mousedown', e => {
              if (e.target.tagName === 'INPUT' || e.target.tagName === 'BUTTON') return;
              isPanning = true;
              startX = e.clientX - panX;
              startY = e.clientY - panY;
            });

            window.addEventListener('mousemove', e => {
              if (!isPanning) return;
              panX = e.clientX - startX;
              panY = e.clientY - startY;
              updateTransform();
            });

            window.addEventListener('mouseup', () => { isPanning = false; });

            function updateTransform() {
              svg.style.transformOrigin = '0 0';
              svg.style.transform = `translate(${panX}px, ${panY}px) scale(${scale})`;
            }

            function resetZoom() {
              scale = 1; panX = 0; panY = 0;
              updateTransform();
            }

            function onSearch(query) {
              const q = query.toLowerCase().trim();
              document.querySelectorAll('#ideas g, #stickies g').forEach(node => {
                const text = node.textContent.toLowerCase();
                const rect = node.querySelector('rect');
                if (rect) {
                  if (q && text.includes(q)) {
                    rect.classList.add('highlight');
                  } else {
                    rect.classList.remove('highlight');
                  }
                }
              });
            }
          </script>
        </body>
        </html>
        """
    }

    static func exportMermaid(items: [Item], connections: [CanvasConnection]) -> String {
        var out = "flowchart TD\n"
        for item in items {
            let safeTitle = item.title.replacingOccurrences(of: "\"", with: "'")
            let safeId = "node_" + item.uuid.uuidString.replacingOccurrences(of: "-", with: "_")
            out += "    \(safeId)[\"\(safeTitle)\"]\n"
        }
        for conn in connections {
            let fromId = conn.fromId.replacingOccurrences(of: "item-", with: "node_").replacingOccurrences(of: "-", with: "_")
            let toId = conn.toId.replacingOccurrences(of: "item-", with: "node_").replacingOccurrences(of: "-", with: "_")
            out += "    \(fromId) --> \(toId)\n"
        }
        return out
    }

    private static func escapeXml(_ str: String) -> String {
        str.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
