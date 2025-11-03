import Foundation

@MainActor
protocol CreateObjectiveUseCase {
    func execute(_ objective: Objective) async throws
}

@MainActor
protocol FetchObjectivesUseCase {
    func execute() async throws -> [Objective]
}

@MainActor
protocol UpdateKeyResultProgressUseCase {
    func execute(objectiveID: UUID, keyResultID: UUID, progress: Double) async throws
}

final class CreateObjectiveUseCaseImpl: CreateObjectiveUseCase, @unchecked Sendable {
    private let repository: ObjectiveRepository

    init(repository: ObjectiveRepository) {
        self.repository = repository
    }

    func execute(_ objective: Objective) async throws {
        try repository.createObjective(objective)
    }
}

final class FetchObjectivesUseCaseImpl: FetchObjectivesUseCase, @unchecked Sendable {
    private let repository: ObjectiveRepository

    init(repository: ObjectiveRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Objective] {
        try repository.fetchObjectives()
    }
}

final class UpdateKeyResultProgressUseCaseImpl: UpdateKeyResultProgressUseCase, @unchecked Sendable {
    private let repository: ObjectiveRepository

    init(repository: ObjectiveRepository) {
        self.repository = repository
    }

    func execute(objectiveID: UUID, keyResultID: UUID, progress: Double) async throws {
        var objectives = try repository.fetchObjectives()
        guard let index = objectives.firstIndex(where: { $0.id == objectiveID }) else {
            throw RepositoryError.missingEntity
        }
        var objective = objectives[index]
        guard let krIndex = objective.keyResults.firstIndex(where: { $0.id == keyResultID }) else {
            throw RepositoryError.missingEntity
        }
        var keyResult = objective.keyResults[krIndex]
        keyResult.currentValue = min(max(progress * keyResult.targetValue, 0), keyResult.targetValue)
        keyResult.updatedAt = Date()
        objective.keyResults[krIndex] = keyResult
        objectives[index] = objective
        try repository.updateObjective(objective)
    }
}
