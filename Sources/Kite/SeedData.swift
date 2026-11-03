import Foundation
import SwiftData

@MainActor
enum SeedData {
    static func insertIfRequested(into model: AppModel) {
        guard ProcessInfo.processInfo.environment["APP_SEED"] == "1" else { return }
        guard Store.isOverridden else {
            print("APP_SEED ignored: APP_STORE must be a file in /tmp")
            return
        }
        let context = model.container.mainContext
        guard ((try? context.fetchCount(FetchDescriptor<Item>())) ?? 0) == 0 else { return }
        let samples: [(String, String, String, String, String, Bool)] = [
            (
                "AI DevTool Cockpit & Agent Monitor",
                "Десктопный пульт для мониторинга локальных LLM и очередей фоновых агентов с тёмной темой и хоткеями.",
                "Desktop",
                "Linear & DevTool Cockpit",
                "in_progress",
                true
            ),
            (
                "Минималистичный ридер лонгридов",
                "Швейцарский типографический ридер с чистой сеткой, акцидентной антиквой и офлайн-кэшированием.",
                "Web",
                "Editorial & Swiss Modern",
                "backlog",
                false
            ),
            (
                "Тактический трекер привычек",
                "Необруталистичный трекер с жирными рамками, контрастными бейджами и тактильным звуковым откликом.",
                "Mobile",
                "Neo-Brutalism & Tactical",
                "completed",
                true
            ),
            (
                "Изометрический 3D-конструктор сцен",
                "Воксельный редактор карточек и пространственных интерфейсов с мягким рассеянным светом.",
                "Web",
                "Voxel & 3D Isometric",
                "backlog",
                false
            )
        ]

        for (index, sample) in samples.enumerated() {
            let item = Item(title: sample.0)
            item.concept = sample.1
            item.platform = sample.2
            item.style = sample.3
            item.status = sample.4
            item.isStarred = sample.5
            item.createdAt = Date.now.addingTimeInterval(Double(-index) * 3_600)
            context.insert(item)
        }
        try? context.save()
    }
}
