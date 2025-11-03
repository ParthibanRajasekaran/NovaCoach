#if canImport(CoreData)
import Foundation
import CoreData

final class CoreDataObjectiveRepository: ObjectiveRepository {
    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func createObjective(_ objective: Objective) throws {
        try stack.viewContext.performAndWaitThrowing {
            _ = ObjectiveManagedObject.make(from: objective, in: stack.viewContext)
            try stack.viewContext.save()
        }
    }

    func fetchObjectives() throws -> [Objective] {
        try stack.viewContext.performAndWaitThrowing {
            let request = NSFetchRequest<ObjectiveManagedObject>(entityName: "ObjectiveEntity")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ObjectiveManagedObject.createdAt, ascending: true)]
            let results = try stack.viewContext.fetch(request)
            return results.map(ObjectiveManagedObject.toDomain)
        }
    }

    func updateObjective(_ objective: Objective) throws {
        try stack.viewContext.performAndWaitThrowing {
            let request = NSFetchRequest<ObjectiveManagedObject>(entityName: "ObjectiveEntity")
            request.predicate = NSPredicate(format: "id == %@", objective.id as CVarArg)
            guard let managed = try stack.viewContext.fetch(request).first else {
                throw RepositoryError.missingEntity
            }
            managed.update(from: objective, in: stack.viewContext)
            try stack.viewContext.save()
        }
    }

    func deleteObjective(id: UUID) throws {
        try stack.viewContext.performAndWaitThrowing {
            let request = NSFetchRequest<ObjectiveManagedObject>(entityName: "ObjectiveEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let managed = try stack.viewContext.fetch(request).first {
                stack.viewContext.delete(managed)
                try stack.viewContext.save()
            }
        }
    }
}

final class CoreDataOneOnOneRepository: OneOnOneRepository {
    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func createMeeting(_ meeting: OneOnOneMeeting) throws {
        try stack.viewContext.performAndWaitThrowing {
            _ = OneOnOneManagedObject.make(from: meeting, in: stack.viewContext)
            try stack.viewContext.save()
        }
    }

    func fetchMeetings(filter: OneOnOneFilter) throws -> [OneOnOneMeeting] {
        try stack.viewContext.performAndWaitThrowing {
            let request = NSFetchRequest<OneOnOneManagedObject>(entityName: "OneOnOneEntity")
            var predicates: [NSPredicate] = []
            if let keyword = filter.keyword, !keyword.isEmpty {
                predicates.append(NSPredicate(format: "notes CONTAINS[cd] %@", keyword))
            }
            if let participant = filter.participant, !participant.isEmpty {
                predicates.append(NSPredicate(format: "counterpartName CONTAINS[cd] %@", participant))
            }
            if let status = filter.status {
                predicates.append(NSPredicate(format: "ANY actionItems.statusRaw == %@", status.rawValue))
            }
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            request.sortDescriptors = [NSSortDescriptor(keyPath: \OneOnOneManagedObject.meetingDate, ascending: false)]
            let items = try stack.viewContext.fetch(request)
            return items.map(OneOnOneManagedObject.toDomain)
        }
    }

    func deleteMeeting(id: UUID) throws {
        try stack.viewContext.performAndWaitThrowing {
            let request = NSFetchRequest<OneOnOneManagedObject>(entityName: "OneOnOneEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try stack.viewContext.fetch(request).first {
                stack.viewContext.delete(entity)
                try stack.viewContext.save()
            }
        }
    }
}

final class CoreDataPersonalLogRepository: PersonalLogRepository {
    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func createLog(_ entry: PersonalLogEntry) throws {
        try stack.viewContext.performAndWaitThrowing {
            _ = PersonalLogManagedObject.make(from: entry, in: stack.viewContext)
            try stack.viewContext.save()
        }
    }

    func fetchLogs() throws -> [PersonalLogEntry] {
        try stack.viewContext.performAndWaitThrowing {
            let request = NSFetchRequest<PersonalLogManagedObject>(entityName: "PersonalLogEntity")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PersonalLogManagedObject.entryDate, ascending: false)]
            let logs = try stack.viewContext.fetch(request)
            return logs.map(PersonalLogManagedObject.toDomain)
        }
    }

    func deleteLog(id: UUID) throws {
        try stack.viewContext.performAndWaitThrowing {
            let request = NSFetchRequest<PersonalLogManagedObject>(entityName: "PersonalLogEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let log = try stack.viewContext.fetch(request).first {
                stack.viewContext.delete(log)
                try stack.viewContext.save()
            }
        }
    }
}

