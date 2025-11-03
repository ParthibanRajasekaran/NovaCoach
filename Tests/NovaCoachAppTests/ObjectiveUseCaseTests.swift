import XCTest
@testable import NovaCoachApp

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
}
