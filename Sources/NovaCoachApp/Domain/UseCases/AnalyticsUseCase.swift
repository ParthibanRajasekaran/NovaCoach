import Foundation

@MainActor
protocol FetchAnalyticsSnapshotUseCase {
    func execute() async throws -> AnalyticsSnapshot
}

final class FetchAnalyticsSnapshotUseCaseImpl: FetchAnalyticsSnapshotUseCase, @unchecked Sendable {
    private let objectiveRepository: ObjectiveRepository
    private let actionItemRepository: ActionItemRepository
    private let personalLogRepository: PersonalLogRepository

    init(
        objectiveRepository: ObjectiveRepository,
        actionItemRepository: ActionItemRepository,
        personalLogRepository: PersonalLogRepository
    ) {
        self.objectiveRepository = objectiveRepository
        self.actionItemRepository = actionItemRepository
        self.personalLogRepository = personalLogRepository
    }

    func execute() async throws -> AnalyticsSnapshot {
        let objectives = try objectiveRepository.fetchObjectives()
        let actionItems = try actionItemRepository.fetchActionItems()
        let logs = try personalLogRepository.fetchLogs()
        let completed = actionItems.filter { $0.status == .completed }.count
        let pending = actionItems.count - completed
        let streak = Self.calculateStreak(from: logs)
        return AnalyticsSnapshot(
            objectiveProgress: objectives,
            completedActionItems: completed,
            pendingActionItems: pending,
            reflectionStreak: streak
        )
    }

    private static func calculateStreak(from logs: [PersonalLogEntry]) -> Int {
        let sorted = logs.sorted(by: { $0.entryDate > $1.entryDate })
        guard let firstDate = sorted.first?.entryDate else { return 0 }
        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: firstDate)
        for log in sorted {
            let logDate = Calendar.current.startOfDay(for: log.entryDate)
            if logDate == expectedDate {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else if logDate == Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: logDate) ?? logDate
            } else {
                break
            }
        }
        return streak
    }
}
