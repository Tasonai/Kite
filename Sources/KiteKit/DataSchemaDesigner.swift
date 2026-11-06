import Foundation

public struct SchemaField: Identifiable, Sendable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var type: FieldType
    public var isOptional: Bool
    public var isPrimaryKey: Bool
    public var relationTarget: String?

    public enum FieldType: String, Sendable, CaseIterable, Codable {
        case uuid = "UUID"
        case string = "String"
        case int = "Integer"
        case boolean = "Boolean"
        case dateTime = "DateTime"
        case relation = "Relation"
    }

    public init(
        id: UUID = UUID(),
        name: String,
        type: FieldType,
        isOptional: Bool = false,
        isPrimaryKey: Bool = false,
        relationTarget: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.isPrimaryKey = isPrimaryKey
        self.relationTarget = relationTarget
    }
}

public struct SchemaEntity: Identifiable, Sendable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var fields: [SchemaField]

    public init(id: UUID = UUID(), name: String, fields: [SchemaField] = []) {
        self.id = id
        self.name = name
        self.fields = fields
    }
}

public enum DataSchemaDesigner {
    public static var starterPack: [SchemaEntity] {
        [
            SchemaEntity(
                name: "User",
                fields: [
                    SchemaField(name: "id", type: .uuid, isPrimaryKey: true),
                    SchemaField(name: "email", type: .string),
                    SchemaField(name: "name", type: .string, isOptional: true),
                    SchemaField(name: "createdAt", type: .dateTime)
                ]
            ),
            SchemaEntity(
                name: "Project",
                fields: [
                    SchemaField(name: "id", type: .uuid, isPrimaryKey: true),
                    SchemaField(name: "title", type: .string),
                    SchemaField(name: "userId", type: .relation, relationTarget: "User"),
                    SchemaField(name: "isArchived", type: .boolean),
                    SchemaField(name: "updatedAt", type: .dateTime)
                ]
            )
        ]
    }

    public static func generateSQL(entities: [SchemaEntity]) -> String {
        var lines: [String] = []
        for entity in entities {
            let table = entity.name.lowercased() + "s"
            lines.append("CREATE TABLE IF NOT EXISTS \(table) (")
            var fieldDefs: [String] = []
            for field in entity.fields {
                var def = "    \(field.name) "
                switch field.type {
                case .uuid:
                    def += "TEXT"
                case .string:
                    def += "TEXT"
                case .int:
                    def += "INTEGER"
                case .boolean:
                    def += "INTEGER DEFAULT 0"
                case .dateTime:
                    def += "TIMESTAMP"
                case .relation:
                    def += "TEXT REFERENCES \(field.relationTarget?.lowercased() ?? "users")(id)"
                }
                if field.isPrimaryKey { def += " PRIMARY KEY" }
                if !field.isOptional && !field.isPrimaryKey { def += " NOT NULL" }
                fieldDefs.append(def)
            }
            lines.append(fieldDefs.joined(separator: ",\n"))
            lines.append(");\n")
        }
        return lines.joined(separator: "\n")
    }

    public static func generatePrisma(entities: [SchemaEntity]) -> String {
        var lines: [String] = [
            "datasource db {",
            "  provider = \"sqlite\"",
            "  url      = env(\"DATABASE_URL\")",
            "}",
            "",
            "generator client {",
            "  provider = \"prisma-client-js\"",
            "}",
            ""
        ]

        for entity in entities {
            lines.append("model \(entity.name) {")
            for field in entity.fields {
                var typeStr: String
                switch field.type {
                case .uuid: typeStr = "String"
                case .string: typeStr = "String"
                case .int: typeStr = "Int"
                case .boolean: typeStr = "Boolean"
                case .dateTime: typeStr = "DateTime"
                case .relation: typeStr = field.relationTarget ?? "String"
                }
                if field.isOptional && field.type != .relation { typeStr += "?" }
                var attr = ""
                if field.isPrimaryKey {
                    attr = " @id @default(uuid())"
                } else if field.type == .dateTime && field.name.contains("created") {
                    attr = " @default(now())"
                } else if field.type == .dateTime && field.name.contains("update") {
                    attr = " @updatedAt"
                }
                lines.append("  \(field.name) \(typeStr)\(attr)")
            }
            lines.append("}\n")
        }
        return lines.joined(separator: "\n")
    }

    public static func generateSwiftData(entities: [SchemaEntity]) -> String {
        var lines: [String] = [
            "import Foundation",
            "import SwiftData",
            ""
        ]

        for entity in entities {
            lines.append("@Model")
            lines.append("final class \(entity.name) {")
            for field in entity.fields {
                let typeStr: String
                switch field.type {
                case .uuid: typeStr = "UUID"
                case .string: typeStr = field.isOptional ? "String?" : "String"
                case .int: typeStr = field.isOptional ? "Int?" : "Int"
                case .boolean: typeStr = "Bool"
                case .dateTime: typeStr = field.isOptional ? "Date?" : "Date"
                case .relation: typeStr = field.isOptional ? "\(field.relationTarget ?? "Item")?" : (field.relationTarget ?? "Item")
                }
                let attr = field.isPrimaryKey ? "@Attribute(.unique) " : ""
                lines.append("    \(attr)var \(field.name): \(typeStr)")
            }
            lines.append("}")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
