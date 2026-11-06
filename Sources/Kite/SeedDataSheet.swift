import SwiftUI
import KiteKit

struct SeedDataSheet: View {
    let onDismiss: () -> Void

    @State private var recordCount: Int = 3
    @State private var activeTab: CodeTarget = .sql
    @State private var isCopied: Bool = false
    @State private var isLoadedToMock: Bool = false

    enum CodeTarget: String, CaseIterable, Identifiable {
        case sql = "SQL (seed.sql)"
        case ts = "TypeScript (Prisma/Drizzle)"
        case json = "JSON Фикстуры"

        var id: String { rawValue }
    }

    private var entities: [SchemaEntity] {
        DataSchemaDesigner.starterPack
    }

    private var generatedCode: String {
        switch activeTab {
        case .sql:
            return SeedDataGenerator.generateSQL(entities: entities, count: recordCount)
        case .ts:
            return SeedDataGenerator.generateTypeScript(entities: entities, count: recordCount)
        case .json:
            return SeedDataGenerator.generateJSON(entities: entities, count: recordCount)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "tray.full.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Генератор тестовых данных (Seed Generator)")
                        .font(.headline)
                    Text("Генерация реалистичных связанных записей для базы данных и Mock-сервера")
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

            // Controls & Preview
            HSplitView {
                // Left: Entities & Controls
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Количество записей на таблицу: \(recordCount)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Picker("", selection: $recordCount) {
                            Text("3 записи").tag(3)
                            Text("5 записей").tag(5)
                            Text("10 записей").tag(10)
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    Text("Целевые таблицы схемы:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        ForEach(entities) { ent in
                            HStack(spacing: 8) {
                                Image(systemName: "tablecells")
                                    .foregroundStyle(Color.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ent.name)
                                        .font(.subheadline.bold())
                                    Text(ent.fields.map(\.name).joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    Spacer()

                    Button {
                        loadIntoMockServer()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isLoadedToMock ? "checkmark" : "network")
                            Text(isLoadedToMock ? "Загружено в Mock-сервер" : "Скормить в локальный Mock-сервер")
                        }
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
                .frame(minWidth: 320, idealWidth: 360)

                // Right: Generated Code Preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("", selection: $activeTab) {
                            ForEach(CodeTarget.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 360)

                        Spacer()

                        Button {
                            copyCode()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано" : "Копировать код")
                            }
                            .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                    }

                    ScrollView {
                        Text(generatedCode)
                            .font(.system(.body, design: .monospaced)) // grid: ok font
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(16)
                .frame(minWidth: 440, idealWidth: 520)
            }

            Divider()

            // Footer
            HStack {
                Text("Совет: выполните команду запуска сидов в терминале Antigravity для наполнения локальной SQLite / Postgres базы.")
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
        .frame(minWidth: 840, idealWidth: 940, minHeight: 520, idealHeight: 640)
    }

    private func loadIntoMockServer() {
        let json = SeedDataGenerator.generateJSON(entities: entities, count: recordCount)
        let routes = [
            APIRoute(path: "/api/projects", method: .get, summary: "Список проектов (Seed)", responseBodySample: json),
            APIRoute(path: "/api/users", method: .get, summary: "Список пользователей (Seed)", responseBodySample: json)
        ]
        InstantPreviewServer.shared.start(html: "<h1>Kite Mock Server with Seed Data</h1>", routes: routes)
        isLoadedToMock = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isLoadedToMock = false
        }
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedCode, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
