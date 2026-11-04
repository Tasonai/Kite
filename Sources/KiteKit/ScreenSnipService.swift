import AppKit
import Foundation
import Vision

public enum ScreenSnipService {
    public static func captureInteractive(hideWindow: (() -> Void)? = nil, restoreWindow: (() -> Void)? = nil) async -> (imageURL: URL, recognizedText: String)? {
        let capturesDir = URL.applicationSupportDirectory
            .appending(path: "Kite", directoryHint: .isDirectory)
            .appending(path: "Captures", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: capturesDir, withIntermediateDirectories: true)
        
        let fileURL = capturesDir.appending(path: "snip_\(UUID().uuidString).png")
        
        await MainActor.run {
            hideWindow?()
        }
        
        // Give macOS window server a brief moment to clear the overlay
        try? await Task.sleep(for: .milliseconds(150))
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-s", fileURL.path]
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            await MainActor.run {
                restoreWindow?()
            }
            return nil
        }
        
        await MainActor.run {
            restoreWindow?()
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let nsImage = NSImage(contentsOf: fileURL),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let recognized = await recognizeText(in: cgImage)
        return (fileURL, recognized)
    }
    
    public static func recognizeText(in image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ru-RU", "en-US"]
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}
