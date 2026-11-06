import Foundation

public struct DiagnosedError: Identifiable, Sendable {
    public var id: String
    public var category: ErrorCategory
    public var title: String
    public var rootCause: String
    public var targetFile: String?
    public var lineNumber: Int?
    public var surgicalFixPrompt: String

    public enum ErrorCategory: String, Sendable, CaseIterable {
        case missingDependency = "Отсутствующая зависимость"
        case typeOrSyntax = "Ошибка типизации или синтаксиса"
        case nilOrCrash = "Обращение к пустому значению (Crash)"
        case networkOrCors = "Сетевой сбой или CORS"
        case environmentVar = "Отсутствует переменная окружения"
        case generic = "Общая системная ошибка"
    }

    public init(
        id: String = UUID().uuidString,
        category: ErrorCategory,
        title: String,
        rootCause: String,
        targetFile: String? = nil,
        lineNumber: Int? = nil,
        surgicalFixPrompt: String
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.rootCause = rootCause
        self.targetFile = targetFile
        self.lineNumber = lineNumber
        self.surgicalFixPrompt = surgicalFixPrompt
    }
}

public enum VibeErrorDoctor {
    public static func diagnose(rawLog: String) -> DiagnosedError {
        let trimmed = rawLog.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        // 1. Extract file and line if present
        let (extractedFile, extractedLine) = extractFileAndLine(from: trimmed)

        // 2. Pattern Matching
        if lower.contains("cannot find module") || lower.contains("no such module") || lower.contains("modulenotfounderror") || lower.contains("unresolved external") {
            let depName = extractMissingModuleName(from: trimmed)
            let fileRef = extractedFile != nil ? " в файле \(extractedFile!)" : ""
            let prompt = """
            [ANTIGRAVITY SURGICAL FIX]
            Проблема: Отсутствует зависимость/модуль "\(depName)"\(fileRef).
            
            СТРОГОЕ ПРАВИЛО:
            - Не переписывай архитектуру и другие файлы.
            - Установи/подключи недостающий модуль одной точной командой или добавь корректный import.
            - Покажи только команду установки или минимальный патч импорта.
            """

            return DiagnosedError(
                category: .missingDependency,
                title: "Не найден модуль: \(depName)",
                rootCause: "Код ссылается на библиотеку или локальный файл, который не установлен или не найден по указанному пути.",
                targetFile: extractedFile,
                lineNumber: extractedLine,
                surgicalFixPrompt: prompt
            )
        }

        if lower.contains("cors") || lower.contains("access-control-allow-origin") {
            let prompt = """
            [ANTIGRAVITY SURGICAL FIX]
            Проблема: Ошибка CORS (Cross-Origin Resource Sharing).
            
            СТРОГОЕ ПРАВИЛО:
            - Добавь заголовки Access-Control-Allow-Origin: * (или локальный origin фронтенда) в API-обработчик.
            - Не меняй структуру данных и клиентские запросы.
            - Измени только конфигурацию роутера/CORS middleware.
            """

            return DiagnosedError(
                category: .networkOrCors,
                title: "Блокировка CORS в браузере",
                rootCause: "Браузер заблокировал запрос от фронтенда к бэкенду из-за отсутствия CORS-заголовков в ответе сервера.",
                targetFile: extractedFile,
                lineNumber: extractedLine,
                surgicalFixPrompt: prompt
            )
        }

        if lower.contains("process.env.") || lower.contains("keyerror") || lower.contains("env") && lower.contains("undefined") {
            let prompt = """
            [ANTIGRAVITY SURGICAL FIX]
            Проблема: Не задана обязательная переменная окружения (Environment Variable).
            
            СТРОГОЕ ПРАВИЛО:
            - Создай или обнови файл .env.example с указанием недостающей переменной.
            - Добавь безопасное fallback-значение или понятную ошибку инициализации вместо падения процесса.
            """

            return DiagnosedError(
                category: .environmentVar,
                title: "Отсутствует переменная в .env",
                rootCause: "Приложение попыталось прочитать ключ конфигурации или API-токен из переменных окружения, но значение пусто.",
                targetFile: extractedFile,
                lineNumber: extractedLine,
                surgicalFixPrompt: prompt
            )
        }

        if lower.contains("fatal error") || lower.contains("unexpectedly found nil") || lower.contains("nullpointerexception") || lower.contains("typeerror: cannot read properties of undefined") || lower.contains("typeerror: undefined is not an object") {
            let location = locationDescription(file: extractedFile, line: extractedLine)
            let prompt = """
            [ANTIGRAVITY SURGICAL FIX]
            Проблема: Обращение к несуществующему (nil/null) объекту\(location).
            
            СТРОГОЕ ПРАВИЛО:
            - Добавь опциональную цепочку (optional chaining '?') или guard/if проверку на null перед чтением поля.
            - Не удаляй существующую бизнес-логику.
            - Исправь только опасное место чтения.
            """

            return DiagnosedError(
                category: .nilOrCrash,
                title: "Падение из-за nil/null значения",
                rootCause: "Код попытался прочитать свойство у переменной, которая оказалась null или undefined во время выполнения.",
                targetFile: extractedFile,
                lineNumber: extractedLine,
                surgicalFixPrompt: prompt
            )
        }

        if lower.contains("error:") || lower.contains("syntaxerror") || lower.contains("cannot convert value of type") || lower.contains("type mismatch") {
            let location = locationDescription(file: extractedFile, line: extractedLine)
            let prompt = """
            [ANTIGRAVITY SURGICAL FIX]
            Проблема: Ошибка компилятора или типизации\(location).
            
            ЛОГ ОШИБКИ:
            \(trimmed.components(separatedBy: "\n").prefix(6).joined(separator: "\n"))
            
            СТРОГОЕ ПРАВИЛО:
            - Исправь только указанную строку и тип данных.
            - Не добавляй новых библиотек.
            - Выполни проверку компиляции и выведи только измененный фрагмент кода.
            """

            return DiagnosedError(
                category: .typeOrSyntax,
                title: "Ошибка типизации или синтаксиса",
                rootCause: "Компилятор или интерпретатор обнаружил несовпадение типов аргументов или синтаксическую неточность.",
                targetFile: extractedFile,
                lineNumber: extractedLine,
                surgicalFixPrompt: prompt
            )
        }

        // Generic Fallback
        let location = locationDescription(file: extractedFile, line: extractedLine)
        let prompt = """
        [ANTIGRAVITY SURGICAL FIX]
        Проблема: Сбой сборки или выполнения\(location).
        
        ЛОГ ОШИБКИ:
        \(trimmed.components(separatedBy: "\n").prefix(8).joined(separator: "\n"))
        
        СТРОГОЕ ПРАВИЛО (ЭКОНОМИЯ ТОКЕНОВ):
        1. Локализуй точную причину сбоя.
        2. Измени минимум строк кода.
        3. Не меняй файлы, которые не связаны с ошибкой.
        4. Дай команду проверки исправления.
        """

        return DiagnosedError(
            category: .generic,
            title: "Сбой сборки или выполнения",
            rootCause: "Обнаружена ошибка выполнения. Проверьте лог терминала и примените точечный патч.",
            targetFile: extractedFile,
            lineNumber: extractedLine,
            surgicalFixPrompt: prompt
        )
    }

