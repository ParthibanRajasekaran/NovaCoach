import Foundation
#if canImport(Speech)
import Speech
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

@MainActor
protocol SpeechTranscribing {
    func transcribeAudio(at url: URL) async throws -> String
}

@MainActor
protocol SpeechSynthesizing {
    func speak(_ text: String) async
}

final class SpeechService: SpeechTranscribing, SpeechSynthesizing {
    func transcribeAudio(at url: URL) async throws -> String {
        #if canImport(Speech)
        let recognizer = SFSpeechRecognizer()
        guard let recognizer else { return "" }
        let request = SFSpeechURLRecognitionRequest(url: url)
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let transcription = result?.bestTranscription.formattedString, result?.isFinal == true {
                    continuation.resume(returning: transcription)
                }
            }
        }
        #else
        _ = url
        return ""
        #endif
    }

    func speak(_ text: String) async {
        #if canImport(AVFoundation)
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
        #else
        _ = text
        #endif
    }
}
