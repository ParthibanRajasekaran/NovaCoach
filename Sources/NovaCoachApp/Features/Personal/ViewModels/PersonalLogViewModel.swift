import Foundation

@MainActor
final class PersonalLogViewModel: ObservableObject {
    @Published private(set) var logs: [PersonalLogEntry] = []
    @Published var plannedWork: String = ""
    @Published var reflection: String = ""
    @Published var moodScore: Double = 0.5
    @Published var reminderFrequency: ReminderFrequency = .daily
    @Published var errorMessage: String?

    private let createUseCase: CreatePersonalLogUseCase
    private let fetchUseCase: FetchPersonalLogsUseCase
    private let notificationScheduler: NotificationScheduling

    init(
        createUseCase: CreatePersonalLogUseCase,
        fetchUseCase: FetchPersonalLogsUseCase,
        notificationScheduler: NotificationScheduling
    ) {
        self.createUseCase = createUseCase
        self.fetchUseCase = fetchUseCase
        self.notificationScheduler = notificationScheduler
    }

    func load() async {
        do {
            logs = try await fetchUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(objectiveID: UUID?) async {
        let entry = PersonalLogEntry(
            entryDate: Date(),
            plannedWork: plannedWork,
            reflection: reflection.isEmpty ? nil : reflection,
            moodScore: moodScore,
            reminderFrequency: reminderFrequency,
            objectiveID: objectiveID
        )
        do {
            try await createUseCase.execute(entry)
            try await scheduleReminder()
            plannedWork = ""
            reflection = ""
            moodScore = 0.5
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleReminder() async throws {
        let nextDate: Date
        switch reminderFrequency {
        case .daily:
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        case .everyOtherDay:
            nextDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        case .weekly:
            nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        }

        try await notificationScheduler.scheduleReminder(
            identifier: "personal-log-reminder",
            title: "Reflection Reminder",
            body: "How did your day go?",
            date: nextDate
        )
    }
}
