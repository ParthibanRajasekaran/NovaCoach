#if canImport(SwiftUI)
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    let objectiveViewModel: ObjectiveDashboardViewModel
    let oneOnOneViewModel: OneOnOneListViewModel
    let personalViewModel: PersonalLogViewModel
    let analyticsViewModel: AnalyticsViewModel
    let voiceAssistant: VoiceAssistantService
    let speechService: SpeechService
    let notificationScheduler: NotificationScheduler
    #if canImport(CoreData)
    let coreDataStack: CoreDataStack
    #endif

    init() {
        speechService = SpeechService()
        notificationScheduler = NotificationScheduler()
        let fileEncryption = FileEncryptionService(encryptionKeyProvider: KeychainService.shared)

        #if canImport(CoreData)
        let stack = CoreDataStack(encryptionKeyProvider: KeychainService.shared)
        coreDataStack = stack
        let objectiveRepository: ObjectiveRepository = CoreDataObjectiveRepository(stack: stack)
        let oneOnOneRepository: OneOnOneRepository = CoreDataOneOnOneRepository(stack: stack)
        let personalLogRepository: PersonalLogRepository = CoreDataPersonalLogRepository(stack: stack)
        let actionItemRepository: ActionItemRepository = CoreDataActionItemRepository(stack: stack)
        #else
        let objectiveRepository: ObjectiveRepository = InMemoryObjectiveRepository()
        let oneOnOneRepository: OneOnOneRepository = InMemoryOneOnOneRepository()
        let personalLogRepository: PersonalLogRepository = InMemoryPersonalLogRepository()
        let actionItemRepository: ActionItemRepository = InMemoryActionItemRepository()
        #endif

        let createObjective = CreateObjectiveUseCaseImpl(repository: objectiveRepository)
        let fetchObjectives = FetchObjectivesUseCaseImpl(repository: objectiveRepository)
        let updateKeyResult = UpdateKeyResultProgressUseCaseImpl(repository: objectiveRepository)
        objectiveViewModel = ObjectiveDashboardViewModel(
            fetchUseCase: fetchObjectives,
            createUseCase: createObjective,
            updateUseCase: updateKeyResult
        )

        let createMeeting = CreateOneOnOneUseCaseImpl(repository: oneOnOneRepository)
        let fetchMeetings = FetchOneOnOneUseCaseImpl(repository: oneOnOneRepository)
        let fileEncryption = FileEncryptionService(keyProvider: KeychainService.shared)
        oneOnOneViewModel = OneOnOneListViewModel(
            fetchUseCase: fetchMeetings,
            createUseCase: createMeeting,
            speechTranscriber: speechService,
            notificationScheduler: notificationScheduler,
            fileEncryption: fileEncryption
        )

        let createPersonal = CreatePersonalLogUseCaseImpl(repository: personalLogRepository)
        let fetchPersonal = FetchPersonalLogsUseCaseImpl(repository: personalLogRepository)
        personalViewModel = PersonalLogViewModel(
            createUseCase: createPersonal,
            fetchUseCase: fetchPersonal,
            notificationScheduler: notificationScheduler
        )

        let analyticsUseCase = FetchAnalyticsSnapshotUseCaseImpl(
            objectiveRepository: objectiveRepository,
            actionItemRepository: actionItemRepository,
            personalLogRepository: personalLogRepository
        )
        analyticsViewModel = AnalyticsViewModel(useCase: analyticsUseCase)

        voiceAssistant = VoiceAssistantService(wakeWord: "Hey Buddy", speechTranscriber: speechService, synthesizer: speechService)
        voiceAssistant.configure(commands: [
            VoiceCommand(phrase: "add a new okr") { [weak objectiveViewModel] in
                Task { await objectiveViewModel?.createObjective(title: "Voice Objective", detail: "", start: Date(), end: Date().addingTimeInterval(60*60*24*30)) }
            },
            VoiceCommand(phrase: "record a 1:1") { [weak oneOnOneViewModel] in
                Task { await oneOnOneViewModel?.saveMeeting(date: Date(), counterpart: "Voice", role: nil, notes: "", audioURL: nil, actionItems: []) }
            },
            VoiceCommand(phrase: "what's my progress") { [weak analyticsViewModel, weak self] in
                Task {
                    await analyticsViewModel?.load()
                    if let percent = analyticsViewModel?.snapshot?.objectiveProgress.first?.completion {
                        await self?.speechService.speak("Your leading objective is \(Int(percent * 100)) percent complete")
                    }
                }
            }
        ])
    }
}
#endif
