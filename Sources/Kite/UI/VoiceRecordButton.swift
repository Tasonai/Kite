import SwiftUI
import KiteKit

struct VoiceRecordButton: View {
    @State private var voice = VoiceCaptureManager.shared
    var onTranscript: @MainActor (String) -> Void

    var body: some View {
        Button {
            voice.toggleRecording { text in
                Task { @MainActor in
                    onTranscript(text)
                }
            }
        } label: {
            HStack(spacing: 4) {
                if voice.isRecording {
                    HStack(spacing: 2) {
                        ForEach(0..<4) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.red)
                                .frame(width: 2, height: CGFloat(8 + (i % 2 == 0 ? 8 : 4) * Int(voice.audioLevel * 3)))
                        }
                    }
                    .frame(height: 16)

                    Text("Слушаю...")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.red)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(voice.isRecording ? Color.red.opacity(0.15) : Color.secondary.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(voice.isRecording ? "Остановить запись" : "Голосовой ввод идеи (микрофон)")
    }
}
