import SwiftUI
import KiteKit

struct DataSchemaDesignerSheet: View {
    let onDismiss: () -> Void

    @State private var entities: [SchemaEntity] = DataSchemaDesigner.starterPack
    @State private var selectedEntityId: UUID? = nil
    @State private var codeTab: CodeTarget = .sql
    @State private var isCopied: Bool = false

    enum CodeTarget: String, CaseIterable, Identifiable {
        case sql = "SQL (DDL)"
        case prisma = "Prisma Schema"
        case swiftData = "SwiftData @Model"

        var id: String { rawValue }
    }

    private var activeEntity: SchemaEntity? {
        if let id = selectedEntityId {
            return entities.first(where: { $0.id == id })
        }
        return entities.first
    }

    private var generatedCode: String {
        switch codeTab {
        case .sql:
            return DataSchemaDesigner.generateSQL(entities: entities)
        case .prisma:
            return DataSchemaDesigner.generatePrisma(entities: entities)
        case .swiftData:
            return DataSchemaDesigner.generateSwiftData(entities: entities)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "cylinder.split.1x2.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Конструктор моделей данных и схемы")
                        .font(.headline)
                    Text("Проектирование таблиц и генерация SQL, Prisma или SwiftData для Волны 1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Main Editor Layout
            HSplitView {
                // Left Column: Entities & Fields
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Сущности (Таблицы):")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            addEntity()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Таблица")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }

                    // Entity Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(entities) { entity in
                                Button {
                                    selectedEntityId = entity.id
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "tablecells")
                                        Text(entity.name)
                                        Text("(\(entity.fields.count))")
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.caption.weight(entity.id == (activeEntity?.id ?? UUID()) ? .semibold : .regular))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(entity.id == (activeEntity?.id ?? UUID()) ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // Field Editor for Active Entity
                    if let entity = activeEntity, let entityIdx = entities.firstIndex(where: { $0.id == entity.id }) {
                        HStack {
                            Text("Поля таблицы «\(entity.name)»:")
                                .font(.caption.bold())
                            Spacer()
                            Button {
                                addField(to: entityIdx)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Поле")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }

                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(Array(entities[entityIdx].fields.enumerated()), id: \.element.id) { fieldIdx, field in
                                    HStack(spacing: 8) {
                                        TextField("Имя поля", text: $entities[entityIdx].fields[fieldIdx].name)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 120)

                                        Picker("", selection: $entities[entityIdx].fields[fieldIdx].type) {
                                            ForEach(SchemaField.FieldType.allCases, id: \.self) { t in
                                                Text(t.rawValue).tag(t)
                                            }
                                        }
                                        .frame(width: 112)

                                        Toggle("PK", isOn: $entities[entityIdx].fields[fieldIdx].isPrimaryKey)
                                            .toggleStyle(.checkbox)
                                            .font(.caption2)

                                        Toggle("Opt", isOn: $entities[entityIdx].fields[fieldIdx].isOptional)
                                            .toggleStyle(.checkbox)
                                            .font(.caption2)

                                        Spacer()

                                        Button {
                                            entities[entityIdx].fields.remove(at: fieldIdx)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption2)
                                                .foregroundStyle(Color.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(8)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 400, idealWidth: 440)

                // Right Column: Code Generator
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("", selection: $codeTab) {
                            ForEach(CodeTarget.allCases) { target in
                                Text(target.rawValue).tag(target)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 320)

                        Spacer()

                        Button {
                            copyCode()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано" : "Копировать код")
                            }
                            .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                    }

                    ScrollView {
                        Text(generatedCode)
                            .font(.system(.body, design: .monospaced)) // grid: ok font
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(16)
                .frame(minWidth: 400, idealWidth: 480)
            }

            Divider()

            // Footer
            HStack {
                Button("Сброс к стартовой схеме") {
                    entities = DataSchemaDesigner.starterPack
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Закрыть") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 840, idealWidth: 960, minHeight: 520, idealHeight: 640)
    }

    private func addEntity() {
        let newEntity = SchemaEntity(name: "Entity\(entities.count + 1)", fields: [
            SchemaField(name: "id", type: .uuid, isPrimaryKey: true),
            SchemaField(name: "createdAt", type: .dateTime)
        ])
        entities.append(newEntity)
        selectedEntityId = newEntity.id
    }

    private func addField(to entityIndex: Int) {
        entities[entityIndex].fields.append(
            SchemaField(name: "field\(entities[entityIndex].fields.count + 1)", type: .string)
        )
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedCode, forType: .string)
        isCopied = true
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isCopied = false
        }
    }
}
