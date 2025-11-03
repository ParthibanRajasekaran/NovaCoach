#if canImport(SwiftUI)
import SwiftUI

struct ProgressRingView: View {
    var progress: Double
    var label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .foregroundStyle(.thinMaterial)
                .opacity(0.2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .foregroundStyle(AngularGradient(gradient: Gradient(colors: [AppTheme.accent, .purple, .blue]), center: .center))
                .rotationEffect(.degrees(-90))
            VStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(progress.asPercentString())
                    .font(.title2.bold())
            }
        }
        .frame(width: 120, height: 120)
        .padding()
    }
}
#endif
