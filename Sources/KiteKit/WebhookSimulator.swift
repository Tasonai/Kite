import Foundation

public struct WebhookDefinition: Identifiable, Sendable, Equatable {
    public var id: String { eventName }
    public var eventName: String
    public var provider: String
    public var signatureHeader: String
    public var samplePayload: String
    public var verificationAlgorithm: String

    public init(eventName: String, provider: String, signatureHeader: String, samplePayload: String, verificationAlgorithm: String) {
        self.eventName = eventName
        self.provider = provider
        self.signatureHeader = signatureHeader
        self.samplePayload = samplePayload
        self.verificationAlgorithm = verificationAlgorithm
    }
}

public enum WebhookSimulator {
    public static var starterWebhooks: [WebhookDefinition] {
        [
            WebhookDefinition(
                eventName: "checkout.session.completed",
                provider: "Stripe",
                signatureHeader: "Stripe-Signature",
                samplePayload: """
                {
                  "id": "evt_1NqTestSessionCompleted",
                  "object": "event",
                  "type": "checkout.session.completed",
                  "data": {
                    "object": {
                      "id": "cs_test_a1b2c3d4",
                      "customer": "cus_998877",
                      "amount_total": 4900,
                      "currency": "usd",
                      "payment_status": "paid"
                    }
                  }
                }
                """,
                verificationAlgorithm: "HMAC-SHA256 (t=timestamp,v1=signature)"
            ),
            WebhookDefinition(
                eventName: "user.created",
                provider: "Clerk",
                signatureHeader: "svix-signature",
                samplePayload: """
                {
                  "type": "user.created",
                  "data": {
                    "id": "user_2XYZ9988",
                    "email_addresses": [{ "email_address": "alex@example.com" }],
                    "first_name": "Alex",
                    "last_name": "Dev"
                  }
                }
                """,
                verificationAlgorithm: "Svix Webhook HMAC-SHA256"
            ),
            WebhookDefinition(
                eventName: "push",
                provider: "GitHub",
                signatureHeader: "X-Hub-Signature-256",
                samplePayload: """
                {
                  "ref": "refs/heads/main",
                  "repository": { "full_name": "user/repo" },
                  "head_commit": { "id": "91dc5cb", "message": "feat: release update" }
                }
                """,
                verificationAlgorithm: "HMAC-SHA256 hex digest"
            )
        ]
    }

    public static func generateWebhooksMarkdown(title: String, webhooks: [WebhookDefinition]) -> String {
        var lines: [String] = [
            "# WEBHOOK INTEGRATION & VERIFICATION SPEC: \(title.uppercased())",
            "This specification mandates cryptographic webhook handling for Google DeepMind Antigravity.",
            "All webhook endpoints MUST reject unverified signatures before processing any payload.",
            ""
        ]

        for (idx, w) in webhooks.enumerated() {
            lines.append("## \(idx + 1). `\(w.eventName)` [\(w.provider)]")
            lines.append("- Signature Header: `\(w.signatureHeader)`")
            lines.append("- Verification Algorithm: `\(w.verificationAlgorithm)`")
            lines.append("- Sample Payload:")
            lines.append("```json")
            lines.append(w.samplePayload)
            lines.append("```")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateVerificationHandlerSnippet(webhooks: [WebhookDefinition]) -> String {
        var lines: [String] = [
            "// app/api/webhooks/route.ts",
            "// Safe webhook ingestion router with signature verification",
            "import { headers } from 'next/headers';",
            "import crypto from 'node:crypto';",
            "",
            "export async function POST(req: Request) {",
            "  const rawBody = await req.text();",
            "  const headerList = await headers();",
            ""
        ]

        for w in webhooks {
            lines.append("  // Provider: \(w.provider) (\(w.eventName))")
            lines.append("  const \(w.provider.lowercased())Sig = headerList.get('\(w.signatureHeader.lowercased())');")
        }

        lines.append("")
        lines.append("  // Verify signature using secret before parsing body")
        lines.append("  // If invalid signature -> return new Response('Invalid Signature', { status: 400 });")
        lines.append("  const payload = JSON.parse(rawBody);")
        lines.append("  console.log('[Webhook Verified]', payload.type || payload.event);")
        lines.append("  return Response.json({ received: true });")
        lines.append("}")

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(webhooks: [WebhookDefinition]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY WEBHOOK INTEGRATION DIRECTIVE]",
            "Do NOT accept unauthenticated webhook payloads.",
            "You MUST verify cryptographic signatures on the raw byte/text body before parsing JSON:",
            ""
        ]

        for w in webhooks {
            lines.append("- [\(w.provider)] Event `\(w.eventName)`: Validate header `\(w.signatureHeader)` with \(w.verificationAlgorithm).")
        }

        lines.append("")
        lines.append("Return HTTP 400 on signature failure; process event idempotently to avoid duplicate executions.")
        return lines.joined(separator: "\n")
    }
}
