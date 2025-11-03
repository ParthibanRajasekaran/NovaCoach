#if canImport(SwiftUI)
import SwiftUI

struct ObjectiveDashboardView: View {
    @StateObject private var viewModel: ObjectiveDashboardViewModel
    @State private var showCreateSheet = false

    init(viewModel: ObjectiveDashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(viewModel.objectives) { objective in
                        ObjectiveCardView(objective: objective)
                            .glassBackground()
                    }
                    .animation(.easeInOut, value: viewModel.objectives)

                    if viewModel.objectives.isEmpty {
                        ContentUnavailableView("No Objectives", systemImage: "target", description: Text("Tap the + button to create your first objective."))
                            .glassBackground()
                    }
                }
                .padding()
            }
            .background(AppTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("OKRs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Create objective")
                }
            }
            .task { await viewModel.load() }
            .sheet(isPresented: $showCreateSheet) {
                CreateObjectiveView(isPresented: $showCreateSheet, onCreate: { title, detail, start, end in
                    Task { await viewModel.createObjective(title: title, detail: detail, start: start, end: end) }
                })
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("Dismiss", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
    }
}


private struct ObjectiveCardView: View {
    let objective: Objective

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(objective.title)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    if let detail = objective.detail {
                        Text(detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ProgressRingView(progress: objective.completion, label: "Progress")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Key Results")
                    .font(.headline)
                ForEach(objective.keyResults) { keyResult in
                    VStack(alignment: .leading) {
                        Text(keyResult.title)
                            .font(.subheadline.bold())
                        ProgressView(value: keyResult.progress) {
                            Text(keyResult.detail ?? keyResult.unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accentColor(AppTheme.accent)
                    }
                }
            }

            if !objective.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Linked Action Items")
                        .font(.headline)
                    ForEach(objective.actionItems) { item in
                        HStack {
                            Image(systemName: item.status == .completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.status == .completed ? .green : .secondary)
                            VStack(alignment: .leading) {
                                Text(item.title)
                                if let due = item.dueDate {
                                    Text("Due \(due.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct CreateObjectiveView: View {
    @Binding var isPresented: Bool
    var onCreate: (String, String?, Date, Date) -> Void

    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Objective") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $detail, axis: .vertical)
                }

                Section("Timeline") {
                    DatePicker("Start", selection: $startDate, displayedComponents: [.date])
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: [.date])
                }
            }
            .navigationTitle("New Objective")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(title, detail.isEmpty ? nil : detail, startDate, endDate)
                        isPresented = false
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
#endif
