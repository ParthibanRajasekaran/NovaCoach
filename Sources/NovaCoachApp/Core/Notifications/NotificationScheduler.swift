import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

protocol NotificationScheduling {
    func scheduleReminder(identifier: String, title: String, body: String, date: Date) async throws
    func cancel(identifier: String) async
}

final class NotificationScheduler: NotificationScheduling {
    func scheduleReminder(identifier: String, title: String, body: String, date: Date) async throws {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
        #else
        // no-op on unsupported platforms
        _ = identifier
        _ = title
        _ = body
        _ = date
        #endif
    }

    func cancel(identifier: String) async {
        #if canImport(UserNotifications)
        await UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        #else
        _ = identifier
        #endif
    }
}
