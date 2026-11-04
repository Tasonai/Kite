import SwiftUI
import KiteKit

struct ScreenSnipButton: View {
    var onHidePanel: (() -> Void)?
    var onRestorePanel: (() -> Void)?
    var onCaptured: (URL, String) -> Void
    
    @State private var isCapturing = false
    
    var body: some View {
        Button {
            triggerCapture()
        } label: {
            HStack(spacing: 4) {
                if isCapturing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 13, weight: .medium))
                }
                
                Text("Снимок")
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.12))
            .foregroundStyle(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isCapturing)
        .help("Интерактивный захват области экрана с оптическим распознаванием текста (Vision OCR)")
    }
    
    private func triggerCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        
        Task {
            let result = await ScreenSnipService.captureInteractive(
                hideWindow: onHidePanel,
                restoreWindow: onRestorePanel
            )
            
            await MainActor.run {
                isCapturing = false
                if let (url, text) = result {
                    onCaptured(url, text)
                }
            }
        }
    }
}
