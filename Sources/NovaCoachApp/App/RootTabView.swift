#if canImport(SwiftUI)
import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var selectedTab: Int = 0
    @State private var isVoiceActive: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ObjectiveDashboardView(viewModel: coordinator.objectiveViewModel)
                .tabItem { Label("OKRs", systemImage: "target") }
                .tag(0)

            OneOnOneListView(viewModel: coordinator.oneOnOneViewModel)
                .tabItem { Label("10:10s", systemImage: "person.2.wave.2") }
                .tag(1)

            PersonalLogView(viewModel: coordinator.personalViewModel)
                .tabItem { Label("Personal", systemImage: "person.crop.circle") }
                .tag(2)

            AnalyticsDashboardView(viewModel: coordinator.analyticsViewModel)
                .tabItem { Label("Analytics", systemImage: "chart.bar") }
                .tag(3)
        }
        .overlay(alignment: .bottomTrailing) {
            VoiceOrbView(assistant: coordinator.voiceAssistant)
            .padding(24)
            .onTapGesture {
                isVoiceActive.toggle()
                if isVoiceActive {
                    coordinator.voiceAssistant.start()
                } else {
                    coordinator.voiceAssistant.stop()
                }
            }
            .accessibilityLabel("Voice Assistant")
            .accessibilityHint("Double tap to toggle voice assistant on or off")
            .accessibilityValue(isVoiceActive ? "Active" : "Inactive")
            .accessibilityAddTraits(.isButton)
        }
    }
}
#endif
