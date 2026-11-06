import Foundation

public struct SecurityThreat: Identifiable, Sendable, Equatable {
    public var id: String { threatName }
    public var threatName: String
    public var category: String
    public var severity: String
    public var mitigationPattern: String
    public var codeSnippet: String

    public init(threatName: String, category: String, severity: String, mitigationPattern: String, codeSnippet: String) {
        self.threatName = threatName
        self.category = category
        self.severity = severity
        self.mitigationPattern = mitigationPattern
        self.codeSnippet = codeSnippet
    }
}

public enum ThreatModeler {
    public static var starterThreats: [SecurityThreat] {
        [
            SecurityThreat(
                threatName: "Insecure Direct Object Reference (IDOR)",
                category: "Authorization",
                severity: "Critical",
                mitigationPattern: "Всегда проверять владение ресурсом через WHERE userId = session.userId или RLS.",
                codeSnippet: """
                // Postgres RLS Policy
                CREATE POLICY user_isolation_policy ON items
                  FOR ALL
                  USING (auth.uid() = user_id);
                """
            ),
            SecurityThreat(
                threatName: "Unauthenticated Webhook Injection",
                category: "Authentication",
                severity: "Critical",
                mitigationPattern: "Обязательная проверка криптографической HMAC-подписи тела запроса перед обработкой.",
                codeSnippet: """
                const event = stripe.webhooks.constructEvent(
                  rawBody,
                  signatureHeader,
                  process.env.STRIPE_WEBHOOK_SECRET!
                );
                """
            ),
            SecurityThreat(
                threatName: "Server-Side Request Forgery (SSRF)",
                category: "Network",
                severity: "High",
                mitigationPattern: "Запрет исходящих запросов к приватным IP диапазонам (10.0.0.0/8, 192.168.0.0/16, 127.0.0.1, 169.254.169.254).",
                codeSnippet: """
                function assertPublicUrl(targetUrl: string): void {
                  const host = new URL(targetUrl).hostname;
                  if (host === 'localhost' || host.startsWith('127.') || host.startsWith('10.') || host.startsWith('192.168.')) {
                    throw new Error('Blocked SSRF attempt to internal network');
                  }
                }
                """
            ),
            SecurityThreat(
                threatName: "Brute Force & DoS on Auth Endpoints",
                category: "Rate Limiting",
                severity: "Medium",
                mitigationPattern: "Ограничение частоты запросов (максимум 5 попыток в минуту на IP для роутов авторизации).",
                codeSnippet: """
                import { Ratelimit } from '@upstash/ratelimit';
                const ratelimit = new Ratelimit({ limiter: Ratelimit.slidingWindow(5, '1 m') });
                const { success } = await ratelimit.limit(clientIp);
                if (!success) throw new Response('Too Many Requests', { status: 429 });
                """
            )
        ]
    }

    public static func generateSecurityMarkdown(title: String, threats: [SecurityThreat]) -> String {
        var lines: [String] = [
            "# SECURITY THREAT MODEL & OWASP GUARD: \(title.uppercased())",
            "This document establishes non-negotiable security controls for Google DeepMind Antigravity.",
            "All generated routes, database queries, and handlers MUST mitigate these threats.",
            ""
        ]

        for (idx, t) in threats.enumerated() {
            lines.append("## \(idx + 1). \(t.threatName) [\(t.severity.uppercased())]")
            lines.append("- Category: `\(t.category)`")
            lines.append("- Mitigation: \(t.mitigationPattern)")
            lines.append("- Required Code Pattern:")
            lines.append("```ts")
            lines.append(t.codeSnippet)
            lines.append("```")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(threats: [SecurityThreat]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY SECURITY & OWASP DIRECTIVE]",
            "Do NOT write insecure prototype code without access controls.",
            "You MUST enforce these security rules across all endpoints and queries:",
            ""
        ]

        for t in threats {
            lines.append("- [\(t.severity)] \(t.threatName) (\(t.category)): \(t.mitigationPattern)")
        }

        lines.append("")
        lines.append("Enforce session authorization, HMAC signature validation, rate limits, and SSRF firewalls.")
        return lines.joined(separator: "\n")
    }
}
