import Foundation

protocol CreateObjectiveUseCase {
    func execute(_ objective: Objective) async throws
}

protocol FetchObjectivesUseCase {
    func execute() async throws -> [Objective]
}

protocol UpdateKeyResultProgressUseCase {
    func execute(objectiveID: UUID, keyResultID: UUID, progress: Double) async throws
}

final class CreateObjectiveUseCaseImpl: CreateObjectiveUseCase {
    private let repository: ObjectiveRepository

    init(repository: ObjectiveRepository) {
        self.repository = repository
    }

    func execute(_ objective: Objective) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.repository.createObjective(objective)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

final class FetchObjectivesUseCaseImpl: FetchObjectivesUseCase {
    private let repository: ObjectiveRepository

    init(repository: ObjectiveRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Objective] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let objectives = try self.repository.fetchObjectives()
                    continuation.resume(returning: objectives)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

final class UpdateKeyResultProgressUseCaseImpl: UpdateKeyResultProgressUseCase {
    private let repository: ObjectiveRepository

    init(repository: ObjectiveRepository) {
        self.repository = repository
    }

    func execute(objectiveID: UUID, keyResultID: UUID, progress: Double) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    var objectives = try self.repository.fetchObjectives()
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
                    objective.actionItems = objective.actionItems
                    objectives[index] = objective
                    try self.repository.updateObjective(objective)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
