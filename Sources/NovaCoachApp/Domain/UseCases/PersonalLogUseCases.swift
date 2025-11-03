import Foundation

@MainActor
protocol CreatePersonalLogUseCase {
    func execute(_ entry: PersonalLogEntry) async throws
}

@MainActor
protocol FetchPersonalLogsUseCase {
    func execute() async throws -> [PersonalLogEntry]
}

final class CreatePersonalLogUseCaseImpl: CreatePersonalLogUseCase, @unchecked Sendable {
    private let repository: PersonalLogRepository

    init(repository: PersonalLogRepository) {
        self.repository = repository
    }

    func execute(_ entry: PersonalLogEntry) async throws {
        try repository.createLog(entry)
    }
}

final class FetchPersonalLogsUseCaseImpl: FetchPersonalLogsUseCase, @unchecked Sendable {
    private let repository: PersonalLogRepository

    init(repository: PersonalLogRepository) {
        self.repository = repository
    }

    func execute() async throws -> [PersonalLogEntry] {
        try repository.fetchLogs()
    }
}
