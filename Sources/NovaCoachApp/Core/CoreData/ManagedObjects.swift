#if canImport(CoreData)
import CoreData

@objc(ObjectiveManagedObject)
final class ObjectiveManagedObject: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var detail: String?
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var keyResults: Set<KeyResultManagedObject>
    @NSManaged var actionItems: Set<ActionItemManagedObject>
}

@objc(KeyResultManagedObject)
final class KeyResultManagedObject: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var detail: String?
    @NSManaged var targetValue: Double
    @NSManaged var currentValue: Double
    @NSManaged var unit: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var objective: ObjectiveManagedObject
}

@objc(ActionItemManagedObject)
final class ActionItemManagedObject: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var detail: String?
    @NSManaged var dueDate: Date?
    @NSManaged var ownerName: String?
    @NSManaged var statusRaw: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var objective: ObjectiveManagedObject?
    @NSManaged var oneOnOne: OneOnOneManagedObject?
    @NSManaged var personalLog: PersonalLogManagedObject?
}

@objc(OneOnOneManagedObject)
final class OneOnOneManagedObject: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var meetingDate: Date
    @NSManaged var counterpartName: String
    @NSManaged var counterpartRole: String?
    @NSManaged var notes: String?
    @NSManaged var audioFilePath: String?
    @NSManaged var transcriptFilePath: String?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var actionItems: Set<ActionItemManagedObject>
}

@objc(PersonalLogManagedObject)
final class PersonalLogManagedObject: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var entryDate: Date
    @NSManaged var plannedWork: String
    @NSManaged var reflection: String?
    @NSManaged var moodScore: Double
    @NSManaged var reminderFrequencyRaw: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var objective: ObjectiveManagedObject?
    @NSManaged var actionItems: Set<ActionItemManagedObject>
}

@objc(UserProfileManagedObject)
final class UserProfileManagedObject: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var displayName: String
    @NSManaged var email: String
    @NSManaged var googleUserID: String?
    @NSManaged var appleUserIdentifier: String?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
}
#endif
