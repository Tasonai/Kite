import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    
    @Query(sort: \Item.createdAt, order: .reverse) private var allItems: [Item]
    
    @State private var quickTitle: String = ""
    @State private var selectedFilter: String = "all"
    @State private var copiedId: PersistentIdentifier?
    
    private var filteredItems: [Item] {
        switch selectedFilter {
        case "in_progress":
            return allItems.filter { $0.status == "in_progress" }
        case "backlog":
            return allItems.filter { $0.status == "backlog" }
        default:
            return allItems
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.headline)
                
                Text("Kite")
                    .font(.headline)
                
                Spacer()
                
                Text("\(allItems.count) идей")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                
                Button {
                    QuickCaptureManager.shared.show()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Открыть окно быстрого захвата (⌘⇧K)")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Inline Quick Add Field
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Быстро записать идею... (⏎)", text: $quickTitle)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .onSubmit {
                        submitQuickIdea()
                    }
                
                if !quickTitle.isEmpty {
                    Button {
                        submitQuickIdea()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Filter Pills
            HStack(spacing: 8) {
                filterPill("Все", tag: "all", count: allItems.count)
                filterPill("В планах", tag: "backlog", count: allItems.filter { $0.status == "backlog" }.count)
                filterPill("В работе", tag: "in_progress", count: allItems.filter { $0.status == "in_progress" }.count)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider()
            
            // Recent Ideas List
            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text("Нет идей в этой категории")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredItems.prefix(6)) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(statusColor(item.status))
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 8) {
                                        Text(item.platform)
                                            .font(.system(size: 9, weight: .semibold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.12))
                                            .clipShape(Capsule())
                                        
                                        if !item.concept.isEmpty {
                                            Text(item.concept)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Quick Copy Blueprint Button
                                Button {
                                    copyBlueprint(for: item)
                                } label: {
                                    Image(systemName: copiedId == item.id ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(copiedId == item.id ? Color.green : Color.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Скопировать блупринт для Antigravity")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                openItemInMain(item)
                            }
                            .hoverEffect()
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 224)
            }
            
            Divider()
            
            // Footer Actions
            HStack(spacing: 12) {
                Button {
                    openMainWindow()
                } label: {
                    Label("Главное окно", systemImage: "macwindow")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                Button {
                    openSettings()
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Настройки")
                
                Button("Завершить") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 360)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func filterPill(_ title: String, tag: String, count: Int) -> some View {
        Button {
            selectedFilter = tag
        } label: {
            Text("\(title) \(count)")
                .font(.system(size: 10, weight: selectedFilter == tag ? .semibold : .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedFilter == tag ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                .foregroundStyle(selectedFilter == tag ? Color.accentColor : Color.secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "completed": return .green
        case "in_progress": return .blue
        default: return .secondary
        }
    }
    
    private func submitQuickIdea() {
        let clean = ItemTitle.clean(quickTitle)
        guard !clean.isEmpty else { return }
        
        let item = Item(title: clean)
        context.insert(item)
        try? context.save()
        model.selection = item.id
        quickTitle = ""
        NSSound.beep()
    }
    
    private func copyBlueprint(for item: Item) {
        let prompt = PromptCompiler.compileBlueprint(
            title: item.title,
            concept: item.concept,
            platform: item.platform,
            style: item.style
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        copiedId = item.id
        NSSound.beep()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedId == item.id {
                copiedId = nil
            }
        }
    }
    
    private func openItemInMain(_ item: Item) {
        model.selection = item.id
        openMainWindow()
    }
    
    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

private extension View {
    func hoverEffect() -> some View {
        modifier(HoverModifier())
    }
}

private struct HoverModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.secondary.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onHover { isHovered = $0 }
    }
}
