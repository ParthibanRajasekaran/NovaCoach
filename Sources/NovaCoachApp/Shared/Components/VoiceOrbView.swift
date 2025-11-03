#if canImport(SwiftUI)
import SwiftUI

struct VoiceOrbView: View {
    @ObservedObject var assistant: VoiceAssistantService

    var body: some View {
        Circle()
            .fill(AppTheme.accent.opacity(assistant.isListening ? 0.8 : 0.3))
            .frame(width: assistant.isListening ? 120 : 80, height: assistant.isListening ? 120 : 80)
            .overlay(
                Circle()
                    .strokeBorder(AppTheme.accent.opacity(0.4), lineWidth: assistant.isListening ? 6 : 2)
                    .blur(radius: assistant.isListening ? 8 : 2)
                    .opacity(assistant.isListening ? 1 : 0.5)
                    .scaleEffect(assistant.isListening ? 1.2 : 1)
            )
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: assistant.isListening)
            .accessibilityLabel(assistant.isListening ? "Assistant listening" : "Assistant idle")
    }
}
#endif