    private static func locationDescription(file: String?, line: Int?) -> String {
        guard let f = file else { return "" }
        if let l = line {
            return " в файле \(f) на строке \(l)"
        }
        return " в файле \(f)"
    }

    private static func extractMissingModuleName(from log: String) -> String {
        let patterns = [
            "Cannot find module ['\"]([^'\"]+)['\"]",
            "No such module ['\"]?([a-zA-Z0-9_]+)['\"]?",
            "ModuleNotFoundError: No module named ['\"]([^'\"]+)['\"]"
        ]

        for pat in patterns {
            if let regex = try? NSRegularExpression(pattern: pat, options: []),
               let match = regex.firstMatch(in: log, options: [], range: NSRange(location: 0, length: log.utf16.count)) {
                if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: log) {
                    return String(log[range])
                }
            }
        }
        return "неизвестный модуль"
    }

    private static func extractFileAndLine(from log: String) -> (String?, Int?) {
        // Matches paths like /path/to/file.swift:42:15 or src/index.ts:18
        let pattern = "([a-zA-Z0-9_\\-\\./\\\\]+\\.[a-zA-Z0-9]+):([0-9]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: log, options: [], range: NSRange(location: 0, length: log.utf16.count)) {
            var file: String? = nil
            var line: Int? = nil

            if let r1 = Range(match.range(at: 1), in: log) {
                file = URL(fileURLWithPath: String(log[r1])).lastPathComponent
            }
            if let r2 = Range(match.range(at: 2), in: log) {
                line = Int(log[r2])
            }
            return (file, line)
        }
        return (nil, nil)
    }
}
