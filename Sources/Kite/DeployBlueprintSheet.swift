import SwiftUI
import KiteKit

struct DeployBlueprintSheet: View {
    var title: String = "Kite App"
    var platform: String = "Web"
    let onDismiss: () -> Void

    @State private var activeTab: DeployTarget = .vercel
    @State private var isCopied: Bool = false

    enum DeployTarget: String, CaseIterable, Identifiable {
        case vercel = "Vercel (vercel.json)"
        case cloudflare = "Cloudflare (wrangler.toml)"
        case docker = "Docker (Dockerfile)"
        case github = "GitHub Actions (CI/CD)"

        var id: String { rawValue }
    }

    private var currentConfig: String {
        switch activeTab {
        case .vercel:
            return DeployBlueprintGenerator.generateVercelConfig(title: title, platform: platform)
        case .cloudflare:
            return DeployBlueprintGenerator.generateCloudflarePages(title: title)
        case .docker:
            return DeployBlueprintGenerator.generateDockerfile(platform: platform)
        case .github:
            return DeployBlueprintGenerator.generateGitHubWorkflow(title: title)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "cloud.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Генератор деплоя (Deploy Blueprint)")
                        .font(.headline)
                    Text("Готовые конфигурации для публикации в Vercel, Cloudflare, Docker и GitHub Actions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Target Selector & Copy Bar
            HStack(spacing: 12) {
                Picker("", selection: $activeTab) {
                    ForEach(DeployTarget.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 480)

                Spacer()

                Button {
                    copyConfig()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Скопировано" : "Скопировать конфиг")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // File Content Viewer
            ScrollView {
                Text(currentConfig)
                    .font(.system(.body, design: .monospaced)) // grid: ok font
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))

            Divider()

            // Footer
            HStack {
                Text("Совет: положите файл в корень проекта для автоматического подхвата Vercel CLI или GitHub Actions.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 840, idealWidth: 920, minHeight: 520, idealHeight: 640)
    }

    private func copyConfig() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentConfig, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
