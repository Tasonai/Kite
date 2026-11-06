import Foundation

public struct APIRoute: Identifiable, Sendable, Codable, Equatable {
    public var id: UUID
    public var path: String
    public var method: HTTPMethod
    public var summary: String
    public var requestBodySample: String?
    public var responseBodySample: String

    public enum HTTPMethod: String, Sendable, CaseIterable, Codable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    public init(
        id: UUID = UUID(),
        path: String,
        method: HTTPMethod = .get,
        summary: String,
        requestBodySample: String? = nil,
        responseBodySample: String
    ) {
        self.id = id
        self.path = path
        self.method = method
        self.summary = summary
        self.requestBodySample = requestBodySample
        self.responseBodySample = responseBodySample
    }
}

public enum APIContractBuilder {
    public static var starterPack: [APIRoute] {
        [
            APIRoute(
                path: "/api/projects",
                method: .get,
                summary: "Список всех проектов пользователя",
                responseBodySample: """
                [
                  { "id": "proj_1", "title": "Kite Studio", "status": "active", "updatedAt": "2026-11-06T12:00:00Z" },
                  { "id": "proj_2", "title": "Habit Tracker", "status": "backlog", "updatedAt": "2026-11-05T09:30:00Z" }
                ]
                """
            ),
            APIRoute(
                path: "/api/projects",
                method: .post,
                summary: "Создание нового проекта",
                requestBodySample: """
                { "title": "Новый проект", "platform": "Web" }
                """,
                responseBodySample: """
                { "id": "proj_new", "title": "Новый проект", "status": "active", "createdAt": "2026-11-06T18:00:00Z" }
                """
            ),
            APIRoute(
                path: "/api/user/profile",
                method: .get,
                summary: "Профиль текущего пользователя",
                responseBodySample: """
                { "id": "usr_42", "email": "founder@example.com", "name": "Vibe Coder", "plan": "pro" }
                """
            )
        ]
    }

    public static func generateTypeScript(routes: [APIRoute]) -> String {
        var lines: [String] = [
            "// Auto-generated TypeScript API Client from Kite",
            "// Base URL: http://localhost:49495 (Local Kite Mock Server)",
            ""
        ]

        for route in routes {
            let funcName = routeFunctionName(method: route.method, path: route.path)
            lines.append("/** \(route.summary) */")
            if route.method == .get {
                lines.append("export async function \(funcName)(): Promise<unknown> {")
                lines.append("  const res = await fetch('\(route.path)');")
                lines.append("  if (!res.ok) throw new Error(`API Error: ${res.status}`);")
                lines.append("  return res.json();")
                lines.append("}\n")
            } else {
                lines.append("export async function \(funcName)(body: unknown): Promise<unknown> {")
                lines.append("  const res = await fetch('\(route.path)', {")
                lines.append("    method: '\(route.method.rawValue)',")
                lines.append("    headers: { 'Content-Type': 'application/json' },")
                lines.append("    body: JSON.stringify(body)")
                lines.append("  });")
                lines.append("  if (!res.ok) throw new Error(`API Error: ${res.status}`);")
                lines.append("  return res.json();")
                lines.append("}\n")
            }
        }
        return lines.joined(separator: "\n")
    }

    public static func generateOpenAPI(routes: [APIRoute]) -> String {
        var lines: [String] = [
            "openapi: 3.0.0",
            "info:",
            "  title: Antigravity Project API",
            "  version: 1.0.0",
            "paths:"
        ]

        let grouped = Dictionary(grouping: routes, by: { $0.path })
        for (path, rList) in grouped {
            lines.append("  \(path):")
            for route in rList {
                lines.append("    \(route.method.rawValue.lowercased()):")
                lines.append("      summary: \"\(route.summary)\"")
                lines.append("      responses:")
                lines.append("        '200':")
                lines.append("          description: Successful response")
                lines.append("          content:")
                lines.append("            application/json:")
                lines.append("              schema:")
                lines.append("                type: object")
            }
        }
        return lines.joined(separator: "\n")
    }

    public static func generateSwiftClient(routes: [APIRoute]) -> String {
        var lines: [String] = [
            "import Foundation",
            "",
            "public enum APIClient {",
            "    public static let baseURL = URL(string: \"http://localhost:49495\")!",
            ""
        ]

        for route in routes {
            let funcName = routeFunctionName(method: route.method, path: route.path)
            lines.append("    /// \(route.summary)")
            lines.append("    public static func \(funcName)() async throws -> Data {")
            lines.append("        let url = baseURL.appendingPathComponent(\"\(route.path.replacingOccurrences(of: "^/", with: "", options: .regularExpression))\")")
            lines.append("        var req = URLRequest(url: url)")
            lines.append("        req.httpMethod = \"\(route.method.rawValue)\"")
            lines.append("        let (data, res) = try await URLSession.shared.data(for: req)")
            lines.append("        guard (res as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }")
            lines.append("        return data")
            lines.append("    }\n")
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public static func findMockResponse(for path: String, method: String, in routes: [APIRoute]) -> (status: Int, json: String)? {
        let cleanPath = path.components(separatedBy: "?").first ?? path
        if let match = routes.first(where: { $0.path == cleanPath && $0.method.rawValue.uppercased() == method.uppercased() }) {
            return (200, match.responseBodySample)
        }
        return nil
    }

    private static func routeFunctionName(method: APIRoute.HTTPMethod, path: String) -> String {
        let parts = path.components(separatedBy: "/")
            .filter { !$0.isEmpty && $0 != "api" }
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
        let verb = method.rawValue.lowercased()
        let name = parts.isEmpty ? "Root" : parts
        return "\(verb)\(name)"
    }
}
