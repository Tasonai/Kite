import Foundation

public struct DomainEventConfig: Identifiable, Sendable, Equatable {
    public var id: String { eventName }
    public var eventName: String
    public var payloadSchema: String
    public var subscribers: [String]
    public var deliveryGuarantee: String
    public var retryPolicy: String

    public init(
        eventName: String,
        payloadSchema: String,
        subscribers: [String],
        deliveryGuarantee: String,
        retryPolicy: String
    ) {
        self.eventName = eventName
        self.payloadSchema = payloadSchema
        self.subscribers = subscribers
        self.deliveryGuarantee = deliveryGuarantee
        self.retryPolicy = retryPolicy
    }
}

public enum EventBusStudio {
    public static var starterEvents: [DomainEventConfig] {
        [
            DomainEventConfig(
                eventName: "user.registered",
                payloadSchema: "z.object({ userId: z.string(), email: z.string().email(), registeredAt: z.string() })",
                subscribers: ["WelcomeEmailWorker", "MixpanelAnalytics", "CrmSync"],
                deliveryGuarantee: "At-Least-Once",
                retryPolicy: "3 Retries + Dead Letter Queue"
            ),
            DomainEventConfig(
                eventName: "workspace.member_invited",
                payloadSchema: "z.object({ workspaceId: z.string(), inviterId: z.string(), inviteeEmail: z.string().email(), role: z.enum(['admin', 'member']) })",
                subscribers: ["InviteEmailDispatcher", "SecurityAuditLog"],
                deliveryGuarantee: "At-Least-Once",
                retryPolicy: "3 Retries + Exponential Backoff"
            ),
            DomainEventConfig(
                eventName: "canvas.node_updated",
                payloadSchema: "z.object({ canvasId: z.string(), nodeId: z.string(), delta: z.record(z.string(), z.unknown()), version: z.number() })",
                subscribers: ["RealtimeBroadcaster", "CanvasSnapshotWorker"],
                deliveryGuarantee: "At-Least-Once",
                retryPolicy: "2 Retries + Drop On Stale Version"
            ),
            DomainEventConfig(
                eventName: "billing.subscription_cancelled",
                payloadSchema: "z.object({ tenantId: z.string(), reason: z.string().optional(), effectiveDate: z.string() })",
                subscribers: ["StripeSyncWorker", "ChurnSurveyDispatcher", "AccessRevoker"],
                deliveryGuarantee: "At-Least-Once",
                retryPolicy: "5 Retries + Dead Letter Queue"
            )
        ]
    }

    public static func generateEventBusMarkdown(title: String, events: [DomainEventConfig]) -> String {
        var lines: [String] = [
            "# DISTRIBUTED EVENT BUS & DOMAIN EVENTS SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in generating typed domain events, asynchronous pub/sub channels, and dead-letter queues.",
            "NEVER tightly couple side-effects (emails, analytics, billing sync) inside primary HTTP request lifecycles.",
            ""
        ]

        for (idx, e) in events.enumerated() {
            lines.append("## \(idx + 1). Event `\(e.eventName)`")
            lines.append("- Payload Schema: `\(e.payloadSchema)`")
            lines.append("- Guarantee: \(e.deliveryGuarantee)")
            lines.append("- Retry & DLQ: \(e.retryPolicy)")
            lines.append("- Active Subscribers: \(e.subscribers.joined(separator: ", "))")
            lines.append("")
        }

        lines.append("## Architecture Guidelines")
        lines.append("1. All event emissions must be wrapped in atomic transaction outbox or background worker dispatch.")
        lines.append("2. Payloads must be schema-validated with Zod before serialization to Redis / SQS / Inngest.")
        lines.append("3. Consumers must be idempotent using `eventId` or `deduplicationKey`.")

        return lines.joined(separator: "\n")
    }

    public static func generateEventBusClientSnippet(events: [DomainEventConfig]) -> String {
        let lines: [String] = [
            "// lib/eventBus.ts",
            "// End-to-end typed domain event bus with Zod validation and safe dispatch",
            "import { z } from 'zod';",
            "",
            "export const EventSchemas = {",
            "  'user.registered': z.object({",
            "    userId: z.string(),",
            "    email: z.string().email(),",
            "    registeredAt: z.string(),",
            "  }),",
            "  'workspace.member_invited': z.object({",
            "    workspaceId: z.string(),",
            "    inviterId: z.string(),",
            "    inviteeEmail: z.string().email(),",
            "    role: z.enum(['admin', 'member']),",
            "  }),",
            "  'canvas.node_updated': z.object({",
            "    canvasId: z.string(),",
            "    nodeId: z.string(),",
            "    delta: z.record(z.string(), z.unknown()),",
            "    version: z.number(),",
            "  }),",
            "  'billing.subscription_cancelled': z.object({",
            "    tenantId: z.string(),",
            "    reason: z.string().optional(),",
            "    effectiveDate: z.string(),",
            "  }),",
            "} as const;",
            "",
            "export type EventMap = {",
            "  [K in keyof typeof EventSchemas]: z.infer<(typeof EventSchemas)[K]>;",
            "};",
            "",
            "export class DomainEventBus {",
            "  private static subscribers: Map<string, Array<(payload: any) => Promise<void>>> = new Map();",
            "",
            "  public static subscribe<K extends keyof EventMap>(",
            "    event: K,",
            "    handler: (payload: EventMap[K]) => Promise<void>",
            "  ): () => void {",
            "    const current = this.subscribers.get(event) || [];",
            "    current.push(handler);",
            "    this.subscribers.set(event, current);",
            "    return () => {",
            "      const updated = (this.subscribers.get(event) || []).filter(h => h !== handler);",
            "      this.subscribers.set(event, updated);",
            "    };",
            "  }",
            "",
            "  public static async publish<K extends keyof EventMap>(",
            "    event: K,",
            "    payload: EventMap[K]",
            "  ): Promise<void> {",
            "    const schema = EventSchemas[event];",
            "    const validated = schema.parse(payload);",
            "    const handlers = this.subscribers.get(event) || [];",
            "    await Promise.allSettled(handlers.map(h => h(validated)));",
            "  }",
            "}",
            ""
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(events: [DomainEventConfig]) -> String {
        var lines: [String] = [
            "### ANTIGRAVITY DISTRIBUTED DOMAIN EVENT BUS DIRECTIVE",
            "Decouple business side effects through typed domain events:",
            ""
        ]

        for e in events {
            lines.append("- Publish `\(e.eventName)` with schema `\(e.payloadSchema)`. Subscribers: \(e.subscribers.joined(separator: ", ")). Delivery: \(e.deliveryGuarantee).")
        }

        lines.append("")
        lines.append("Never run transactional emails or billing reconciliations inline in API handlers; emit events into the bus with idempotency keys.")

        return lines.joined(separator: "\n")
    }
}
