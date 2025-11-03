import Foundation

@MainActor
protocol CreateOneOnOneUseCase {
    func execute(_ meeting: OneOnOneMeeting) async throws
}

@MainActor
protocol FetchOneOnOneUseCase {
    func execute(filter: OneOnOneFilter) async throws -> [OneOnOneMeeting]
}

final class CreateOneOnOneUseCaseImpl: CreateOneOnOneUseCase, @unchecked Sendable {
    private let repository: OneOnOneRepository

    init(repository: OneOnOneRepository) {
        self.repository = repository
    }

    func execute(_ meeting: OneOnOneMeeting) async throws {
        try repository.createMeeting(meeting)
    }
}

final class FetchOneOnOneUseCaseImpl: FetchOneOnOneUseCase, @unchecked Sendable {
    private let repository: OneOnOneRepository

    init(repository: OneOnOneRepository) {
        self.repository = repository
    }

    func execute(filter: OneOnOneFilter) async throws -> [OneOnOneMeeting] {
        try repository.fetchMeetings(filter: filter)
    }
}
