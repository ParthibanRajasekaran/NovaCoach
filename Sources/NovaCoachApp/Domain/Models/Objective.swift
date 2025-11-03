import Foundation

public struct Objective: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var detail: String?
    public var startDate: Date
    public var endDate: Date
    public var keyResults: [KeyResult]
    public var actionItems: [ActionItem]
    public var personalLogs: [PersonalLogEntry]

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        startDate: Date,
        endDate: Date,
        keyResults: [KeyResult] = [],
        actionItems: [ActionItem] = [],
        personalLogs: [PersonalLogEntry] = []
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.startDate = startDate
        self.endDate = endDate
        self.keyResults = keyResults
        self.actionItems = actionItems
        self.personalLogs = personalLogs
    }

    public var completion: Double {
        guard !keyResults.isEmpty else { return 0 }
        let totalProgress = keyResults.reduce(0.0) { partialResult, keyResult in
            partialResult + keyResult.progress
        }
        return min(max(totalProgress / Double(keyResults.count), 0), 1)
    }
}

public struct KeyResult: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var detail: String?
    public var targetValue: Double
    public var currentValue: Double
    public var unit: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        targetValue: Double,
        currentValue: Double,
        unit: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var progress: Double {
        guard targetValue != 0 else { return 0 }
        return min(max(currentValue / targetValue, 0), 1)
    }
}

public struct ActionItem: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var detail: String?
    public var dueDate: Date?
    public var ownerName: String?
    public var status: ActionItemStatus
    public var createdAt: Date
    public var updatedAt: Date
    public var objectiveID: UUID?
    public var oneOnOneID: UUID?
    public var personalLogID: UUID?

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        dueDate: Date? = nil,
        ownerName: String? = nil,
        status: ActionItemStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        objectiveID: UUID? = nil,
        oneOnOneID: UUID? = nil,
        personalLogID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.dueDate = dueDate
        self.ownerName = ownerName
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.objectiveID = objectiveID
        self.oneOnOneID = oneOnOneID
        self.personalLogID = personalLogID
    }
}

public enum ActionItemStatus: String, CaseIterable, Identifiable, Sendable {
    case pending
    case inProgress
    case completed

    public var id: String { rawValue }
}

public struct OneOnOneMeeting: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var meetingDate: Date
    public var counterpartName: String
    public var counterpartRole: String?
    public var notes: String?
    public var audioFilePath: String?
    public var transcriptFilePath: String?
    public var actionItems: [ActionItem]

    public init(
        id: UUID = UUID(),
        meetingDate: Date,
        counterpartName: String,
        counterpartRole: String? = nil,
        notes: String? = nil,
        audioFilePath: String? = nil,
        transcriptFilePath: String? = nil,
        actionItems: [ActionItem] = []
    ) {
        self.id = id
        self.meetingDate = meetingDate
        self.counterpartName = counterpartName
        self.counterpartRole = counterpartRole
        self.notes = notes
        self.audioFilePath = audioFilePath
        self.transcriptFilePath = transcriptFilePath
        self.actionItems = actionItems
    }
}

public struct PersonalLogEntry: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var entryDate: Date
    public var plannedWork: String
    public var reflection: String?
    public var moodScore: Double
    public var reminderFrequency: ReminderFrequency
    public var objectiveID: UUID?
    public var actionItems: [ActionItem]

    public init(
        id: UUID = UUID(),
        entryDate: Date,
        plannedWork: String,
        reflection: String? = nil,
        moodScore: Double = 0,
        reminderFrequency: ReminderFrequency = .daily,
        objectiveID: UUID? = nil,
        actionItems: [ActionItem] = []
    ) {
        self.id = id
        self.entryDate = entryDate
        self.plannedWork = plannedWork
        self.reflection = reflection
        self.moodScore = moodScore
        self.reminderFrequency = reminderFrequency
        self.objectiveID = objectiveID
        self.actionItems = actionItems
    }
}

public enum ReminderFrequency: String, CaseIterable, Identifiable, Sendable {
    case daily
    case everyOtherDay
    case weekly

    public var id: String { rawValue }
}

public struct AnalyticsSnapshot: Sendable {
    public var objectiveProgress: [Objective]
    public var completedActionItems: Int
    public var pendingActionItems: Int
    public var reflectionStreak: Int

    public init(
        objectiveProgress: [Objective],
        completedActionItems: Int,
        pendingActionItems: Int,
        reflectionStreak: Int
    ) {
        self.objectiveProgress = objectiveProgress
        self.completedActionItems = completedActionItems
        self.pendingActionItems = pendingActionItems
        self.reflectionStreak = reflectionStreak
    }
}
