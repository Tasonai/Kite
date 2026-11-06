import Foundation

public struct SecretFinding: Identifiable, Sendable, Equatable {
    public var id: String
    public var kind: SecretKind
    public var preview: String

    public enum SecretKind: String, Sendable, CaseIterable {
        case openAI = "OpenAI API Key (sk-...)"
        case anthropic = "Anthropic API Key (sk-ant-...)"
        case gemini = "Google Gemini API Key (AIzaSy...)"
        case github = "GitHub Personal Access Token (ghp_...)"
        case stripe = "Stripe Secret Key (sk_live/test_...)"
        case aws = "AWS Access Key (AKIA...)"
        case jwt = "JWT Bearer Token (eyJ...)"
    }

    public init(id: String = UUID().uuidString, kind: SecretKind, preview: String) {
        self.id = id
        self.kind = kind
        self.preview = preview
    }
}

public enum SecretShield {
    private static let patterns: [(SecretFinding.SecretKind, String, String)] = [
        (.openAI, "sk-[a-zA-Z0-9_\\-]{24,}", "process.env.OPENAI_API_KEY"),
        (.anthropic, "sk-ant-[a-zA-Z0-9_\\-]{24,}", "process.env.ANTHROPIC_API_KEY"),
        (.gemini, "AIzaSy[a-zA-Z0-9_\\-]{30,}", "process.env.GEMINI_API_KEY"),
        (.github, "ghp_[a-zA-Z0-9]{30,}", "process.env.GITHUB_TOKEN"),
        (.stripe, "sk_(live|test)_[a-zA-Z0-9]{20,}", "process.env.STRIPE_SECRET_KEY"),
        (.aws, "AKIA[0-9A-Z]{16}", "process.env.AWS_ACCESS_KEY_ID"),
        (.jwt, "eyJ[a-zA-Z0-9_\\-]+\\.[a-zA-Z0-9_\\-]+\\.[a-zA-Z0-9_\\-]+", "process.env.AUTH_TOKEN")
    ]

    public static func scan(text: String) -> [SecretFinding] {
        var findings: [SecretFinding] = []

        for (kind, pattern, _) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let matched = String(text[range])
                        let masked = matched.prefix(6) + "..." + matched.suffix(4)
                        findings.append(SecretFinding(kind: kind, preview: String(masked)))
                    }
                }
            }
        }

        return findings
    }

    public static func sanitize(text: String) -> String {
        var result = text

        for (_, pattern, replacement) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: NSRange(location: 0, length: result.utf16.count),
                    withTemplate: replacement
                )
            }
        }

        return result
    }

    public static func generateEnvExample(title: String) -> String {
        """
        # .env.example — Environment Variables for \(title)
        # ВНИМАНИЕ: Никогда не коммитьте реальные ключи в репозиторий!

        # 1. Серверные API Ключи
        GEMINI_API_KEY="AIzaSy_YOUR_KEY_HERE"
        # OPENAI_API_KEY="sk_YOUR_KEY_HERE"

        # 2. База данных
        DATABASE_URL="file:./dev.db"

        # 3. Аутентификация и сессии
        AUTH_SECRET="generate_random_secret_32_chars"
        NEXTAUTH_URL="http://localhost:3000"

        # 4. Локальный Mock-сервер Kite
        KITE_MOCK_SERVER_URL="http://localhost:49495"
        """
    }
}
