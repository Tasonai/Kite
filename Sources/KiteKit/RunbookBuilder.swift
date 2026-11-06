import Foundation

public struct RunbookCommand: Identifiable, Sendable, Equatable {
    public var id: String { name }
    public var name: String
    public var command: String
    public var description: String
    public var phase: String

    public init(name: String, command: String, description: String, phase: String) {
        self.name = name
        self.command = command
        self.description = description
        self.phase = phase
    }
}

public enum RunbookBuilder {
    public static var starterCommands: [RunbookCommand] {
        [
            RunbookCommand(
                name: "Установка окружения",
                command: "npm install",
                description: "Установка минимальных зависимостей без bloat-пакетов",
                phase: "Setup"
            ),
            RunbookCommand(
                name: "Локальный dev-сервер",
                command: "npm run dev",
                description: "Запуск локального сервера с Hot Module Replacement (HMR)",
                phase: "Development"
            ),
            RunbookCommand(
                name: "Накатывание сид-данных",
                command: "npx tsx scripts/seed.ts",
                description: "Заполнение локальной базы или мока реалистичными записями",
                phase: "Data"
            ),
            RunbookCommand(
                name: "Прогон E2E тестов",
                command: "npx playwright test",
                description: "Запуск автоматических приемочных тестов для верификации",
                phase: "Verification"
            ),
            RunbookCommand(
                name: "Продакшн сборка",
                command: "npm run build",
                description: "Компиляция оптимизированного бандла без ошибок типов",
                phase: "Production"
            ),
            RunbookCommand(
                name: "Сброс кэша и чистка",
                command: "rm -rf dist node_modules/.vite .next",
                description: "Очистка временных файлов при возникновении трудноуловимых сбоев",
                phase: "Maintenance"
            )
        ]
    }

    public static func generateRunbookMarkdown(title: String, commands: [RunbookCommand]) -> String {
        var lines: [String] = [
            "# DEVELOPER RUNBOOK: \(title.uppercased())",
            "Official terminal commands and runbook for Google DeepMind Antigravity execution.",
            ""
        ]

        for (idx, cmd) in commands.enumerated() {
            lines.append("### \(idx + 1). \(cmd.name) [\(cmd.phase)]")
            lines.append("```bash")
            lines.append(cmd.command)
            lines.append("```")
            lines.append("\(cmd.description)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePackageJsonScripts(commands: [RunbookCommand]) -> String {
        """
        {
          "scripts": {
            "dev": "vite",
            "build": "tsc && vite build",
            "preview": "vite preview",
            "test": "playwright test",
            "db:seed": "tsx scripts/seed.ts",
            "clean": "rm -rf dist node_modules/.vite"
          }
        }
        """
    }

    public static func generateMakefile(commands: [RunbookCommand]) -> String {
        """
        .PHONY: install dev test build clean

        install:
        \tnpm install

        dev:
        \tnpm run dev

        test:
        \tnpx playwright test

        build:
        \tnpm run build

        clean:
        \trm -rf dist node_modules/.vite
        """
    }
}
