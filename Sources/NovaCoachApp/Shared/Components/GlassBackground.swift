#if canImport(SwiftUI)
import SwiftUI

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.glassStroke, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
    }
}
#endif

#if canImport(SwiftUI)
extension View {
    func glassBackground() -> some View {
        modifier(GlassBackground())
    }
}
#endif
