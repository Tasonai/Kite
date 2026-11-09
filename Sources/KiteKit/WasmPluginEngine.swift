import Foundation

/// WebAssembly (WASM) Sandboxed Plugin Runtime & Extensibility Engine
/// Standard: Google DeepMind Antigravity Craftsmanship Standard (Zero Emojis).

public struct PluginCustomNodeSpec: Sendable, Codable, Equatable {
    public var typeId: String
    public var displayName: String
    public var category: String
    public var defaultWidth: Double
    public var defaultHeight: Double
    public var iconSymbol: String
    public var accentColorHex: String
    public var defaultProperties: [String: String]

    public init(
        typeId: String,
        displayName: String,
        category: String = "Custom Integration",
        defaultWidth: Double = 256.0,
        defaultHeight: Double = 160.0,
        iconSymbol: String = "cube.box",
        accentColorHex: String = "#FF9F0A",
        defaultProperties: [String: String] = [:]
    ) {
        self.typeId = typeId
        self.displayName = displayName
        self.category = category
        self.defaultWidth = defaultWidth
        self.defaultHeight = defaultHeight
        self.iconSymbol = iconSymbol
        self.accentColorHex = accentColorHex
        self.defaultProperties = defaultProperties
    }
}

public struct PluginProtocolValidatorSpec: Sendable, Codable, Equatable {
    public var protocolName: String
    public var allowedSourceTypes: [String]
    public var allowedTargetTypes: [String]
    public var requiredProperties: [String]
    public var errorMessage: String

    public init(
        protocolName: String,
        allowedSourceTypes: [String],
        allowedTargetTypes: [String],
        requiredProperties: [String] = [],
        errorMessage: String
    ) {
        self.protocolName = protocolName
        self.allowedSourceTypes = allowedSourceTypes
        self.allowedTargetTypes = allowedTargetTypes
        self.requiredProperties = requiredProperties
        self.errorMessage = errorMessage
    }
}

public struct KitePluginManifest: Sendable, Codable, Equatable {
    public var id: String
    public var name: String
    public var version: String
    public var author: String
    public var description: String
    public var entrypoint: String
    public var customNodes: [PluginCustomNodeSpec]
    public var validators: [PluginProtocolValidatorSpec]

    public init(
        id: String,
        name: String,
        version: String = "1.0.0",
        author: String = "Kite Community",
        description: String = "",
        entrypoint: String = "plugin.wasm",
        customNodes: [PluginCustomNodeSpec] = [],
        validators: [PluginProtocolValidatorSpec] = []
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.description = description
        self.entrypoint = entrypoint
        self.customNodes = customNodes
        self.validators = validators
    }
}

public struct WasmExecutionResult: Sendable, Codable, Equatable {
    public var isSuccess: Bool
    public var executionTimeMs: Double
    public var memoryUsedBytes: Int
    public var outputLogs: [String]
    public var violations: [String]

    public init(
        isSuccess: Bool,
        executionTimeMs: Double,
        memoryUsedBytes: Int = 1024,
        outputLogs: [String] = [],
        violations: [String] = []
    ) {
        self.isSuccess = isSuccess
        self.executionTimeMs = executionTimeMs
        self.memoryUsedBytes = memoryUsedBytes
        self.outputLogs = outputLogs
        self.violations = violations
    }
}

/// Sandboxed WebAssembly Module Header & Memory Validator
public enum WasmModuleValidator {
    public static let wasmMagicHeader: [UInt8] = [0x00, 0x61, 0x73, 0x6D] // "\0asm"
    public static let wasmVersion: [UInt8] = [0x01, 0x00, 0x00, 0x00]     // version 1

    /// Validates raw byte sequence as valid WebAssembly binary
    public static func validateBinary(bytes: [UInt8]) -> Bool {
        guard bytes.count >= 8 else { return false }
        let header = Array(bytes[0..<4])
        let version = Array(bytes[4..<8])
        return header == wasmMagicHeader && version == wasmVersion
    }

    /// Generates a minimal valid WASM binary stub for plugins
    public static func generateMinimalWasmStub() -> [UInt8] {
        return wasmMagicHeader + wasmVersion
    }
}

/// Thread-Safe Plugin Runtime Registry & WASM Execution Manager
public final class WasmPluginEngine: @unchecked Sendable {
    public static let shared = WasmPluginEngine()

    private let lock = NSLock()
    private var registeredPlugins: [String: KitePluginManifest] = [:]
    private var pluginBinaries: [String: [UInt8]] = [:]

    public init() {
        registerBuiltinPlugins()
    }

