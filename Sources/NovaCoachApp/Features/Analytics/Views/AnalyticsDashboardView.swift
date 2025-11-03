import SwiftUI

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let snapshot = viewModel.snapshot {
                        ProgressSection(snapshot: snapshot)
                        ActionItemSummary(snapshot: snapshot)
                        ReflectionStreakView(streak: snapshot.reflectionStreak)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                .padding()
            }
            .background(AppTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("Analytics")
            .task { await viewModel.load() }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("Dismiss", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
    }
}

private struct ProgressSection: View {
    let snapshot: AnalyticsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Objective Progress")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(snapshot.objectiveProgress) { objective in
                        VStack(alignment: .leading) {
                            Text(objective.title)
                                .font(.subheadline.bold())
                            ProgressRingView(progress: objective.completion, label: "Complete")
                        }
                        .glassBackground()
                    }
                }
            }
        }
    }
}

private struct ActionItemSummary: View {
    let snapshot: AnalyticsSnapshot

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Completed")
                    .font(.headline)
                Text("\(snapshot.completedActionItems)")
                    .font(.title.bold())
            }
            .padding()
            .glassBackground()

            VStack(alignment: .leading) {
                Text("Pending")
                    .font(.headline)
                Text("\(snapshot.pendingActionItems)")
                    .font(.title.bold())
            }
            .padding()
            .glassBackground()
        }
    }
}

private struct ReflectionStreakView: View {
    let streak: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("Reflection Streak")
                .font(.headline)
            Text("\(streak) days")
                .font(.largeTitle.bold())
            if streak >= 7 {
                Text("Amazing consistency! Keep the streak alive.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .glassBackground()
    }
}
