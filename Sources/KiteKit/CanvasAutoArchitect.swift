import CoreGraphics
import Foundation

public struct AutoArchitectureResult: Sendable {
    public let frames: [CanvasFrame]
    public let stickies: [CanvasSticky]
    public let connections: [CanvasConnection]

    public init(frames: [CanvasFrame], stickies: [CanvasSticky], connections: [CanvasConnection]) {
        self.frames = frames
        self.stickies = stickies
        self.connections = connections
    }
}

public enum CanvasAutoArchitect {
    public static func synthesize(
        title: String,
        concept: String,
        platform: String = "Web",
        style: String = "Apple Minimal"
    ) -> AutoArchitectureResult {
        let cleanTitle = stringOrFallback(title, fallback: "Архитектура")
        let cleanConcept = stringOrFallback(concept, fallback: "Сервис бизнес-логики")

        // 1. Frames (Layered Subsystems)
        let fClient = CanvasFrame(
            title: "1. Клиентский уровень (\(platform))",
            colorHex: "#3B82F6",
            x: 80,
            y: 80,
            width: 340,
            height: 480
        )

        let fGateway = CanvasFrame(
            title: "2. Edge Gateway & Безопасность",
            colorHex: "#8B5CF6",
            x: 480,
            y: 80,
            width: 340,
            height: 480
        )

        let fDomain = CanvasFrame(
            title: "3. Сервисы предметной области",
            colorHex: "#10B981",
            x: 880,
            y: 80,
            width: 360,
            height: 480
        )

        let fData = CanvasFrame(
            title: "4. Персистентность и Кэш",
            colorHex: "#64748B",
            x: 1300,
            y: 80,
            width: 340,
            height: 480
        )

        let fAsync = CanvasFrame(
            title: "5. Фоновые очереди и EventBus",
            colorHex: "#F59E0B",
            x: 880,
            y: 620,
            width: 360,
            height: 400
        )

        // 2. Component Stickies
        let sUI = CanvasSticky(
            text: "\(cleanTitle) UI (\(platform))\nЭстетика: \(style)",
            colorHex: "#BAE6FD",
            position: CGPoint(x: 250, y: 180)
        )

        let sState = CanvasSticky(
            text: "Клиентский менеджер состояния и кэш форм",
            colorHex: "#E0F2FE",
            position: CGPoint(x: 250, y: 380)
        )

        let sGateway = CanvasSticky(
            text: "Edge API Gateway\nRate Limiter (100 req/min) & WAF",
            colorHex: "#DDD6FE",
            position: CGPoint(x: 650, y: 180)
        )

        let sAuth = CanvasSticky(
            text: "JWT Auth / Session Guard\nПроверка прав и RBAC",
            colorHex: "#EDE9FE",
            position: CGPoint(x: 650, y: 380)
        )

        let sCoreService = CanvasSticky(
            text: "\(cleanTitle) Core Domain Service\n\(cleanConcept)",
            colorHex: "#BBF7D0",
            position: CGPoint(x: 1060, y: 180)
        )

        let sValidator = CanvasSticky(
            text: "Zod Schema Validator & Бизнес-правила",
            colorHex: "#DCFCE7",
            position: CGPoint(x: 1060, y: 380)
        )

        let sDB = CanvasSticky(
            text: "PostgreSQL Database\nРеляционная схема с B-Tree индексами",
            colorHex: "#E2E8F0",
            position: CGPoint(x: 1470, y: 180)
        )

        let sRedis = CanvasSticky(
            text: "Redis In-Memory Cache\nLRU буфер горячих запросов (TTL 300s)",
            colorHex: "#F1F5F9",
            position: CGPoint(x: 1470, y: 380)
        )

        let sEventBus = CanvasSticky(
            text: "Domain EventBus\nПубликация доменных событий",
            colorHex: "#FEF08A",
            position: CGPoint(x: 1060, y: 720)
        )

        let sWorker = CanvasSticky(
            text: "Async Job Queue (Inngest/Temporal)\nТяжелые задачи, письма и вебхуки",
            colorHex: "#FEF9C3",
            position: CGPoint(x: 1060, y: 880)
        )

        // 3. Typified Protocol Connections
        let c1 = CanvasConnection(
            fromId: "sticky-\(sUI.id.uuidString)",
            toId: "sticky-\(sGateway.id.uuidString)",
            label: "tRPC",
            colorHex: CanvasConnectionProtocol.trpc.colorHex
        )

        let c2 = CanvasConnection(
            fromId: "sticky-\(sGateway.id.uuidString)",
            toId: "sticky-\(sAuth.id.uuidString)",
            label: "gRPC",
            colorHex: CanvasConnectionProtocol.grpc.colorHex
        )

        let c3 = CanvasConnection(
            fromId: "sticky-\(sGateway.id.uuidString)",
            toId: "sticky-\(sCoreService.id.uuidString)",
            label: "gRPC",
            colorHex: CanvasConnectionProtocol.grpc.colorHex
        )

        let c4 = CanvasConnection(
            fromId: "sticky-\(sCoreService.id.uuidString)",
            toId: "sticky-\(sValidator.id.uuidString)",
            label: "Calls",
            colorHex: CanvasConnectionProtocol.rest.colorHex
        )

        let c5 = CanvasConnection(
            fromId: "sticky-\(sCoreService.id.uuidString)",
            toId: "sticky-\(sDB.id.uuidString)",
            label: "SQL",
            colorHex: CanvasConnectionProtocol.sql.colorHex
        )

        let c6 = CanvasConnection(
            fromId: "sticky-\(sCoreService.id.uuidString)",
            toId: "sticky-\(sRedis.id.uuidString)",
            label: "REST",
            colorHex: CanvasConnectionProtocol.rest.colorHex
        )

        let c7 = CanvasConnection(
            fromId: "sticky-\(sCoreService.id.uuidString)",
            toId: "sticky-\(sEventBus.id.uuidString)",
            label: "EventBus",
            colorHex: CanvasConnectionProtocol.eventbus.colorHex
        )

        let c8 = CanvasConnection(
            fromId: "sticky-\(sEventBus.id.uuidString)",
            toId: "sticky-\(sWorker.id.uuidString)",
            label: "Queue",
            colorHex: CanvasConnectionProtocol.queue.colorHex
        )

        let c9 = CanvasConnection(
            fromId: "sticky-\(sUI.id.uuidString)",
            toId: "sticky-\(sState.id.uuidString)",
            label: "Sync",
            colorHex: CanvasConnectionProtocol.websocket.colorHex
        )

        return AutoArchitectureResult(
            frames: [fClient, fGateway, fDomain, fData, fAsync],
            stickies: [sUI, sState, sGateway, sAuth, sCoreService, sValidator, sDB, sRedis, sEventBus, sWorker],
            connections: [c1, c2, c3, c4, c5, c6, c7, c8, c9]
        )
    }

    private static func stringOrFallback(_ str: String, fallback: String) -> String {
        let clean = str.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? fallback : clean
    }
}
