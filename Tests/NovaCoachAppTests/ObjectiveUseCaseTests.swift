import XCTest
@testable import NovaCoachApp

@MainActor
final class ObjectiveUseCaseTests: XCTestCase {
    func testCreateObjectiveAddsToRepository() async throws {
        let repository = InMemoryObjectiveRepository()
        let createUseCase = CreateObjectiveUseCaseImpl(repository: repository)
        let fetchUseCase = FetchObjectivesUseCaseImpl(repository: repository)

        let objective = Objective(title: "Ship NovaCoach", startDate: Date(), endDate: Date().addingTimeInterval(86_400))
        try await createUseCase.execute(objective)
        let objectives = try await fetchUseCase.execute()
        XCTAssertEqual(objectives.count, 1)
        XCTAssertEqual(objectives.first?.title, "Ship NovaCoach")
    }

    func testAnalyticsSnapshotCountsActionItems() async throws {
        let objectiveRepo = InMemoryObjectiveRepository()
        let actionRepo = InMemoryActionItemRepository()
        let personalRepo = InMemoryPersonalLogRepository()

        let action = ActionItem(title: "Demo", status: .completed)
        try actionRepo.upsertActionItems([action])
        try objectiveRepo.createObjective(Objective(title: "Launch", startDate: Date(), endDate: Date()))

        let analytics = FetchAnalyticsSnapshotUseCaseImpl(
            objectiveRepository: objectiveRepo,
            actionItemRepository: actionRepo,
            personalLogRepository: personalRepo
        )

        let snapshot = try await analytics.execute()
        XCTAssertEqual(snapshot.completedActionItems, 1)
        XCTAssertEqual(snapshot.pendingActionItems, 0)
    }

    func testUpdateKeyResultProgressClampsToTarget() async throws {
        let repository = InMemoryObjectiveRepository()
        let keyResult = KeyResult(title: "Adoption", targetValue: 100, currentValue: 10, unit: "%")
        let objective = Objective(title: "Grow", startDate: Date(), endDate: Date(), keyResults: [keyResult])
        try repository.createObjective(objective)

        let updateUseCase = UpdateKeyResultProgressUseCaseImpl(repository: repository)
        try await updateUseCase.execute(objectiveID: objective.id, keyResultID: keyResult.id, progress: 1.5)

        let fetchUseCase = FetchObjectivesUseCaseImpl(repository: repository)
        let updatedObjectives = try await fetchUseCase.execute()
        let updatedValue = updatedObjectives.first?.keyResults.first?.currentValue
        XCTAssertEqual(updatedValue, 100)
    }
}
