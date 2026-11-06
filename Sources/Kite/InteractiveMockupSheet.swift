import AppKit
import SwiftUI
import WebKit
import KiteKit

struct InteractiveMockupSheet: View {
    let title: String
    let concept: String
    let platform: String
    let style: String
    let onDismiss: () -> Void

    @State private var previewHTML: String = ""
    @State private var showQRSharePopover: Bool = false
    @ObservedObject private var previewServer = InstantPreviewServer.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 8) {
                Image(systemName: "safari")
                    .foregroundStyle(Color.accentColor)

                Text(title.isEmpty ? "Интерактивный черновик" : title)
                    .font(.headline)

                Text(platform)
                    .font(.system(size: 10, design: .monospaced)) // grid: ok font
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())

                Text(style)
                    .font(.system(size: 10)) // grid: ok font
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    previewServer.start(html: previewHTML)
                    showQRSharePopover = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "qrcode")
                        Text("На телефон")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .popover(isPresented: $showQRSharePopover) {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "iphone.gen3")
                                .foregroundStyle(Color.accentColor)
                            Text("Просмотр на смартфоне")
                                .font(.headline)
                        }

                        if let qr = previewServer.qrCodeImage {
                            Image(nsImage: qr)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ProgressView()
                                .frame(width: 160, height: 160)
                        }

                        VStack(spacing: 4) {
                            Text("Наведите камеру iPhone в одной сети Wi-Fi:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(previewServer.localURLString)
                                .font(.caption.monospaced().bold())
                                .textSelection(.enabled)
                        }

                        Button("Скопировать ссылку") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(previewServer.localURLString, forType: .string)
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                    .padding(16)
                    .frame(width: 240)
                }

                Button {
                    openInExternalBrowser()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                        Text("В браузере")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)

                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Web View Container
            MockupWebView(html: previewHTML)
                .frame(minWidth: 800, minHeight: 560)
        }
        .frame(width: 860, height: 620)
        .onAppear {
            previewHTML = WebMockupGenerator.generateInteractiveHTML(
                title: title,
                concept: concept,
                platform: platform,
                style: style
            )
        }
    }

    private func openInExternalBrowser() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("kite-mockup-\(UUID().uuidString.prefix(8)).html")
        try? previewHTML.write(to: tempURL, atomically: true, encoding: .utf8)
        NSWorkspace.shared.open(tempURL)
    }
}

private struct MockupWebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(html, baseURL: nil)
    }
}