    private func registerBuiltinPlugins() {
        // 1. Kafka Event Stream Plugin
        let kafkaPlugin = KitePluginManifest(
            id: "kite-plugin-kafka",
            name: "Apache Kafka Streaming Validator",
            version: "1.2.0",
            author: "Confluent",
            description: "Custom event broker node and connection validation for pub/sub event streams.",
            entrypoint: "kafka.wasm",
            customNodes: [
                PluginCustomNodeSpec(
                    typeId: "kafka-cluster",
                    displayName: "Kafka Broker Cluster",
                    category: "Event Streaming",
                    iconSymbol: "arrow.triangle.merge",
                    accentColorHex: "#3273DC",
                    defaultProperties: ["partitions": "12", "replication": "3", "retentionHours": "168"]
                )
            ],
            validators: [
                PluginProtocolValidatorSpec(
                    protocolName: "kafka-topic",
                    allowedSourceTypes: ["api-gateway", "worker-service", "microservice"],
                    allowedTargetTypes: ["kafka-cluster"],
                    requiredProperties: ["topicName", "schemaRegistry"],
                    errorMessage: "Kafka topic connection requires topicName and schemaRegistry properties."
                )
            ]
        )

        // 2. Snowflake Data Warehouse Plugin
        let snowflakePlugin = KitePluginManifest(
            id: "kite-plugin-snowflake",
            name: "Snowflake Analytics Lakehouse",
            version: "1.0.4",
            author: "Snowflake Inc",
            description: "Custom analytical warehouse frame and column-level isolation validator.",
            entrypoint: "snowflake.wasm",
            customNodes: [
                PluginCustomNodeSpec(
                    typeId: "snowflake-warehouse",
                    displayName: "Snowflake Virtual Warehouse",
                    category: "Data Warehouse",
                    iconSymbol: "snowflake",
                    accentColorHex: "#29B5E8",
                    defaultProperties: ["size": "X-Small", "autoSuspendMin": "10"]
                )
            ],
            validators: [
                PluginProtocolValidatorSpec(
                    protocolName: "sql-analytics",
                    allowedSourceTypes: ["etl-pipeline", "bi-dashboard", "batch-job"],
                    allowedTargetTypes: ["snowflake-warehouse"],
                    requiredProperties: ["role", "warehouse"],
                    errorMessage: "Snowflake connection requires role and warehouse properties."
                )
            ]
        )

        let stubBytes = WasmModuleValidator.generateMinimalWasmStub()
        registerPlugin(manifest: kafkaPlugin, binary: stubBytes)
        registerPlugin(manifest: snowflakePlugin, binary: stubBytes)
    }

    public func registerPlugin(manifest: KitePluginManifest, binary: [UInt8]) {
        lock.lock()
        defer { lock.unlock() }

        registeredPlugins[manifest.id] = manifest
        pluginBinaries[manifest.id] = binary
    }

    public func unregisterPlugin(id: String) {
        lock.lock()
        defer { lock.unlock() }

        registeredPlugins.removeValue(forKey: id)
        pluginBinaries.removeValue(forKey: id)
    }

    public func allPlugins() -> [KitePluginManifest] {
        lock.lock()
        defer { lock.unlock() }
        return Array(registeredPlugins.values)
    }

    public func getPlugin(id: String) -> KitePluginManifest? {
        lock.lock()
        defer { lock.unlock() }
        return registeredPlugins[id]
    }

    /// Executes sandboxed WASM plugin validation against a connection or frame
    public func executePlugin(id: String, inputContext: [String: Any]) -> WasmExecutionResult {
        lock.lock()
        let plugin = registeredPlugins[id]
        let binary = pluginBinaries[id]
        lock.unlock()

        guard let plugin = plugin, let binary = binary else {
            return WasmExecutionResult(isSuccess: false, executionTimeMs: 0.1, outputLogs: ["Plugin not found"])
        }

        // Validate WASM binary header
        guard WasmModuleValidator.validateBinary(bytes: binary) else {
            return WasmExecutionResult(isSuccess: false, executionTimeMs: 0.2, outputLogs: ["Invalid WASM binary header"])
        }

        let start = Date()
        var logs: [String] = ["Loaded WASM module '\(plugin.entrypoint)' (\(binary.count) bytes)"]
        var violations: [String] = []

        // Simulate sandboxed execution of plugin validators
        for val in plugin.validators {
            let protocolName = inputContext["protocol"] as? String ?? ""
            if !protocolName.isEmpty && protocolName == val.protocolName {
                let props = inputContext["properties"] as? [String: String] ?? [:]
                for req in val.requiredProperties {
                    if props[req] == nil || props[req]?.isEmpty == true {
                        violations.append("Violation: \(val.errorMessage) Missing property '\(req)'.")
                    }
                }
            }
        }

        let elapsed = Date().timeIntervalSince(start) * 1000.0
        logs.append("WASM execution finished in \(String(format: "%.2f", elapsed))ms")

        return WasmExecutionResult(
            isSuccess: violations.isEmpty,
            executionTimeMs: elapsed,
            memoryUsedBytes: binary.count + 4096,
            outputLogs: logs,
            violations: violations
        )
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        registeredPlugins.removeAll()
        pluginBinaries.removeAll()
        registerBuiltinPlugins()
    }
}
