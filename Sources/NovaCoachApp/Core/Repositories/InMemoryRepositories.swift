import Foundation

final class InMemoryObjectiveRepository: ObjectiveRepository {
    private var storage: [Objective] = []

    func createObjective(_ objective: Objective) throws {
        storage.append(objective)
    }

    func fetchObjectives() throws -> [Objective] {
        storage
    }

    func updateObjective(_ objective: Objective) throws {
        guard let index = storage.firstIndex(where: { $0.id == objective.id }) else { throw RepositoryError.missingEntity }
        storage[index] = objective
    }

    func deleteObjective(id: UUID) throws {
        storage.removeAll { $0.id == id }
    }
}

final class InMemoryOneOnOneRepository: OneOnOneRepository {
    private var storage: [OneOnOneMeeting] = []

    func createMeeting(_ meeting: OneOnOneMeeting) throws {
        storage.append(meeting)
    }

    func fetchMeetings(filter: OneOnOneFilter) throws -> [OneOnOneMeeting] {
        storage.filter { meeting in
            var matches = true
            if let keyword = filter.keyword, !keyword.isEmpty {
                matches = matches && (meeting.notes?.contains(keyword) ?? false)
            }
            if let participant = filter.participant, !participant.isEmpty {
                matches = matches && meeting.counterpartName.contains(participant)
            }
            if let status = filter.status {
                matches = matches && meeting.actionItems.contains(where: { $0.status == status })
            }
            return matches
        }
    }

    func deleteMeeting(id: UUID) throws {
        storage.removeAll { $0.id == id }
    }
}

final class InMemoryPersonalLogRepository: PersonalLogRepository {
    private var storage: [PersonalLogEntry] = []

    func createLog(_ entry: PersonalLogEntry) throws {
        storage.append(entry)
    }

    func fetchLogs() throws -> [PersonalLogEntry] {
        storage
    }

    func deleteLog(id: UUID) throws {
        storage.removeAll { $0.id == id }
    }
}

final class InMemoryActionItemRepository: ActionItemRepository {
    private var storage: [ActionItem] = []

    func upsertActionItems(_ items: [ActionItem]) throws {
        for item in items {
            if let index = storage.firstIndex(where: { $0.id == item.id }) {
                storage[index] = item
            } else {
                storage.append(item)
            }
        }
    }

    func fetchActionItems() throws -> [ActionItem] {
        storage
    }
}
