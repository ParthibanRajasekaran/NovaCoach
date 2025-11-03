import Foundation

protocol CreateOneOnOneUseCase {
    func execute(_ meeting: OneOnOneMeeting) async throws
}

protocol FetchOneOnOneUseCase {
    func execute(filter: OneOnOneFilter) async throws -> [OneOnOneMeeting]
}

final class CreateOneOnOneUseCaseImpl: CreateOneOnOneUseCase {
    private let repository: OneOnOneRepository

    init(repository: OneOnOneRepository) {
        self.repository = repository
    }

    func execute(_ meeting: OneOnOneMeeting) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.repository.createMeeting(meeting)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

final class FetchOneOnOneUseCaseImpl: FetchOneOnOneUseCase {
    private let repository: OneOnOneRepository

    init(repository: OneOnOneRepository) {
        self.repository = repository
    }

    func execute(filter: OneOnOneFilter) async throws -> [OneOnOneMeeting] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let meetings = try self.repository.fetchMeetings(filter: filter)
                    continuation.resume(returning: meetings)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
