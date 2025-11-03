import SwiftUI

struct OneOnOneListView: View {
    @StateObject private var viewModel: OneOnOneListViewModel
    @State private var filter = OneOnOneFilter()
    @State private var showingCreate = false
    @State private var selectedStatus: ActionItemStatus? = nil

    init(viewModel: OneOnOneListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.meetings) { meeting in
                    NavigationLink(value: meeting.id) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(meeting.counterpartName)
                                .font(.headline)
                            Text(meeting.meetingDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let notes = meeting.notes {
                                Text(notes)
                                    .font(.callout)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("10:10s")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Status", selection: Binding(
                            get: { selectedStatus },
                            set: { newValue in
                                selectedStatus = newValue
                                filter.status = newValue
                                Task { await viewModel.load(filter: filter) }
                            }
                        )) {
                            Text("All").tag(ActionItemStatus?.none)
                            ForEach(ActionItemStatus.allCases) { status in
                                Text(status.rawValue.capitalized).tag(Optional(status))
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCreate = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .task { await viewModel.load(filter: filter) }
            .sheet(isPresented: $showingCreate) {
                CreateOneOnOneView(isPresented: $showingCreate) { date, name, role, notes, audioURL, items in
                    Task { await viewModel.saveMeeting(date: date, counterpart: name, role: role, notes: notes, audioURL: audioURL, actionItems: items) }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("Dismiss", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
            .navigationDestination(for: UUID.self) { id in
                if let meeting = viewModel.meetings.first(where: { $0.id == id }) {
                    OneOnOneDetailView(meeting: meeting)
                }
            }
        }
    }
}

private struct CreateOneOnOneView: View {
    @Binding var isPresented: Bool
    var onSave: (Date, String, String?, String?, URL?, [ActionItem]) -> Void

    @State private var date: Date = Date()
    @State private var name: String = ""
    @State private var role: String = ""
    @State private var notes: String = ""
    @State private var actionItems: [ActionItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Meeting") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Name", text: $name)
                    TextField("Role", text: $role)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section("Action Items") {
                    ForEach(actionItems) { item in
                        VStack(alignment: .leading) {
                            Text(item.title)
                            if let due = item.dueDate {
                                Text("Due \(due.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Add Action Item") {
                        let newItem = ActionItem(title: "Follow up", dueDate: Date().addingTimeInterval(86400))
                        actionItems.append(newItem)
                    }
                }
            }
            .navigationTitle("New 10:10")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(date, name, role.isEmpty ? nil : role, notes.isEmpty ? nil : notes, nil, actionItems)
                        isPresented = false
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

private struct OneOnOneDetailView: View {
    let meeting: OneOnOneMeeting

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(meeting.counterpartName)
                    .font(.largeTitle.bold())
                if let role = meeting.counterpartRole {
                    Text(role)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Text(meeting.meetingDate.formatted(date: .complete, time: .shortened))
                    .font(.subheadline)
                if let notes = meeting.notes {
                    Text(notes)
                        .font(.body)
                }
                if !meeting.actionItems.isEmpty {
                    Divider()
                    Text("Action Items")
                        .font(.headline)
                    ForEach(meeting.actionItems) { item in
                        HStack {
                            Image(systemName: item.status == .completed ? "checkmark.circle.fill" : "circle")
                            Text(item.title)
                            Spacer()
                            if let due = item.dueDate {
                                Text(due.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("10:10 Summary")
    }
}
