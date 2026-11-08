import Foundation

public struct ProjectArtifactSummary: Sendable, Hashable {
    public let relativePath: String
    public let category: String
    public let waveIndex: Int

    public init(relativePath: String, category: String, waveIndex: Int) {
        self.relativePath = relativePath
        self.category = category
        self.waveIndex = waveIndex
    }
}

public struct ProjectProgressSnapshot: Sendable {
    public let watchedPath: String
    public let completedTaskKeys: Set<String>
    public let detectedArtifacts: [ProjectArtifactSummary]
    public let wavePercentages: [Int: Int]
    public let overallPercentage: Int

    public init(
        watchedPath: String,
        completedTaskKeys: Set<String>,
        detectedArtifacts: [ProjectArtifactSummary],
        wavePercentages: [Int: Int],
        overallPercentage: Int
    ) {
        self.watchedPath = watchedPath
        self.completedTaskKeys = completedTaskKeys
        self.detectedArtifacts = detectedArtifacts
        self.wavePercentages = wavePercentages
        self.overallPercentage = overallPercentage
    }
}

public enum ProjectWatcherService {
    public static func analyzeDirectory(
        at url: URL,
        waves: [AntigravityWave]
    ) -> ProjectProgressSnapshot {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            return ProjectProgressSnapshot(
                watchedPath: url.path,
                completedTaskKeys: [],
                detectedArtifacts: [],
                wavePercentages: [1: 0, 2: 0, 3: 0, 4: 0],
                overallPercentage: 0
            )
        }

        var detectedArtifacts: [ProjectArtifactSummary] = []
        var detectedRelativePaths = Set<String>()

