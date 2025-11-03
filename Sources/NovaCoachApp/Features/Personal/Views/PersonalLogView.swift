#if canImport(SwiftUI)
import SwiftUI

struct PersonalLogView: View {
    @StateObject private var viewModel: PersonalLogViewModel

    init(viewModel: PersonalLogViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Morning Focus")
                            .font(.headline)
                        TextField("What will you focus on today?", text: $viewModel.plannedWork, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Slider(value: $viewModel.moodScore, in: 0...1) {
                            Text("Energy Level")
                        }
                        Picker("Reminder Frequency", selection: $viewModel.reminderFrequency) {
                            ForEach(ReminderFrequency.allCases) { frequency in
                                Text(frequency.rawValue.capitalized).tag(frequency)
                            }
                        }
                        Button(action: { Task { await viewModel.save(objectiveID: nil) } }) {
                            Label("Save Entry", systemImage: "tray.and.arrow.down.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.plannedWork.isEmpty)
                    }
                    .glassBackground()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Reflections")
                            .font(.headline)
                        ForEach(viewModel.logs) { log in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(log.entryDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(log.moodScore.asPercentString())
                                        .font(.caption)
                                }
                                Text(log.plannedWork)
                                    .font(.body)
                                if let reflection = log.reflection {
                                    Text(reflection)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
                        }
                    }
                    .glassBackground()
                }
                .padding()
            }
            .background(AppTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("Personal")
            .task { await viewModel.load() }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("Dismiss", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
    }
}
#endif
