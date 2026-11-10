import Foundation
import Network

public final class KiteSyncServer: @unchecked Sendable {
    public static let shared = KiteSyncServer()

    public private(set) var isRunning: Bool = false
    public private(set) var boundPort: UInt16 = 24242

    public var exportIdeasProvider: (@Sendable () async -> Data?)?
    public var importIdeasHandler: (@Sendable (Data) async -> Int)?
    public var exportCanvasProvider: (@Sendable () async -> Data?)?
    public var importCanvasHandler: (@Sendable (Data) async -> Bool)?

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.kite.syncserver", qos: .userInitiated)
    private var sseConnections: [NWConnection] = []
    private let sseLock = NSLock()

    private init() {}

    public func start(port: UInt16 = 24242) {
        guard !isRunning else { return }
        self.boundPort = port

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        do {
            guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
            let listener = try NWListener(using: params, on: nwPort)
            self.listener = listener

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    KiteLANBeacon.shared.start(appPort: Int(port))
                    KiteLog.sync.info("KiteSyncServer listening on port \(port)")
                case .failed(let err):
                    KiteLog.sync.error("KiteSyncServer failed: \(err.localizedDescription)")
                    self?.stop()
                case .cancelled:
                    self?.isRunning = false
                    KiteLANBeacon.shared.stop()
                    KiteLog.sync.info("KiteSyncServer stopped")
                default:
                    break
                }
            }

