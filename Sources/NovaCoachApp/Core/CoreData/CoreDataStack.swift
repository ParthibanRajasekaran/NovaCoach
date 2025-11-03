#if canImport(CoreData)
import CoreData
import OSLog

protocol EncryptionKeyProviding {
    func loadOrCreateKey(identifier: String) throws -> Data
}

final class CoreDataStack: ObservableObject {
    static let modelName = "NovaCoach"
    private static let storeFileName = "NovaCoach.sqlite"
    private let logger = Logger(subsystem: "com.novacoach.app", category: "CoreData")

    let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    init(encryptionKeyProvider: EncryptionKeyProviding) {
        let model = CoreDataStack.makeModel()
        persistentContainer = NSPersistentContainer(name: Self.modelName, managedObjectModel: model)

        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.novacoach.shared") ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true, attributes: nil)
        let sqliteURL = storeURL.appendingPathComponent(Self.storeFileName)

        let description = NSPersistentStoreDescription(url: sqliteURL)
        description.type = NSSQLiteStoreType
        description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        var pragmas: [String: NSObject] = [
            "journal_mode": "WAL" as NSString,
            "secure_delete": "ON" as NSString,
            "cipher_page_size": NSNumber(value: 4096),
            "kdf_iter": NSNumber(value: 256_000)
        ]

        #if ENABLE_SQLCIPHER
        do {
            let keyData = try encryptionKeyProvider.loadOrCreateKey(identifier: "NovaCoach.SQLCipherKey")
            let hexKey = keyData.map { String(format: "%02hhx", $0) }.joined()
            pragmas["key"] = "x'\(hexKey)'" as NSString
        } catch {
            logger.error("Failed to retrieve SQLCipher key: \(error.localizedDescription)")
        }
        #endif

        description.setOption(pragmas as NSDictionary, forKey: NSSQLitePragmasOption)
        persistentContainer.persistentStoreDescriptions = [description]

        persistentContainer.loadPersistentStores { [logger] _, error in
            if let error {
                logger.fault("Failed to load persistent store: \(error.localizedDescription)")
            } else {
                logger.info("Persistent store ready")
            }
        }

        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}

private extension CoreDataStack {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let objectiveEntity = NSEntityDescription()
        objectiveEntity.name = "ObjectiveEntity"
        objectiveEntity.managedObjectClassName = NSStringFromClass(ObjectiveManagedObject.self)

        let keyResultEntity = NSEntityDescription()
        keyResultEntity.name = "KeyResultEntity"
        keyResultEntity.managedObjectClassName = NSStringFromClass(KeyResultManagedObject.self)

        let actionItemEntity = NSEntityDescription()
        actionItemEntity.name = "ActionItemEntity"
        actionItemEntity.managedObjectClassName = NSStringFromClass(ActionItemManagedObject.self)

        let oneOnOneEntity = NSEntityDescription()
        oneOnOneEntity.name = "OneOnOneEntity"
        oneOnOneEntity.managedObjectClassName = NSStringFromClass(OneOnOneManagedObject.self)

        let personalLogEntity = NSEntityDescription()
        personalLogEntity.name = "PersonalLogEntity"
        personalLogEntity.managedObjectClassName = NSStringFromClass(PersonalLogManagedObject.self)

        let userProfileEntity = NSEntityDescription()
        userProfileEntity.name = "UserProfileEntity"
        userProfileEntity.managedObjectClassName = NSStringFromClass(UserProfileManagedObject.self)

        // Attributes
        objectiveEntity.properties = [
            makeUUIDAttribute(named: "id"),
            makeStringAttribute(named: "title"),
            makeStringAttribute(named: "detail", optional: true),
            makeDateAttribute(named: "startDate"),
            makeDateAttribute(named: "endDate"),
            makeDateAttribute(named: "createdAt"),
            makeDateAttribute(named: "updatedAt")
        ]

        keyResultEntity.properties = [
            makeUUIDAttribute(named: "id"),
            makeStringAttribute(named: "title"),
            makeStringAttribute(named: "detail", optional: true),
            makeDoubleAttribute(named: "targetValue"),
            makeDoubleAttribute(named: "currentValue"),
            makeStringAttribute(named: "unit"),
            makeDateAttribute(named: "createdAt"),
            makeDateAttribute(named: "updatedAt")
        ]

        actionItemEntity.properties = [
            makeUUIDAttribute(named: "id"),
            makeStringAttribute(named: "title"),
            makeStringAttribute(named: "detail", optional: true),
            makeDateAttribute(named: "dueDate", optional: true),
            makeStringAttribute(named: "ownerName", optional: true),
            makeStringAttribute(named: "statusRaw"),
            makeDateAttribute(named: "createdAt"),
            makeDateAttribute(named: "updatedAt")
        ]

        oneOnOneEntity.properties = [
            makeUUIDAttribute(named: "id"),
            makeDateAttribute(named: "meetingDate"),
            makeStringAttribute(named: "counterpartName"),
            makeStringAttribute(named: "counterpartRole", optional: true),
            makeStringAttribute(named: "notes", optional: true),
            makeStringAttribute(named: "audioFilePath", optional: true),
            makeStringAttribute(named: "transcriptFilePath", optional: true),
            makeDateAttribute(named: "createdAt"),
            makeDateAttribute(named: "updatedAt")
        ]

