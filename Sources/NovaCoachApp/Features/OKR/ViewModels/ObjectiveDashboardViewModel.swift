import Foundation
import Combine

@MainActor
final class ObjectiveDashboardViewModel: ObservableObject {
    @Published private(set) var objectives: [Objective] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let fetchUseCase: FetchObjectivesUseCase
    private let createUseCase: CreateObjectiveUseCase
    private let updateUseCase: UpdateKeyResultProgressUseCase

    init(
        fetchUseCase: FetchObjectivesUseCase,
        createUseCase: CreateObjectiveUseCase,
        updateUseCase: UpdateKeyResultProgressUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.createUseCase = createUseCase
        self.updateUseCase = updateUseCase
    }

    func load() async {
        do {
            isLoading = true
            objectives = try await fetchUseCase.execute()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createObjective(title: String, detail: String?, start: Date, end: Date) async {
        let objective = Objective(title: title, detail: detail, startDate: start, endDate: end)
        do {
            try await createUseCase.execute(objective)
            await load()
            HapticEngine.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProgress(objectiveID: UUID, keyResultID: UUID, progress: Double) async {
        do {
            try await updateUseCase.execute(objectiveID: objectiveID, keyResultID: keyResultID, progress: progress)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