        if let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            let basePath = url.standardizedFileURL.path
            for case let fileURL as URL in enumerator {
                let path = fileURL.standardizedFileURL.path
                guard path.hasPrefix(basePath) else { continue }
                var rel = String(path.dropFirst(basePath.count))
                if rel.hasPrefix("/") { rel.removeFirst() }

                // Skip vendor directories
                let topComponent = rel.split(separator: "/").first.map(String.init) ?? ""
                if topComponent == "node_modules" ||
                   topComponent == ".git" ||
                   topComponent == ".build" ||
                   topComponent == "bin" ||
                   topComponent == "obj" ||
                   topComponent == "target" ||
                   topComponent == "dist" {
                    enumerator.skipDescendants()
                    continue
                }

                // Limit deep scan to 4 directory levels
                let depth = rel.split(separator: "/").count
                if depth > 4 {
                    enumerator.skipDescendants()
                    continue
                }

                detectedRelativePaths.insert(rel.lowercased())

                // Categorize well-known artifacts
                let lower = rel.lowercased()
                if lower.hasSuffix(".prisma") || lower.hasSuffix("schema.sql") || lower.hasSuffix("package.json") || lower.hasSuffix("cargo.toml") {
                    detectedArtifacts.append(ProjectArtifactSummary(relativePath: rel, category: "Foundation & Schema", waveIndex: 1))
                } else if lower.contains("/api/") || lower.contains("/services/") || lower.contains("/server/") || lower.contains("/routes/") {
                    detectedArtifacts.append(ProjectArtifactSummary(relativePath: rel, category: "Backend Services", waveIndex: 2))
                } else if lower.contains("/components/") || lower.contains("/pages/") || lower.contains("/views/") || lower.hasSuffix(".xaml") {
                    detectedArtifacts.append(ProjectArtifactSummary(relativePath: rel, category: "UI Components", waveIndex: 3))
                } else if lower.contains("/tests/") || lower.contains("/test/") || lower.contains("__tests__") || lower.contains(".github/workflows") {
                    detectedArtifacts.append(ProjectArtifactSummary(relativePath: rel, category: "Tests & QA", waveIndex: 4))
                }
            }
        }

        var completedTaskKeys: Set<String> = []
        var wavePercentages: [Int: Int] = [:]

        for wave in waves {
            let totalTasks = wave.scope.count
            guard totalTasks > 0 else {
                wavePercentages[wave.id] = 0
                continue
            }

            var waveCompletedCount = 0
            for task in wave.scope {
                let taskKey = "\(task)_\(wave.id)"
                if matchesTask(taskText: task, waveId: wave.id, detectedPaths: detectedRelativePaths) {
                    completedTaskKeys.insert(taskKey)
                    waveCompletedCount += 1
                }
            }

            let pct = Int((Double(waveCompletedCount) / Double(totalTasks)) * 100.0)
            wavePercentages[wave.id] = min(100, max(0, pct))
        }

        let totalExpectedTasks = waves.reduce(0) { $0 + $1.scope.count }
        let overall = totalExpectedTasks > 0 ? Int((Double(completedTaskKeys.count) / Double(totalExpectedTasks)) * 100.0) : 0

        return ProjectProgressSnapshot(
            watchedPath: url.path,
            completedTaskKeys: completedTaskKeys,
            detectedArtifacts: detectedArtifacts,
            wavePercentages: wavePercentages,
            overallPercentage: min(100, max(0, overall))
        )
    }

    private static func matchesTask(
        taskText: String,
        waveId: Int,
        detectedPaths: Set<String>
    ) -> Bool {
        let lower = taskText.lowercased()

        switch waveId {
        case 1:
            // Foundation, Config, Schema, DB
            if lower.contains("schema") || lower.contains("prisma") || lower.contains("бд") || lower.contains("баз") {
                return detectedPaths.contains { $0.contains("schema") || $0.contains("prisma") || $0.contains("sql") || $0.contains("migrations") }
            }
            if lower.contains("типы") || lower.contains("модели") || lower.contains("model") || lower.contains("type") {
                return detectedPaths.contains { $0.contains("types") || $0.contains("models") || $0.contains("model") }
            }
            if lower.contains("проект") || lower.contains("каркас") || lower.contains("конфиг") || lower.contains("config") {
                return detectedPaths.contains { $0.contains("package.json") || $0.contains("tsconfig") || $0.contains("cargo.toml") || $0.contains("package.swift") }
            }
            return detectedPaths.contains { $0.contains("package.json") || $0.contains("schema") || $0.contains("src") }

        case 2:
            // Core Domain, API, Services
            if lower.contains("auth") || lower.contains("авториз") || lower.contains("безопасн") || lower.contains("токен") {
                return detectedPaths.contains { $0.contains("auth") || $0.contains("jwt") || $0.contains("guard") || $0.contains("session") }
            }
            if lower.contains("api") || lower.contains("роут") || lower.contains("route") || lower.contains("endpoint") {
                return detectedPaths.contains { $0.contains("api") || $0.contains("routes") || $0.contains("controllers") || $0.contains("endpoints") }
            }
            if lower.contains("сервис") || lower.contains("service") || lower.contains("логик") {
                return detectedPaths.contains { $0.contains("services") || $0.contains("server") || $0.contains("core") }
            }
            return detectedPaths.contains { $0.contains("api") || $0.contains("services") || $0.contains("controllers") || $0.contains("server") }

        case 3:
            // Frontend, UI, Forms, Screens
            if lower.contains("компонент") || lower.contains("ui") || lower.contains("кнопк") || lower.contains("виджет") {
                return detectedPaths.contains { $0.contains("components") || $0.contains("widgets") || $0.contains("ui") }
            }
            if lower.contains("экран") || lower.contains("страниц") || lower.contains("page") || lower.contains("view") {
                return detectedPaths.contains { $0.contains("pages") || $0.contains("views") || $0.contains("app") }
            }
            if lower.contains("состояни") || lower.contains("state") || lower.contains("стил") || lower.contains("theme") {
                return detectedPaths.contains { $0.contains("hooks") || $0.contains("store") || $0.contains("styles") || $0.contains("css") }
            }
            return detectedPaths.contains { $0.contains("components") || $0.contains("pages") || $0.contains("views") || $0.contains("src") }

        case 4:
            // Tests, CI/CD, Deployment, Docs
            if lower.contains("тест") || lower.contains("test") || lower.contains("unit") || lower.contains("e2e") {
                return detectedPaths.contains { $0.contains("test") || $0.contains("spec") || $0.contains("e2e") }
            }
            if lower.contains("ci") || lower.contains("deploy") || lower.contains("docker") || lower.contains("workflow") {
                return detectedPaths.contains { $0.contains(".github") || $0.contains("docker") || $0.contains("deploy") || $0.contains("workflows") }
            }
            if lower.contains("документ") || lower.contains("readme") || lower.contains("инструкц") {
                return detectedPaths.contains { $0.contains("readme") || $0.contains("antigravity.md") || $0.contains("docs") }
            }
            return detectedPaths.contains { $0.contains("test") || $0.contains(".github") || $0.contains("docker") || $0.contains("readme") }

        default:
            return false
        }
    }
}
