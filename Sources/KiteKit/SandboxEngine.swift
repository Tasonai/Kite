import Foundation

public enum SandboxRuntime: String, Codable, Sendable {
    case docker = "docker"
    case appleVirtualization = "apple_virtualization"
    case processIsolation = "process_isolation"
    case wasm = "wasm"
}

public enum SandboxStatus: String, Codable, Sendable {
    case idle = "idle"
    case provisioning = "provisioning"
    case running = "running"
    case degraded = "degraded"
    case terminated = "terminated"
}

public struct ServiceContainerSpec: Codable, Sendable, Identifiable {
    public var id: String { name }
    public var name: String
    public var image: String
    public var internalPort: Int
    public var hostPort: Int
    public var environment: [String: String]
    public var healthCheckCommand: String?
    public var dependsOn: [String]

    public init(
        name: String,
        image: String,
        internalPort: Int,
        hostPort: Int,
        environment: [String: String] = [:],
        healthCheckCommand: String? = nil,
        dependsOn: [String] = []
    ) {
        self.name = name
        self.image = image
        self.internalPort = internalPort
        self.hostPort = hostPort
        self.environment = environment
        self.healthCheckCommand = healthCheckCommand
        self.dependsOn = dependsOn
    }
}

public enum SandboxEngine {
    public static func inferContainerSpec(for frameTitle: String, index: Int) -> ServiceContainerSpec {
        let lower = frameTitle.lowercased()
        let cleanName = frameTitle
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        let svcName = cleanName.isEmpty ? "service-\(index)" : cleanName

        if lower.contains("postgres") || lower.contains("db") || lower.contains("database") {
            return ServiceContainerSpec(
                name: svcName,
                image: "postgres:16-alpine",
                internalPort: 5432,
                hostPort: 5432 + index,
                environment: [
                    "POSTGRES_DB": "kitedb",
                    "POSTGRES_USER": "kite",
                    "POSTGRES_PASSWORD": "kite_secret_dev_pass"
                ],
                healthCheckCommand: "pg_isready -U kite -d kitedb",
                dependsOn: []
            )
        } else if lower.contains("redis") || lower.contains("cache") {
            return ServiceContainerSpec(
                name: svcName,
                image: "redis:7-alpine",
                internalPort: 6379,
                hostPort: 6379 + index,
                healthCheckCommand: "redis-cli ping",
                dependsOn: []
            )
        } else if lower.contains("gateway") || lower.contains("ingress") || lower.contains("proxy") {
            return ServiceContainerSpec(
                name: svcName,
                image: "traefik:v3.0",
                internalPort: 80,
                hostPort: 8080 + index,
                dependsOn: []
            )
        } else if lower.contains("web") || lower.contains("front") || lower.contains("ui") {
            return ServiceContainerSpec(
                name: svcName,
                image: "node:20-alpine",
                internalPort: 3000,
                hostPort: 3000 + index,
                environment: ["NODE_ENV": "development", "PORT": "3000"],
                dependsOn: []
            )
        } else {
            return ServiceContainerSpec(
                name: svcName,
                image: "golang:1.22-alpine",
                internalPort: 8000,
                hostPort: 8000 + index,
                environment: ["APP_ENV": "development"],
                dependsOn: []
            )
        }
    }

    public static func synthesizeDockerCompose(from frames: [CanvasFrame]) -> String {
        var lines: [String] = [
            "# Generated automatically by Kite Sandbox Engine (BAMA/BAWA Specification)",
            "# Zero Emojis, production isolated micro-environment topology",
            "version: '3.8'",
            "",
            "services:"
        ]

        var specs: [ServiceContainerSpec] = []
        for (idx, frame) in frames.enumerated() {
            specs.append(inferContainerSpec(for: frame.title, index: idx))
        }

        // Establish natural dependency ordering
        let dbServices = specs.filter { $0.image.contains("postgres") || $0.image.contains("redis") }
        let dbNames = dbServices.map(\.name)

        for spec in specs {
            var mutableSpec = spec
            if !dbNames.contains(mutableSpec.name) && !dbNames.isEmpty {
                mutableSpec.dependsOn = dbNames
            }

            lines.append("  \(mutableSpec.name):")
            lines.append("    image: \(mutableSpec.image)")
            lines.append("    container_name: kite-\(mutableSpec.name)")
            lines.append("    ports:")
            lines.append("      - \"\(mutableSpec.hostPort):\(mutableSpec.internalPort)\"")

            if !mutableSpec.environment.isEmpty {
                lines.append("    environment:")
                for (k, v) in mutableSpec.environment.sorted(by: { $0.key < $1.key }) {
                    lines.append("      \(k): \(v)")
                }
            }

            if let hc = mutableSpec.healthCheckCommand {
                lines.append("    healthcheck:")
                lines.append("      test: [\"CMD-SHELL\", \"\(hc)\"]")
                lines.append("      interval: 10s")
                lines.append("      timeout: 5s")
                lines.append("      retries: 5")
            }

            if !mutableSpec.dependsOn.isEmpty {
                lines.append("    depends_on:")
                for dep in mutableSpec.dependsOn {
                    lines.append("      - \(dep)")
                }
            }

            lines.append("    networks:")
            lines.append("      - kite-mesh-net")
            lines.append("    restart: unless-stopped")
            lines.append("")
        }

        lines.append("networks:")
        lines.append("  kite-mesh-net:")
        lines.append("    driver: bridge")

        return lines.joined(separator: "\n")
    }
}