final class CoreDataActionItemRepository: ActionItemRepository {
    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func upsertActionItems(_ items: [ActionItem]) throws {
        try stack.viewContext.performAndWaitThrowing {
            for item in items {
                let request = NSFetchRequest<ActionItemManagedObject>(entityName: "ActionItemEntity")
                request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
                let existing = try stack.viewContext.fetch(request).first
                let managed = existing ?? ActionItemManagedObject(context: stack.viewContext)
                managed.update(from: item, in: stack.viewContext)
            }
            try stack.viewContext.save()
        }
    }

    func fetchActionItems() throws -> [ActionItem] {
        try stack.viewContext.performAndWaitThrowing {
            let request = NSFetchRequest<ActionItemManagedObject>(entityName: "ActionItemEntity")
            let results = try stack.viewContext.fetch(request)
            return results.map(ActionItemManagedObject.toDomain)
        }
    }
}

private extension NSManagedObjectContext {
    func performAndWaitThrowing<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>!
        performAndWait {
            result = Result { try block() }
        }
        return try result.get()
    }
}

private extension ObjectiveManagedObject {
    static func make(from objective: Objective, in context: NSManagedObjectContext) -> ObjectiveManagedObject {
        let managed = ObjectiveManagedObject(context: context)
        managed.update(from: objective, in: context)
        return managed
    }

    func update(from objective: Objective, in context: NSManagedObjectContext) {
        id = objective.id
        title = objective.title
        detail = objective.detail
        startDate = objective.startDate
        endDate = objective.endDate
        createdAt = objective.personalLogs.map(\PersonalLogEntry.entryDate).min() ?? objective.startDate
        updatedAt = Date()

        keyResults.forEach(context.delete)
        actionItems.forEach(context.delete)
        personalLogs.forEach(context.delete)

        keyResults = Set(objective.keyResults.map { KeyResultManagedObject.make(from: $0, objective: self, in: context) })
        actionItems = Set(objective.actionItems.map { ActionItemManagedObject.make(from: $0, in: context, objective: self) })
        personalLogs = Set(objective.personalLogs.map { PersonalLogManagedObject.make(from: $0, in: context, objective: self) })
    }

    static func toDomain(_ managed: ObjectiveManagedObject) -> Objective {
        Objective(
            id: managed.id,
            title: managed.title,
            detail: managed.detail,
            startDate: managed.startDate,
            endDate: managed.endDate,
            keyResults: managed.keyResults.map(KeyResultManagedObject.toDomain).sorted(by: { $0.createdAt < $1.createdAt }),
            actionItems: managed.actionItems.map(ActionItemManagedObject.toDomain),
            personalLogs: managed.personalLogs.map(PersonalLogManagedObject.toDomain)
        )
    }
}

private extension KeyResultManagedObject {
    static func make(from keyResult: KeyResult, objective: ObjectiveManagedObject, in context: NSManagedObjectContext) -> KeyResultManagedObject {
        let managed = KeyResultManagedObject(context: context)
        managed.id = keyResult.id
        managed.title = keyResult.title
        managed.detail = keyResult.detail
        managed.targetValue = keyResult.targetValue
        managed.currentValue = keyResult.currentValue
        managed.unit = keyResult.unit
        managed.createdAt = keyResult.createdAt
        managed.updatedAt = keyResult.updatedAt
        managed.objective = objective
        return managed
    }

    static func toDomain(_ managed: KeyResultManagedObject) -> KeyResult {
        KeyResult(
            id: managed.id,
            title: managed.title,
            detail: managed.detail,
            targetValue: managed.targetValue,
            currentValue: managed.currentValue,
            unit: managed.unit,
            createdAt: managed.createdAt,
            updatedAt: managed.updatedAt
        )
    }
}

private extension ActionItemManagedObject {
    static func make(from item: ActionItem, in context: NSManagedObjectContext, objective: ObjectiveManagedObject? = nil, meeting: OneOnOneManagedObject? = nil, personalLog: PersonalLogManagedObject? = nil) -> ActionItemManagedObject {
        let managed = ActionItemManagedObject(context: context)
        managed.id = item.id
        managed.title = item.title
        managed.detail = item.detail
        managed.dueDate = item.dueDate
        managed.ownerName = item.ownerName
        managed.statusRaw = item.status.rawValue
        managed.createdAt = item.createdAt
        managed.updatedAt = item.updatedAt
        managed.objective = objective
        managed.oneOnOne = meeting
        managed.personalLog = personalLog
        return managed
    }

