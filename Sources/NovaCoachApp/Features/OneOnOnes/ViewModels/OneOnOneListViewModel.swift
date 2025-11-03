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
    private let fileEncryption: FileEncrypting

    init(
        fetchUseCase: FetchOneOnOneUseCase,
        createUseCase: CreateOneOnOneUseCase,
        speechTranscriber: SpeechTranscribing,
        notificationScheduler: NotificationScheduling,
        fileEncryption: FileEncrypting
    ) {
        self.fetchUseCase = fetchUseCase
        self.createUseCase = createUseCase
        self.speechTranscriber = speechTranscriber
        self.notificationScheduler = notificationScheduler
        self.fileEncryption = fileEncryption
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
        guard let data = text.data(using: .utf8) else {
            throw FileEncryptionError.invalidData
        }
        let filename = UUID().uuidString + ".enc"
        let url = try fileEncryption.encryptAndSave(data, filename: filename)
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
