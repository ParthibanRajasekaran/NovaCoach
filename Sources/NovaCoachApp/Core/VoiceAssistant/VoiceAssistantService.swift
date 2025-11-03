import Foundation
#if canImport(OSLog)
import OSLog
#endif
#if canImport(Porcupine)
import Porcupine
#endif

public struct VoiceCommand: Identifiable {
    public let id = UUID()
    public var phrase: String
    public var action: () -> Void
}

protocol VoiceAssistantManaging: AnyObject {
    var isListening: Bool { get }
    var wakeWord: String { get }
    func configure(commands: [VoiceCommand])
    func start()
    func stop()
}

final class VoiceAssistantService: ObservableObject, VoiceAssistantManaging, @unchecked Sendable {
    @Published private(set) var isListening: Bool = false
    let wakeWord: String
    private var commands: [VoiceCommand] = []
    private let speechTranscriber: SpeechTranscribing
    private let synthesizer: SpeechSynthesizing
    private let queue = DispatchQueue(label: "com.novacoach.voiceassistant")
    #if canImport(OSLog)
    private let logger = Logger(subsystem: "com.novacoach.app", category: "VoiceAssistant")
    #endif
    #if canImport(Porcupine)
    private var porcupineManager: PorcupineManager?
    #endif

    init(wakeWord: String = "Hey Buddy", speechTranscriber: SpeechTranscribing, synthesizer: SpeechSynthesizing) {
        self.wakeWord = wakeWord
        self.speechTranscriber = speechTranscriber
        self.synthesizer = synthesizer
    }

    func configure(commands: [VoiceCommand]) {
        self.commands = commands
    }

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { [weak self] in
                self?.isListening = true
            }
            #if canImport(Porcupine)
            if self.porcupineManager == nil {
                // The Porcupine wake-word engine must be bundled with the app. Replace "HeyBuddy.ppn"
                // with the generated model path to deploy a custom wake word.
                do {
                    self.porcupineManager = try PorcupineManager(keywordPath: "HeyBuddy.ppn", onDetection: { [weak self] _ in
                        self?.synthesizerSpeak("Listening")
                    })
                } catch {
                    self.logError("Failed to initialize PorcupineManager: \(error.localizedDescription)")
                    self.synthesizerSpeak("Wake word detection is unavailable. Please check your app setup.")
                    return
                }
            }
            do {
                try self.porcupineManager?.start()
            } catch {
                self.logError("Failed to start PorcupineManager: \(error.localizedDescription)")
                self.synthesizerSpeak("Wake word detection could not be started.")
                return
            }
            #endif
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { [weak self] in
                self?.isListening = false
            }
            #if canImport(Porcupine)
            self.porcupineManager?.stop()
            #endif
        }
    }

    func handleRecognizedText(_ text: String) {
        guard isListening else { return }
        let normalised = text.lowercased()
        if let command = commands.first(where: { normalised.contains($0.phrase.lowercased()) }) {
            synthesizerSpeak("Executing \(command.phrase)")
            command.action()
        }
    }

    private func synthesizerSpeak(_ text: String) {
        Task { await synthesizer.speak(text) }
    }
    
    private func logError(_ message: String) {
        #if canImport(OSLog)
        logger.error("\(message)")
        #else
        print("ERROR: \(message)")
        #endif
    }
}