    func update(from item: ActionItem, in context: NSManagedObjectContext) {
        id = item.id
        title = item.title
        detail = item.detail
        dueDate = item.dueDate
        ownerName = item.ownerName
        statusRaw = item.status.rawValue
        createdAt = item.createdAt
        updatedAt = item.updatedAt
        if let objectiveID = item.objectiveID {
            let request = NSFetchRequest<ObjectiveManagedObject>(entityName: "ObjectiveEntity")
            request.predicate = NSPredicate(format: "id == %@", objectiveID as CVarArg)
            objective = try? context.fetch(request).first
        }
        if let meetingID = item.oneOnOneID {
            let request = NSFetchRequest<OneOnOneManagedObject>(entityName: "OneOnOneEntity")
            request.predicate = NSPredicate(format: "id == %@", meetingID as CVarArg)
            oneOnOne = try? context.fetch(request).first
        }
        if let logID = item.personalLogID {
            let request = NSFetchRequest<PersonalLogManagedObject>(entityName: "PersonalLogEntity")
            request.predicate = NSPredicate(format: "id == %@", logID as CVarArg)
            personalLog = try? context.fetch(request).first
        }
    }

    static func toDomain(_ managed: ActionItemManagedObject) -> ActionItem {
        ActionItem(
            id: managed.id,
            title: managed.title,
            detail: managed.detail,
            dueDate: managed.dueDate,
            ownerName: managed.ownerName,
            status: ActionItemStatus(rawValue: managed.statusRaw) ?? .pending,
            createdAt: managed.createdAt,
            updatedAt: managed.updatedAt,
            objectiveID: managed.objective?.id,
            oneOnOneID: managed.oneOnOne?.id,
            personalLogID: managed.personalLog?.id
        )
    }
}

private extension OneOnOneManagedObject {
    static func make(from meeting: OneOnOneMeeting, in context: NSManagedObjectContext) -> OneOnOneManagedObject {
        let managed = OneOnOneManagedObject(context: context)
        managed.id = meeting.id
        managed.meetingDate = meeting.meetingDate
        managed.counterpartName = meeting.counterpartName
        managed.counterpartRole = meeting.counterpartRole
        managed.notes = meeting.notes
        managed.audioFilePath = meeting.audioFilePath
        managed.transcriptFilePath = meeting.transcriptFilePath
        managed.createdAt = meeting.meetingDate
        managed.updatedAt = Date()
        managed.actionItems = Set(meeting.actionItems.map { ActionItemManagedObject.make(from: $0, in: context, meeting: managed) })
        return managed
    }

    static func toDomain(_ managed: OneOnOneManagedObject) -> OneOnOneMeeting {
        OneOnOneMeeting(
            id: managed.id,
            meetingDate: managed.meetingDate,
            counterpartName: managed.counterpartName,
            counterpartRole: managed.counterpartRole,
            notes: managed.notes,
            audioFilePath: managed.audioFilePath,
            transcriptFilePath: managed.transcriptFilePath,
            actionItems: managed.actionItems.map(ActionItemManagedObject.toDomain)
        )
    }
}

private extension PersonalLogManagedObject {
    static func make(from entry: PersonalLogEntry, in context: NSManagedObjectContext, objective: ObjectiveManagedObject? = nil) -> PersonalLogManagedObject {
        let managed = PersonalLogManagedObject(context: context)
        managed.id = entry.id
        managed.entryDate = entry.entryDate
        managed.plannedWork = entry.plannedWork
        managed.reflection = entry.reflection
        managed.moodScore = entry.moodScore
        managed.reminderFrequencyRaw = entry.reminderFrequency.rawValue
        managed.createdAt = entry.entryDate
        managed.updatedAt = Date()
        managed.objective = objective
        managed.actionItems = Set(entry.actionItems.map { ActionItemManagedObject.make(from: $0, in: context, personalLog: managed) })
        return managed
    }

    static func toDomain(_ managed: PersonalLogManagedObject) -> PersonalLogEntry {
        PersonalLogEntry(
            id: managed.id,
            entryDate: managed.entryDate,
            plannedWork: managed.plannedWork,
            reflection: managed.reflection,
            moodScore: managed.moodScore,
            reminderFrequency: ReminderFrequency(rawValue: managed.reminderFrequencyRaw) ?? .daily,
            objectiveID: managed.objective?.id,
            actionItems: managed.actionItems.map(ActionItemManagedObject.toDomain)
        )
    }
}
#endif
