import AppKit
import SwiftData
import SwiftUI
import KiteKit

struct QuickCaptureView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    
    var onDismiss: () -> Void = {}
    
    @State private var title: String = ""
    @State private var concept: String = ""
    @State private var platform: String = "Web"
    @State private var style: String = "Editorial & Swiss Modern"
    @State private var showSavedToast: Bool = false
    @FocusState private var isTitleFocused: Bool
    
    private let platforms = ["Web", "Mobile", "Desktop"]
    private let styles = [
        "Editorial & Swiss Modern",
        "Linear & DevTool Cockpit",
        "Neo-Brutalism & Tactical",
        "Voxel & 3D Isometric"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.headline)
                
                Text("Быстрый захват идеи")
                    .font(.headline)
                
                Spacer()
                
                Text("⌘⇧K")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
            
            // Title Input
            TextField("Название идеи (например, Minimalist Markdown Reader)...", text: $title)
                .font(.title3.weight(.medium))
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .onSubmit {
                    saveAndClose(copyBlueprint: false)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            
            // Concept Input
            TextEditor(text: $concept)
                .font(.body)
                .frame(minHeight: 64, maxHeight: 90)
                .padding(6)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    if concept.isEmpty {
                        Text("Краткое описание, JTBD или фичи (необязательно)...")
                            .font(.body)
                            .foregroundStyle(.secondary.opacity(0.7))
                            .padding(.top, 10)
                            .padding(.leading, 10)
                            .allowsHitTesting(false)
                    }
                }
            
            // Controls: Platform & Style
            HStack(spacing: 12) {
                // Platform segmented
                HStack(spacing: 4) {
                    ForEach(platforms, id: \.self) { p in
                        Button {
                            platform = p
                        } label: {
                            Text(p)
                                .font(.caption.weight(platform == p ? .semibold : .regular))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(platform == p ? Color.accentColor : Color.secondary.opacity(0.1))
                                .foregroundStyle(platform == p ? Color.white : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                Picker("", selection: $style) {
                    ForEach(styles, id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 220)
            }
            
            Divider()
            
            // Footer & Actions
            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    Text("⎋ Esc отмена")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("⏎ сохранить")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("⌘⏎ в буфер (/plan)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Отмена") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Button {
                    saveAndClose(copyBlueprint: true)
                } label: {
                    Label("В буфер 🪄", systemImage: "sparkles")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                
                Button {
                    saveAndClose(copyBlueprint: false)
                } label: {
                    Text("Сохранить")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 580)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 12)
        .onAppear {
            isTitleFocused = true
        }
    }
    
    private func saveAndClose(copyBlueprint: Bool) {
        let cleanTitle = ItemTitle.clean(title)
        guard !cleanTitle.isEmpty else { return }
        
        let item = Item(title: cleanTitle)
        item.concept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        item.platform = platform
        item.style = style
        item.status = "backlog"
        
        if copyBlueprint {
            let prompt = PromptCompiler.compileBlueprint(
                title: item.title,
                concept: item.concept,
                platform: item.platform,
                style: item.style
            )
            item.generatedPrompt = prompt
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(prompt, forType: .string)
            NSSound.beep()
        }
        
        context.insert(item)
        try? context.save()
        model.selection = item.id
        
        onDismiss()
    }
}
