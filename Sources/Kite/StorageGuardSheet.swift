import SwiftUI
import KiteKit

struct StorageGuardSheet: View {
    var title: String = "Kite App"
    let onDismiss: () -> Void

    @State private var activeTab: OutputMode = .markdown
    @State private var isCopied: Bool = false

    enum OutputMode: String, CaseIterable, Identifiable {
        case markdown = "Манифест (STORAGE_SECURITY.md)"
        case route = "Хендлер (presigned-url.ts)"
        case prompt = "Промпт для Antigravity"

        var id: String { rawValue }
    }

    private var policies: [StoragePolicyConfig] {
        StorageGuard.starterPolicies
    }

    private var currentText: String {
        switch activeTab {
        case .markdown:
            return StorageGuard.generateStorageMarkdown(title: title, policies: policies)
        case .route:
            return StorageGuard.generatePresignedUploadSnippet(policy: policies[0])
        case .prompt:
            return StorageGuard.generatePromptDirective(policies: policies)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "externaldrive.badge.shield")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Страж облачных хранилищ (Storage Guard)")
                        .font(.headline)
                    Text("Политики безопасной загрузки (S3/R2/Supabase), Presigned URLs и валидация MIME-типов")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Закрыть", action: onDismiss)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            HSplitView {
                // Left: Storage Policies List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Бакеты и хранилища (\(policies.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(policies) { p in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(p.bucketName)
                                            .font(.caption.bold().monospaced())
                                        Spacer()
                                        Text(p.storageProvider)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    Text("Лимит: \(p.maxSizeBytes / (1024 * 1024)) MB • TTL: \(p.presignedUrlTtlSeconds)s")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text("MIME: \(p.allowedMimeTypes.joined(separator: ", "))")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.primary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 280, idealWidth: 300)

                // Right: Generated Spec
                VStack(spacing: 12) {
                    HStack {
                        Picker("", selection: $activeTab) {
                            ForEach(OutputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(currentText, forType: .string)
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                isCopied = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано!" : "Копировать")
                            }
                            .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isCopied ? .green : .accentColor)
                    }

                    ScrollView {
                        Text(currentText)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 740, idealWidth: 800, minHeight: 520, idealHeight: 560)
    }
}
