import Foundation

protocol ObjectiveRepository {
    func createObjective(_ objective: Objective) throws
    func fetchObjectives() throws -> [Objective]
    func updateObjective(_ objective: Objective) throws
    func deleteObjective(id: UUID) throws
}

protocol OneOnOneRepository {
    func createMeeting(_ meeting: OneOnOneMeeting) throws
    func fetchMeetings(filter: OneOnOneFilter) throws -> [OneOnOneMeeting]
    func deleteMeeting(id: UUID) throws
}

protocol PersonalLogRepository {
    func createLog(_ entry: PersonalLogEntry) throws
    func fetchLogs() throws -> [PersonalLogEntry]
    func deleteLog(id: UUID) throws
}

protocol ActionItemRepository {
    func upsertActionItems(_ items: [ActionItem]) throws
    func fetchActionItems() throws -> [ActionItem]
}

struct OneOnOneFilter {
    var keyword: String?
    var participant: String?
    var status: ActionItemStatus?

    public init(keyword: String? = nil, participant: String? = nil, status: ActionItemStatus? = nil) {
        self.keyword = keyword
        self.participant = participant
        self.status = status
    }
}
