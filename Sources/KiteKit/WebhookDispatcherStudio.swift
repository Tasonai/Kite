import Foundation

public struct OutgoingWebhookConfig: Identifiable, Sendable, Equatable {
    public var id: String { targetSystem }
    public var targetSystem: String
    public var eventTriggers: [String]
    public var signingAlgorithm: String
    public var retrySchedule: String
    public var timeoutMs: Int

    public init(
        targetSystem: String,
        eventTriggers: [String],
        signingAlgorithm: String,
        retrySchedule: String,
        timeoutMs: Int
    ) {
        self.targetSystem = targetSystem
        self.eventTriggers = eventTriggers
        self.signingAlgorithm = signingAlgorithm
        self.retrySchedule = retrySchedule
        self.timeoutMs = timeoutMs
    }
}

public enum WebhookDispatcherStudio {
    public static var starterWebhooks: [OutgoingWebhookConfig] {
        [
            OutgoingWebhookConfig(
                targetSystem: "Customer Endpoint",
                eventTriggers: ["order.paid", "subscription.cancelled"],
                signingAlgorithm: "HMAC-SHA256 (X-Kite-Signature)",
                retrySchedule: "1m, 5m, 15m, 1h, 6h (Max 5 attempts)",
                timeoutMs: 5000
            ),
            OutgoingWebhookConfig(
                targetSystem: "Slack Alerts Channel",
                eventTriggers: ["incident.triggered", "threat.detected"],
                signingAlgorithm: "HMAC-SHA256 (X-Kite-Signature)",
                retrySchedule: "30s, 2m, 10m (Max 3 attempts)",
                timeoutMs: 3000
            ),
            OutgoingWebhookConfig(
                targetSystem: "Zapier / Make Automation",
                eventTriggers: ["user.registered", "lead.captured"],
                signingAlgorithm: "HMAC-SHA256 (X-Kite-Signature)",
                retrySchedule: "1m, 5m, 30m (Max 3 attempts)",
                timeoutMs: 5000
            ),
            OutgoingWebhookConfig(
                targetSystem: "Audit Vault",
                eventTriggers: ["security.role_changed", "data.exported"],
                signingAlgorithm: "HMAC-SHA256 (X-Kite-Signature)",
                retrySchedule: "1m, 5m, 15m, 1h, 6h, 24h (Max 6 attempts)",
                timeoutMs: 10000
            )
        ]
    }

    public static func generateDispatcherMarkdown(title: String, webhooks: [OutgoingWebhookConfig]) -> String {
        var lines: [String] = [
            "# OUTGOING WEBHOOK DISPATCHER SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in generating resilient outgoing webhook delivery workers.",
            "NEVER deliver outgoing webhooks without cryptographic signatures and exponential backoff retry guarantees.",
            ""
        ]

        for (idx, w) in webhooks.enumerated() {
            lines.append("## \(idx + 1). Target: `\(w.targetSystem)`")
            lines.append("- Subscribed Events: \(w.eventTriggers.joined(separator: ", "))")
            lines.append("- Security: \(w.signingAlgorithm)")
            lines.append("- Backoff: \(w.retrySchedule)")
            lines.append("- Timeout: \(w.timeoutMs) ms")
            lines.append("")
        }

        lines.append("## Webhook Security Directives")
        lines.append("1. Compute cryptographic signature over timestamp + body payload: `X-Kite-Signature = HMAC-SHA256(secret, t + '.' + body)`.")
        lines.append("2. Include `X-Kite-Delivery` UUID header for consumer idempotency tracking.")
        lines.append("3. Archive failed deliveries exceeding max attempts to dead-letter queue for manual replay.")

        return lines.joined(separator: "\n")
    }

    public static func generateWorkerSnippet(webhooks: [OutgoingWebhookConfig]) -> String {
        let lines: [String] = [
            "// workers/webhookDispatcher.ts",
            "// Outgoing webhook worker with HMAC-SHA256 signing and exponential retries",
            "import crypto from 'node:crypto';",
            "",
            "interface WebhookPayload {",
            "  id: string;",
            "  event: string;",
            "  timestamp: number;",
            "  data: Record<string, unknown>;",
            "}",
            "",
            "export async function dispatchWebhook(",
            "  endpointUrl: string,",
            "  secret: string,",
            "  payload: WebhookPayload",
            "): Promise<boolean> {",
            "  const body = JSON.stringify(payload);",
            "  const timestamp = Math.floor(Date.now() / 1000);",
            "  const signaturePayload = `${timestamp}.${body}`;",
            "  const signature = crypto",
            "    .createHmac('sha256', secret)",
            "    .update(signaturePayload)",
            "    .digest('hex');",
            "",
            "  const response = await fetch(endpointUrl, {",
            "    method: 'POST',",
            "    headers: {",
            "      'Content-Type': 'application/json',",
            "      'X-Kite-Delivery': payload.id,",
            "      'X-Kite-Timestamp': timestamp.toString(),",
            "      'X-Kite-Signature': `t=${timestamp},v1=${signature}`,",
            "    },",
            "    body,",
            "    signal: AbortSignal.timeout(5000),",
            "  });",
            "",
            "  if (!response.ok) {",
            "    throw new Error(`Webhook delivery failed with HTTP status ${response.status}`);",
            "  }",
            "",
            "  return true;",
            "}",
            ""
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(webhooks: [OutgoingWebhookConfig]) -> String {
        var lines: [String] = [
            "### ANTIGRAVITY OUTGOING WEBHOOK DISPATCHER DIRECTIVE",
            "Implement signed and resilient outgoing webhook delivery workers:",
            ""
        ]

        for w in webhooks {
            lines.append("- Dispatch \(w.eventTriggers.joined(separator: ", ")) to `\(w.targetSystem)` signed with \(w.signingAlgorithm). Retry: \(w.retrySchedule).")
        }

        lines.append("")
        lines.append("Stamp headers with timestamp, idempotency UUID, and HMAC-SHA256 signature to protect endpoints against replay attacks.")

        return lines.joined(separator: "\n")
    }
}
