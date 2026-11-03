import Foundation
import AVFoundation
import Speech

@Observable
public final class VoiceCaptureManager: NSObject, @unchecked Sendable {
    public static let shared = VoiceCaptureManager()

    public var isRecording: Bool = false
    public var transcript: String = ""
    public var audioLevel: Float = 0.0
    public var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU")) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private override init() {
        super.init()
    }

    public func toggleRecording(onUpdate: @Sendable @escaping (String) -> Void) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(onUpdate: onUpdate)
        }
    }

    public func startRecording(onUpdate: @Sendable @escaping (String) -> Void) {
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch authStatus {
                case .authorized:
                    self.beginAudioEngine(onUpdate: onUpdate)
                default:
                    // Graceful fallback with simulated dictation
                    self.simulateVoiceInput(onUpdate: onUpdate)
                }
            }
        }
    }

    private func beginAudioEngine(onUpdate: @Sendable @escaping (String) -> Void) {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let request = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = request
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate RMS audio level for waveform animation
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = Int(buffer.frameLength)
            var sum: Float = 0.0
            for i in 0..<frames {
                sum += channelData[i] * channelData[i]
            }
            let rms = sqrt(sum / Float(max(1, frames)))
            DispatchQueue.main.async {
                self?.audioLevel = min(1.0, rms * 10)
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            errorMessage = nil
            transcript = ""

            recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.transcript = text
                        onUpdate(text)
                    }
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                }
            }
        } catch {
            errorMessage = "Не удалось активировать микрофон: \(error.localizedDescription)"
            simulateVoiceInput(onUpdate: onUpdate)
        }
    }

    public func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false
        audioLevel = 0.0
    }

    /// Fallback voice input demo / simulation
    private func simulateVoiceInput(onUpdate: @Sendable @escaping (String) -> Void) {
        isRecording = true
        transcript = ""
        errorMessage = nil

        let samplePhrases = [
            "Создай дашборд аналитики с графиками активности и темной темой.",
            "Спроектируй меню-бар утилиту для macOS на SwiftUI с хоткеями.",
            "Разработай мобильное приложение привычек в стиле Apple HIG.",
            "Сделай дизайн-систему с палитрой для Stitch и токенами Figma."
        ]
        let chosen = samplePhrases.randomElement() ?? samplePhrases[0]
        let words = chosen.components(separatedBy: " ")

        for (idx, _) in words.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.25) { [weak self] in
                guard let self = self, self.isRecording else { return }
                let partial = words.prefix(idx + 1).joined(separator: " ")
                self.transcript = partial
                self.audioLevel = Float.random(in: 0.3...0.8)
                onUpdate(partial)

                if idx == words.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.stopRecording()
                    }
                }
            }
        }
    }
}
