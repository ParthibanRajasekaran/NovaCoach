import Foundation

@MainActor
final class OneOnOneListViewModel: ObservableObject {
    @Published private(set) var meetings: [OneOnOneMeeting] = []
    @Published var errorMessage: String?
    @Published var isRecording: Bool = false

    private let fetchUseCase: FetchOneOnOneUseCase
    private let createUseCase: CreateOneOnOneUseCase
    private let speechTranscriber: SpeechTranscribing
    private let notificationScheduler: NotificationScheduling

    init(
        fetchUseCase: FetchOneOnOneUseCase,
        createUseCase: CreateOneOnOneUseCase,
        speechTranscriber: SpeechTranscribing,
        notificationScheduler: NotificationScheduling
    ) {
        self.fetchUseCase = fetchUseCase
        self.createUseCase = createUseCase
        self.speechTranscriber = speechTranscriber
        self.notificationScheduler = notificationScheduler
    }

    func load(filter: OneOnOneFilter = OneOnOneFilter()) async {
        do {
            meetings = try await fetchUseCase.execute(filter: filter)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveMeeting(date: Date, counterpart: String, role: String?, notes: String?, audioURL: URL?, actionItems: [ActionItem]) async {
        do {
            var transcriptPath: String?
            if let audioURL {
                let transcription = try await speechTranscriber.transcribeAudio(at: audioURL)
                transcriptPath = try saveTranscript(transcription)
            }
            let meeting = OneOnOneMeeting(
                meetingDate: date,
                counterpartName: counterpart,
                counterpartRole: role,
                notes: notes,
                audioFilePath: audioURL?.path,
                transcriptFilePath: transcriptPath,
                actionItems: actionItems
            )
            try await createUseCase.execute(meeting)
            try await scheduleReminders(for: actionItems)
            await load()
            HapticEngine.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveTranscript(_ text: String) throws -> String {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(UUID().uuidString + ".txt")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    private func scheduleReminders(for items: [ActionItem]) async throws {
        for item in items {
            if let due = item.dueDate {
                try await notificationScheduler.scheduleReminder(
                    identifier: item.id.uuidString,
                    title: "Action item due",
                    body: item.title,
                    date: due
                )
            }
        }
    }
}
