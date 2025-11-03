#if canImport(SwiftUI)
import SwiftUI

struct AppTheme {
    static let accent = Color("AccentColor", bundle: .module)
    static let glassBackground = Color.white.opacity(0.08)
    static let glassStroke = Color.white.opacity(0.2)
    static let darkBackground = LinearGradient(
        colors: [Color.black, Color(red: 0.08, green: 0.09, blue: 0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
#endif

#if canImport(UIKit)
import UIKit
#endif

struct HapticEngine {
    static func success() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}