            listener.start(queue: queue)
        } catch {
            KiteLog.sync.error("KiteSyncServer failed to bind port \(port): \(error.localizedDescription)")
        }
    }

    public func stop() {
        sseLock.lock()
        for conn in sseConnections {
            conn.cancel()
        }
        sseConnections.removeAll()
        sseLock.unlock()

        listener?.cancel()
        listener = nil
        isRunning = false
        KiteLANBeacon.shared.stop()
    }

    public func broadcast(event: String, payload: [String: Any] = [:]) {
        let jsonPayload: String
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let str = String(data: data, encoding: .utf8) {
            jsonPayload = str
        } else {
            jsonPayload = "{}"
        }
        let sseString = "event: message\ndata: {\"type\":\"\(event)\",\"payload\":\(jsonPayload)}\n\n"
        let data = Data(sseString.utf8)

        sseLock.lock()
        let connections = sseConnections
        sseLock.unlock()

        for conn in connections {
            conn.send(content: data, completion: .contentProcessed { [weak self] error in
                if error != nil {
                    self?.removeSseConnection(conn)
                }
            })
        }
    }

    private func addSseConnection(_ connection: NWConnection) {
        sseLock.lock()
        sseConnections.append(connection)
        sseLock.unlock()

        let header = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream; charset=utf-8\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
        connection.send(content: Data(header.utf8), completion: .contentProcessed { _ in })

        let welcome = "data: {\"type\":\"connected\",\"app\":\"Kite macOS\",\"port\":\(boundPort)}\n\n"
        connection.send(content: Data(welcome.utf8), completion: .contentProcessed { _ in })
    }

    private func removeSseConnection(_ connection: NWConnection) {
        sseLock.lock()
        sseConnections.removeAll(where: { $0 === connection })
        sseLock.unlock()
        connection.cancel()
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(connection)
    }

    private func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] data, _, _, _ in
            guard let self = self, let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            Task {
                await self.processHTTP(data: data, connection: connection)
            }
        }
    }

    private func processHTTP(data: Data, connection: NWConnection) async {
        guard let rawString = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, status: "400 Bad Request")
            return
        }

        // Split headers and body
        let parts = rawString.components(separatedBy: "\r\n\r\n")
        let headerPart = parts[0]
        let lines = headerPart.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(connection: connection, status: "400 Bad Request")
            return
        }

        let tokens = requestLine.components(separatedBy: " ")
        guard tokens.count >= 2 else {
            sendResponse(connection: connection, status: "400 Bad Request")
            return
        }

        let method = tokens[0].uppercased()
        let path = tokens[1]
        KiteLog.sync.debug("Incoming \(method) \(path)")

        // CORS Preflight
        if method == "OPTIONS" {
            sendResponse(connection: connection, status: "204 No Content")
            return
        }

        // Body extraction
        var bodyData = Data()
        if parts.count > 1 {
            let bodyString = parts[1...].joined(separator: "\r\n\r\n")
            bodyData = Data(bodyString.utf8)
        }

        switch (method, path) {
        case ("GET", "/"), ("GET", "/index.html"):
            let html = WebStudio.html(port: Int(boundPort), appName: "Kite macOS")
            sendResponse(connection: connection, contentType: "text/html; charset=utf-8", body: Data(html.utf8))

        case ("GET", "/api/events"):
            addSseConnection(connection)
            return

        case ("GET", "/api/status"):
            let json = """
            {"status":"online","app":"Kite macOS","version":"1.3.0","port":\(boundPort)}
            """
            sendResponse(connection: connection, body: Data(json.utf8))

        case ("GET", "/api/peers"):
            let peers = KiteLANBeacon.shared.activePeers
            if let data = try? JSONEncoder().encode(peers) {
                sendResponse(connection: connection, contentType: "application/json", body: data)
            } else {
                sendResponse(connection: connection, contentType: "application/json", body: Data("[]".utf8))
            }

        case ("GET", "/api/ideas"):
            let responseData = await exportIdeasProvider?() ?? Data("{\"ideas\":[]}".utf8)
            sendResponse(connection: connection, body: responseData)

        case ("POST", "/api/ideas"):
            let count = await importIdeasHandler?(bodyData) ?? 0
            broadcast(event: "ideas_updated", payload: ["imported": count])
            let res = "{\"status\":\"ok\",\"imported\":\(count)}"
            sendResponse(connection: connection, body: Data(res.utf8))

        case ("GET", "/api/canvas"):
            let responseData = await exportCanvasProvider?() ?? Data("{}".utf8)
            sendResponse(connection: connection, body: responseData)

        case ("POST", "/api/canvas"):
            let ok = await importCanvasHandler?(bodyData) ?? false
            if ok {
                broadcast(event: "canvas_updated", payload: ["status": "ok"])
            }
            let res = "{\"status\":\(ok ? "\"ok\"" : "\"error\"")}"
            sendResponse(connection: connection, body: Data(res.utf8))

        case ("POST", "/api/ide/active"):
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let filePath = json["filePath"] as? String {
                let line = json["line"] as? Int
                let editor = json["editor"] as? String ?? "ide"
                IDEBridgeHub.shared.updateActiveFile(path: filePath, line: line, editor: editor)
                broadcast(event: "ide_active_file", payload: ["filePath": filePath, "line": line ?? 0, "editor": editor])
                let res = "{\"status\":\"ok\",\"filePath\":\"\(filePath)\"}"
                sendResponse(connection: connection, body: Data(res.utf8))
            } else {
                sendResponse(connection: connection, status: "400 Bad Request", body: Data("{\"error\":\"Invalid payload\"}".utf8))
            }

        case ("POST", "/api/ide/navigate"):
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let filePath = json["filePath"] as? String {
                let line = json["line"] as? Int ?? 1
                let column = json["column"] as? Int ?? 1
                let editor = json["editor"] as? String ?? "vscode"
                broadcast(event: "ide_navigate", payload: ["filePath": filePath, "line": line, "column": column, "editor": editor])
                let res = "{\"status\":\"ok\",\"navigated\":true}"
                sendResponse(connection: connection, body: Data(res.utf8))
            } else {
                sendResponse(connection: connection, status: "400 Bad Request", body: Data("{\"error\":\"Invalid payload\"}".utf8))
            }

        case ("GET", "/api/ide/status"):
            let current = IDEBridgeHub.shared.currentActiveFile
            let path = current.path ?? ""
            let line = current.line ?? 0
            let res = "{\"status\":\"online\",\"activeFilePath\":\"\(path)\",\"activeLine\":\(line)}"
            sendResponse(connection: connection, body: Data(res.utf8))

        case ("GET", "/api/telemetry"):
            let list = IDEBridgeHub.shared.allTelemetries()
            if let data = try? JSONEncoder().encode(list) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("[]".utf8))
            }

        case ("POST", "/api/telemetry"):
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let nodeId = json["nodeId"] as? String {
                let rps = (json["rps"] as? NSNumber)?.doubleValue ?? 0.0
                let p99 = (json["p99LatencyMs"] as? NSNumber)?.doubleValue ?? 0.0
                let errorRate = (json["errorRate"] as? NSNumber)?.doubleValue ?? 0.0
                let item = NodeTelemetry(nodeId: nodeId, rps: rps, p99LatencyMs: p99, errorRate: errorRate)
                IDEBridgeHub.shared.setTelemetry(item)
                broadcast(event: "telemetry_updated", payload: ["nodeId": nodeId, "status": item.status.rawValue, "rps": rps, "p99LatencyMs": p99, "errorRate": errorRate])
                if let data = try? JSONEncoder().encode(item) {
                    sendResponse(connection: connection, body: data)
                } else {
                    sendResponse(connection: connection, body: Data("{\"status\":\"ok\"}".utf8))
                }
            } else {
                sendResponse(connection: connection, status: "400 Bad Request", body: Data("{\"error\":\"Invalid telemetry data\"}".utf8))
            }

        case ("POST", "/api/relay/create"):
            let roomToken = RoomSecurityKeyDeriver.generateRoomToken()
            let res = """
            {"status":"ok","roomId":"\(roomToken)","joinUrl":"kite://join?room=\(roomToken)","isEncrypted":true}
            """
            sendResponse(connection: connection, body: Data(res.utf8))

        case ("GET", "/api/relay/status"):
            let stats = WebRTCMeshManager.shared.statistics()
            let peers = WebRTCMeshManager.shared.activePeers()
            struct RelayStatusResponse: Codable {
                let stats: MeshSyncStatistics
                let peers: [MeshPeerNode]
                let isOnline: Bool
            }
            let resp = RelayStatusResponse(stats: stats, peers: peers, isOnline: true)
            if let data = try? JSONEncoder().encode(resp) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{\"isOnline\":true}".utf8))
            }

        case ("POST", "/api/relay/signal"):
            if let msg = try? JSONDecoder().decode(SignalingMessage.self, from: bodyData) {
                RelayStationHub.shared.routeMessage(msg)
                broadcast(event: "relay_signal_routed", payload: ["type": msg.type.rawValue, "roomId": msg.roomId, "sender": msg.senderPeerId])
                sendResponse(connection: connection, body: Data("{\"status\":\"ok\",\"routed\":true}".utf8))
            } else {
                sendResponse(connection: connection, status: "400 Bad Request", body: Data("{\"error\":\"Invalid signaling message\"}".utf8))
            }

        case ("GET", let p) where p.starts(with: "/api/relay/messages"):
            // Extract peerId from query parameter
            var peerId = ""
            if let queryIndex = p.firstIndex(of: "?") {
                let queryString = String(p[p.index(after: queryIndex)...])
                let pairs = queryString.components(separatedBy: "&")
                for pair in pairs {
                    let kv = pair.components(separatedBy: "=")
                    if kv.count == 2 && kv[0] == "peerId" {
                        peerId = kv[1]
                    }
                }
            }
            let msgs = RelayStationHub.shared.popMessages(for: peerId)
            if let data = try? JSONEncoder().encode(msgs) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("[]".utf8))
            }

        case ("GET", "/api/plugins"):
            let plugins = WasmPluginEngine.shared.allPlugins()
            if let data = try? JSONEncoder().encode(plugins) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("[]".utf8))
            }

        case ("POST", "/api/plugins/execute"):
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let pluginId = json["pluginId"] as? String {
                let context = json["context"] as? [String: Any] ?? [:]
                let result = WasmPluginEngine.shared.executePlugin(id: pluginId, inputContext: context)
                if let data = try? JSONEncoder().encode(result) {
                    sendResponse(connection: connection, body: data)
                } else {
                    sendResponse(connection: connection, body: Data("{\"isSuccess\":true}".utf8))
                }
            } else {
                sendResponse(connection: connection, status: "400 Bad Request", body: Data("{\"error\":\"Invalid plugin execution request\"}".utf8))
            }

        case ("GET", "/api/worktree/status"):
            let session = WorktreeSyncEngine.shared.getSession()
            if let data = try? JSONEncoder().encode(session) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{}".utf8))
            }

        case ("POST", "/api/worktree/sync"):
            var nodesList: [(id: String, name: String, type: String)] = [
                (id: "node-1", name: "Orders API", type: "api-service"),
                (id: "node-2", name: "Orders DB", type: "postgres-database"),
                (id: "node-3", name: "Order Events", type: "kafka-stream")
            ]
            var branch: String? = nil
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                branch = json["branch"] as? String
                if let customNodes = json["nodes"] as? [[String: String]] {
                    nodesList = customNodes.compactMap { n in
                        guard let id = n["id"], let name = n["name"], let type = n["type"] else { return nil }
                        return (id: id, name: name, type: type)
                    }
                }
            }
            let syncResult = WorktreeSyncEngine.shared.executeSync(branchName: branch, nodes: nodesList)
            if let data = try? JSONEncoder().encode(syncResult) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{\"isSuccess\":true}".utf8))
            }

        case ("POST", "/api/worktree/pr"):
            var title: String? = nil
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                title = json["title"] as? String
            }
            let pr = WorktreeSyncEngine.shared.synthesizePullRequest(customTitle: title)
            if let data = try? JSONEncoder().encode(pr) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{}".utf8))
            }

        case ("GET", "/api/audit/trail"):
            let leaves = MerkleAuditEngine.shared.allLeaves()
            let root = MerkleAuditEngine.shared.computeMerkleRoot()
            let payload: [String: Any] = [
                "rootHash": root.rootHash,
                "leafCount": root.leafCount,
                "height": root.height,
                "generatedAt": root.generatedAtIso,
                "leaves": leaves.map { l in
                    [
                        "index": l.index,
                        "action": l.action.rawValue,
                        "actor": l.actor.email,
                        "entityId": l.entityId,
                        "leafHash": l.leafHash,
                        "previousHash": l.previousHash
                    ]
                }
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{}".utf8))
            }

        case ("POST", "/api/audit/record"):
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let actionRaw = json["action"] as? String,
               let action = AuditActionType(rawValue: actionRaw),
               let entityId = json["entityId"] as? String,
               let entityType = json["entityType"] as? String {
                let payloadJson = json["payload"] as? String ?? "{}"
                let leaf = MerkleAuditEngine.shared.recordAction(
                    action: action,
                    entityId: entityId,
                    entityType: entityType,
                    payloadJson: payloadJson
                )
                if let data = try? JSONEncoder().encode(leaf) {
                    sendResponse(connection: connection, body: data)
                } else {
                    sendResponse(connection: connection, body: Data("{\"isSuccess\":true}".utf8))
                }
            } else {
                sendResponse(connection: connection, status: "400 Bad Request", body: Data("{\"error\":\"Invalid audit record payload\"}".utf8))
            }

        case ("POST", "/api/audit/verify"):
            var leafIndex = 0
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let idx = json["leafIndex"] as? Int {
                leafIndex = idx
            }
            if let proof = MerkleAuditEngine.shared.generateInclusionProof(forLeafIndex: leafIndex),
               let data = try? JSONEncoder().encode(proof) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, status: "404 Not Found", body: Data("{\"error\":\"Proof generation failed\"}".utf8))
            }

        case ("GET", "/api/iam/session"):
            let actor = MerkleAuditEngine.shared.getCurrentActor()
            if let data = try? JSONEncoder().encode(actor) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{}".utf8))
            }

        case ("POST", "/api/audit/rfc"):
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let rfcId = json["rfcId"] as? String,
               let approve = json["approve"] as? Bool {
                let result = MerkleAuditEngine.shared.signOffRFC(rfcId: rfcId, approve: approve)
                if result.success, let item = result.item, let data = try? JSONEncoder().encode(item) {
                    sendResponse(connection: connection, body: data)
                } else {
                    let errMsg = result.error ?? "Operation failed"
                    sendResponse(connection: connection, status: "403 Forbidden", body: Data("{\"error\":\"\(errMsg)\"}".utf8))
                }
            } else {
                let rfcs = MerkleAuditEngine.shared.allRFCs()
                if let data = try? JSONEncoder().encode(rfcs) {
                    sendResponse(connection: connection, body: data)
                } else {
                    sendResponse(connection: connection, body: Data("[]".utf8))
                }
            }

        case ("GET", "/api/tf/export"):
            let sampleNodes = [
                (id: "node-1", name: "Billing Database", type: "postgres-database"),
                (id: "node-2", name: "Payment Processor", type: "api-service"),
                (id: "node-3", name: "Invoices Bucket", type: "s3-storage")
            ]
            let bundle = TerraformIaCEngine.shared.synthesizeHcl(provider: .aws, nodes: sampleNodes)
            if let data = try? JSONEncoder().encode(bundle) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{}".utf8))
            }

        case ("POST", "/api/tf/import"):
            var stateStr = "{}"
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let rawState = json["jsonState"] as? String {
                stateStr = rawState
            } else if let raw = String(data: bodyData, encoding: .utf8), !raw.isEmpty {
                stateStr = raw
            }
            let importRes = TerraformIaCEngine.shared.reverseEngineerState(jsonState: stateStr)
            if let data = try? JSONEncoder().encode(importRes) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{\"isSuccess\":false}".utf8))
            }

        case ("POST", "/api/tf/plan"):
            let targetNodes = [
                (id: "node-1", name: "Billing Database", type: "postgres-database"),
                (id: "node-2", name: "Payment Processor", type: "api-service"),
                (id: "node-3", name: "Invoices Bucket", type: "s3-storage")
            ]
            var activeRes: [String] = []
            if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let list = json["activeResources"] as? [String] {
                activeRes = list
            }
            let planDiff = TerraformIaCEngine.shared.calculatePlan(targetNodes: targetNodes, activeResources: activeRes)
            if let data = try? JSONEncoder().encode(planDiff) {
                sendResponse(connection: connection, body: data)
            } else {
                sendResponse(connection: connection, body: Data("{}".utf8))
            }

        default:
            sendResponse(connection: connection, status: "404 Not Found")
        }
    }

    private func sendResponse(
        connection: NWConnection,
        status: String = "200 OK",
        contentType: String = "application/json; charset=utf-8",
        body: Data = Data()
    ) {
        let headers = [
            "HTTP/1.1 \(status)",
            "Content-Type: \(contentType)",
            "Content-Length: \(body.count)",
            "Access-Control-Allow-Origin: *",
            "Access-Control-Allow-Methods: GET, POST, OPTIONS",
            "Access-Control-Allow-Headers: Content-Type, Accept",
            "Connection: close",
            "",
            ""
        ].joined(separator: "\r\n")

        var payload = Data(headers.utf8)
        payload.append(body)

        connection.send(content: payload, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
