import Foundation

public struct RealtimeStreamEvent: Identifiable, Sendable, Equatable {
    public var id: String { eventType }
    public var eventType: String
    public var protocolType: String
    public var direction: String
    public var payloadContract: String
    public var isHeartbeatEnabled: Bool

    public init(eventType: String, protocolType: String, direction: String, payloadContract: String, isHeartbeatEnabled: Bool) {
        self.eventType = eventType
        self.protocolType = protocolType
        self.direction = direction
        self.payloadContract = payloadContract
        self.isHeartbeatEnabled = isHeartbeatEnabled
    }
}

public enum RealtimeArchitect {
    public static var starterEvents: [RealtimeStreamEvent] {
        [
            RealtimeStreamEvent(
                eventType: "token_chunk",
                protocolType: "Server-Sent Events (SSE)",
                direction: "Server -> Client",
                payloadContract: "{ text: string, isFinished: boolean, model: string }",
                isHeartbeatEnabled: true
            ),
            RealtimeStreamEvent(
                eventType: "peer_cursor_moved",
                protocolType: "WebSocket",
                direction: "Bidirectional",
                payloadContract: "{ peerId: string, x: number, y: number, color: string }",
                isHeartbeatEnabled: true
            ),
            RealtimeStreamEvent(
                eventType: "workflow_step_status",
                protocolType: "Server-Sent Events (SSE)",
                direction: "Server -> Client",
                payloadContract: "{ stepId: string, status: 'running' | 'success' | 'failed', logs: string[] }",
                isHeartbeatEnabled: true
            )
        ]
    }

    public static func generateRealtimeMarkdown(title: String, events: [RealtimeStreamEvent]) -> String {
        var lines: [String] = [
            "# REAL-TIME STREAMING & PROTOCOL SPEC: \(title.uppercased())",
            "This document establishes streaming architectures for Google DeepMind Antigravity.",
            "All real-time streams MUST implement automatic reconnection, heartbeat pings, and typed payloads.",
            ""
        ]

        for (idx, e) in events.enumerated() {
            lines.append("## \(idx + 1). `\(e.eventType)` [\(e.protocolType)]")
            lines.append("- Direction: \(e.direction)")
            lines.append("- Heartbeat Enabled: `\(e.isHeartbeatEnabled)`")
            lines.append("- Payload Contract: `\(e.payloadContract)`")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateSseClientSnippet() -> String {
        let lines: [String] = [
            "// hooks/useRealtimeStream.ts",
            "// Resilient Server-Sent Events (SSE) subscriber with exponential backoff",
            "import { useEffect, useState, useRef } from 'react';",
            "",
            "export function useRealtimeStream(url: string, onMessage: (data: any) => void) {",
            "  const [isConnected, setIsConnected] = useState(false);",
            "  const retryCount = useRef(0);",
            "",
            "  useEffect(() => {",
            "    let eventSource: EventSource | null = null;",
            "    let timer: NodeJS.Timeout;",
            "",
            "    function connect() {",
            "      eventSource = new EventSource(url);",
            "      eventSource.onopen = () => {",
            "        setIsConnected(true);",
            "        retryCount.current = 0;",
            "      };",
            "      eventSource.onmessage = (event) => {",
            "        try {",
            "          const parsed = JSON.parse(event.data);",
            "          onMessage(parsed);",
            "        } catch (err) {",
            "          console.error('[SSE Parse Error]', err);",
            "        }",
            "      };",
            "      eventSource.onerror = () => {",
            "        setIsConnected(false);",
            "        eventSource?.close();",
            "        const delay = Math.min(1000 * Math.pow(2, retryCount.current), 30000);",
            "        retryCount.current += 1;",
            "        timer = setTimeout(connect, delay);",
            "      };",
            "    }",
            "",
            "    connect();",
            "    return () => {",
            "      eventSource?.close();",
            "      clearTimeout(timer);",
            "    };",
            "  }, [url]);",
            "",
            "  return { isConnected };",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(events: [RealtimeStreamEvent]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY REAL-TIME STREAMING DIRECTIVE]",
            "Do NOT use simple polling for live updates or build fragile WebSocket loops.",
            "Implement resilient streaming with automatic reconnection:",
            ""
        ]

        for e in events {
            lines.append("- [\(e.protocolType)] `\(e.eventType)` (\(e.direction)): payload \(e.payloadContract)")
        }

        lines.append("")
        lines.append("Always handle connection termination, backoff delays, and JSON parse guards.")
        return lines.joined(separator: "\n")
    }
}
