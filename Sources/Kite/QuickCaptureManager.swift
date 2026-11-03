import AppKit
import Carbon
import SwiftData
import SwiftUI

@MainActor
final class QuickCaptureManager: NSObject {
    static let shared = QuickCaptureManager()
    
    private var panel: NSPanel?
    private var hotKeyRef: EventHotKeyRef?
    private weak var appModel: AppModel?
    private var isRegistered = false
    
    func start(model: AppModel) {
        self.appModel = model
        setupGlobalHotkey()
    }
    
    func toggle() {
        if let panel = panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        guard let model = appModel else { return }
        
        if panel == nil {
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 280),
                styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.isFloatingPanel = true
            p.level = .floating
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.titleVisibility = .hidden
            p.titlebarAppearsTransparent = true
            p.isMovableByWindowBackground = true
            p.backgroundColor = .clear
            p.isOpaque = false
            p.hasShadow = true
            
            let hosting = NSHostingView(
                rootView: QuickCaptureView(onDismiss: { [weak self] in
                    self?.hide()
                })
                .environment(model)
                .modelContainer(model.container)
                .themed()
            )
            p.contentView = hosting
            self.panel = p
        } else {
            // Re-render fresh view to reset fields
            let hosting = NSHostingView(
                rootView: QuickCaptureView(onDismiss: { [weak self] in
                    self?.hide()
                })
                .environment(model)
                .modelContainer(model.container)
                .themed()
            )
            panel?.contentView = hosting
        }
        
        guard let panel = panel else { return }
        
        // Position panel at top third of the main screen (Spotlight-style)
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 290
            let y = screenRect.midY + 60
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            panel.center()
        }
        
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        panel?.orderOut(nil)
    }
    
    private func setupGlobalHotkey() {
        guard !isRegistered else { return }
        isRegistered = true
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x4B495445), id: 1) // 'KITE'
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            if hkID.signature == OSType(0x4B495445) && hkID.id == 1 {
                DispatchQueue.main.async {
                    QuickCaptureManager.shared.toggle()
                }
            }
            return noErr
        }, 1, &eventType, nil, nil)
        
        // Command + Shift + K
        RegisterEventHotKey(UInt32(kVK_ANSI_K), UInt32(cmdKey | shiftKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
