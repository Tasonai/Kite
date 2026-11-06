import SwiftUI
import KiteKit

struct APIContractSheet: View {
    let onDismiss: () -> Void

    @State private var routes: [APIRoute] = APIContractBuilder.starterPack
    @State private var selectedRouteId: UUID? = nil
    @State private var activeTab: CodeTab = .typeScript
    @State private var isMockActive: Bool = false
    @State private var isCopied: Bool = false

    enum CodeTab: String, CaseIterable, Identifiable {
        case typeScript = "TypeScript API"
        case openAPI = "OpenAPI 3.0"
        case swift = "Swift Client"

        var id: String { rawValue }
    }

    private var generatedCode: String {
        switch activeTab {
        case .typeScript:
            return APIContractBuilder.generateTypeScript(routes: routes)
        case .openAPI:
            return APIContractBuilder.generateOpenAPI(routes: routes)
        case .swift:
            return APIContractBuilder.generateSwiftClient(routes: routes)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("API-контракты и локальный Mock-сервер")
                        .font(.headline)
                    Text("Спецификация эндпоинтов и отдача реальных мок-данных на http://localhost:49495/api/...")
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

            // Main Editor
            HSplitView {
                // Left Column: Route List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Эндпоинты (\(routes.count)):")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            addRoute()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Маршрут")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(routes.enumerated()), id: \.element.id) { idx, route in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Text(route.method.rawValue)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(methodColor(route.method).opacity(0.16))
                                            .foregroundStyle(methodColor(route.method))
                                            .clipShape(Capsule())

                                        TextField("Путь", text: $routes[idx].path)
                                            .textFieldStyle(.roundedBorder)

                                        Button {
                                            routes.remove(at: idx)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption2)
                                                .foregroundStyle(Color.red)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    TextField("Описание", text: $routes[idx].summary)
                                        .textFieldStyle(.plain)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    // Mock Server Toggle
                    HStack(spacing: 8) {
                        Button {
                            toggleMockServer()
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(isMockActive ? Color.green : Color.secondary.opacity(0.4))
                                    .frame(width: 8, height: 8)
                                Image(systemName: isMockActive ? "stop.fill" : "play.fill")
                                Text(isMockActive ? "Остановить Mock-сервер" : "Запустить Mock-сервер (порт 49495)")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .frame(minWidth: 380, idealWidth: 420)

                // Right Column: Generated Code
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("", selection: $activeTab) {
                            ForEach(CodeTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 340)

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
                .frame(minWidth: 400, idealWidth: 480)
            }

            Divider()

            // Footer
            HStack {
                Text("Совет: фронтенд в Antigravity может слать реальные fetch-запросы на localhost:49495 без ожидания бэкенда.")
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
        .frame(minWidth: 840, idealWidth: 960, minHeight: 520, idealHeight: 640)
    }

    private func methodColor(_ method: APIRoute.HTTPMethod) -> Color {
        switch method {
        case .get: return .blue
        case .post: return .green
        case .put: return .orange
        case .delete: return .red
        }
    }

    private func addRoute() {
        routes.append(
            APIRoute(
                path: "/api/item/\(routes.count + 1)",
                method: .get,
                summary: "Новый эндпоинт",
                responseBodySample: "{\n  \"ok\": true\n}"
            )
        )
    }

    private func toggleMockServer() {
        if isMockActive {
            InstantPreviewServer.shared.stop()
            isMockActive = false
        } else {
            InstantPreviewServer.shared.start(html: "<h1>Kite Mock Server</h1>", routes: routes)
            isMockActive = true
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
