import SwiftUI
import KiteKit

struct SitemapRouterSheet: View {
    let onDismiss: () -> Void

    @State private var routes: [AppScreenRoute] = SitemapRouterBuilder.starterSitemap
    @State private var codeTab: CodeTarget = .nextJs
    @State private var isCopied: Bool = false

    enum CodeTarget: String, CaseIterable, Identifiable {
        case nextJs = "Next.js 15 Router"
        case swiftUI = "SwiftUI NavigationPath"

        var id: String { rawValue }
    }

    private var generatedCode: String {
        switch codeTab {
        case .nextJs:
            return SitemapRouterBuilder.generateNextJsAppRouter(routes: routes)
        case .swiftUI:
            return SitemapRouterBuilder.generateSwiftUIRouter(routes: routes)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Карта экранов и навигации (App Router)")
                        .font(.headline)
                    Text("Иерархия страниц, модальных окон и генерация типизированного роутера")
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

            // Main Content
            HSplitView {
                // Left Column: Screens List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Экраны приложения (\(routes.count)):")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            addScreen()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Экран")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(routes.enumerated()), id: \.element.id) { idx, screen in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        TextField("Путь", text: $routes[idx].path)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 140)

                                        TextField("Заголовок", text: $routes[idx].title)
                                            .textFieldStyle(.roundedBorder)

                                        Picker("", selection: $routes[idx].presentation) {
                                            ForEach(AppScreenRoute.ScreenPresentation.allCases, id: \.self) { p in
                                                Text(p.rawValue).tag(p)
                                            }
                                        }
                                        .frame(width: 128)

                                        Spacer()

                                        Button {
                                            routes.remove(at: idx)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption2)
                                                .foregroundStyle(Color.red)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    TextField("Описание экрана", text: $routes[idx].description)
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
                }
                .padding(16)
                .frame(minWidth: 440, idealWidth: 480)

                // Right Column: Generated Code
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("", selection: $codeTab) {
                            ForEach(CodeTarget.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 320)

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
                .frame(minWidth: 400, idealWidth: 460)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 860, idealWidth: 960, minHeight: 520, idealHeight: 640)
    }

    private func addScreen() {
        routes.append(
            AppScreenRoute(
                path: "/screen-\(routes.count + 1)",
                title: "Экран \(routes.count + 1)",
                presentation: .push,
                description: "Пользовательский сценарий"
            )
        )
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
