#if canImport(SwiftUI)
import SwiftUI
#endif

#if os(iOS)
@main
struct NovaCoachAppMain: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(coordinator)
        }
    }
}
#else
public struct NovaCoachAppMain {
    public static func main() {
        // Entry point is only available on iOS. Tests on other platforms use the library APIs.
    }
}
#endif