        personalLogEntity.properties = [
            makeUUIDAttribute(named: "id"),
            makeDateAttribute(named: "entryDate"),
            makeStringAttribute(named: "plannedWork"),
            makeStringAttribute(named: "reflection", optional: true),
            makeDoubleAttribute(named: "moodScore"),
            makeStringAttribute(named: "reminderFrequencyRaw"),
            makeDateAttribute(named: "createdAt"),
            makeDateAttribute(named: "updatedAt")
        ]

        userProfileEntity.properties = [
            makeUUIDAttribute(named: "id"),
            makeStringAttribute(named: "displayName"),
            makeStringAttribute(named: "email"),
            makeStringAttribute(named: "googleUserID", optional: true),
            makeStringAttribute(named: "appleUserIdentifier", optional: true),
            makeDateAttribute(named: "createdAt"),
            makeDateAttribute(named: "updatedAt")
        ]

        // Relationships
        let objectiveToKeyResults = makeRelationship(name: "keyResults", destination: keyResultEntity, toMany: true, deleteRule: .cascadeDeleteRule)
        let keyResultToObjective = makeRelationship(name: "objective", destination: objectiveEntity, toMany: false, deleteRule: .nullifyDeleteRule)
        objectiveToKeyResults.inverseRelationship = keyResultToObjective
        keyResultToObjective.inverseRelationship = objectiveToKeyResults

        let objectiveToActionItems = makeRelationship(name: "actionItems", destination: actionItemEntity, toMany: true, deleteRule: .nullifyDeleteRule)
        let actionItemToObjective = makeRelationship(name: "objective", destination: objectiveEntity, toMany: false, deleteRule: .nullifyDeleteRule)
        objectiveToActionItems.inverseRelationship = actionItemToObjective
        actionItemToObjective.inverseRelationship = objectiveToActionItems

        let oneOnOneToActionItems = makeRelationship(name: "actionItems", destination: actionItemEntity, toMany: true, deleteRule: .cascadeDeleteRule)
        let actionItemToOneOnOne = makeRelationship(name: "oneOnOne", destination: oneOnOneEntity, toMany: false, deleteRule: .nullifyDeleteRule)
        oneOnOneToActionItems.inverseRelationship = actionItemToOneOnOne
        actionItemToOneOnOne.inverseRelationship = oneOnOneToActionItems

        let personalLogToActionItems = makeRelationship(name: "actionItems", destination: actionItemEntity, toMany: true, deleteRule: .nullifyDeleteRule)
        let actionItemToPersonalLog = makeRelationship(name: "personalLog", destination: personalLogEntity, toMany: false, deleteRule: .nullifyDeleteRule)
        personalLogToActionItems.inverseRelationship = actionItemToPersonalLog
        actionItemToPersonalLog.inverseRelationship = personalLogToActionItems

        let personalLogToObjective = makeRelationship(name: "objective", destination: objectiveEntity, toMany: false, deleteRule: .nullifyDeleteRule)
        let objectiveToPersonalLogs = makeRelationship(name: "personalLogs", destination: personalLogEntity, toMany: true, deleteRule: .nullifyDeleteRule)
        personalLogToObjective.inverseRelationship = objectiveToPersonalLogs
        objectiveToPersonalLogs.inverseRelationship = personalLogToObjective

        objectiveEntity.properties.append(contentsOf: [objectiveToKeyResults, objectiveToActionItems, objectiveToPersonalLogs])
        keyResultEntity.properties.append(keyResultToObjective)
        actionItemEntity.properties.append(contentsOf: [actionItemToObjective, actionItemToOneOnOne, actionItemToPersonalLog])
        oneOnOneEntity.properties.append(oneOnOneToActionItems)
        personalLogEntity.properties.append(contentsOf: [personalLogToActionItems, personalLogToObjective])

        model.entities = [objectiveEntity, keyResultEntity, actionItemEntity, oneOnOneEntity, personalLogEntity, userProfileEntity]
        return model
    }

    static func makeStringAttribute(named name: String, optional: Bool = false) -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = .stringAttributeType
        description.isOptional = optional
        return description
    }

    static func makeUUIDAttribute(named name: String) -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = .UUIDAttributeType
        description.isOptional = false
        return description
    }

    static func makeDateAttribute(named name: String, optional: Bool = false) -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = .dateAttributeType
        description.isOptional = optional
        return description
    }

    static func makeDoubleAttribute(named name: String) -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = .doubleAttributeType
        description.isOptional = false
        return description
    }

    static func makeRelationship(name: String, destination: NSEntityDescription, toMany: Bool, deleteRule: NSDeleteRule) -> NSRelationshipDescription {
        let relationship = NSRelationshipDescription()
        relationship.name = name
        relationship.destinationEntity = destination
        relationship.deleteRule = deleteRule
        relationship.minCount = 0
        relationship.maxCount = toMany ? 0 : 1
        relationship.isOptional = true
        relationship.isToMany = toMany
        return relationship
    }
}
#endif
