import Foundation

protocol CreatePersonalLogUseCase {
    func execute(_ entry: PersonalLogEntry) async throws
}

protocol FetchPersonalLogsUseCase {
    func execute() async throws -> [PersonalLogEntry]
}

final class CreatePersonalLogUseCaseImpl: CreatePersonalLogUseCase {
    private let repository: PersonalLogRepository

    init(repository: PersonalLogRepository) {
        self.repository = repository
    }

    func execute(_ entry: PersonalLogEntry) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.repository.createLog(entry)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

final class FetchPersonalLogsUseCaseImpl: FetchPersonalLogsUseCase {
    private let repository: PersonalLogRepository

    init(repository: PersonalLogRepository) {
        self.repository = repository
    }

    func execute() async throws -> [PersonalLogEntry] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let logs = try self.repository.fetchLogs()
                    continuation.resume(returning: logs)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
