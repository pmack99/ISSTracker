import Foundation
import UserNotifications

@MainActor
@Observable
final class PassNotificationService {
    private enum Keys {
        static let enabled = "passNotificationsEnabled"
        static let leadMinutes = "passNotificationLeadMinutes"
    }

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.enabled) }
    }

    var leadTimeMinutes: Int {
        didSet { UserDefaults.standard.set(leadTimeMinutes, forKey: Keys.leadMinutes) }
    }

    var lastScheduleSummary: String?

    init() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)
        let storedLead = UserDefaults.standard.integer(forKey: Keys.leadMinutes)
        leadTimeMinutes = storedLead == 0 ? 10 : storedLead
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func schedulePasses(_ passes: [ISSPass], placeName: String) async {
        lastScheduleSummary = nil
        guard notificationsEnabled else { return }

        await refreshAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            lastScheduleSummary = "Turn on notifications in Settings to get pass reminders."
            return
        }

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let toSchedule = PassNotificationPlanner.passesToSchedule(
            from: passes,
            leadMinutes: leadTimeMinutes
        )
        var scheduled = 0

        for pass in toSchedule {
            let fireDate = PassNotificationPlanner.fireDate(for: pass, leadMinutes: leadTimeMinutes)
            let content = UNMutableNotificationContent()
            content.title = "ISS pass reminder"
            content.body = PassNotificationPlanner.reminderBody(pass: pass, placeName: placeName)
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = PassNotificationPlanner.notificationIdentifier(startUTC: pass.startUTC)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
                scheduled += 1
            } catch {
                continue
            }
        }

        lastScheduleSummary = PassNotificationPlanner.scheduleSummary(
            scheduledCount: scheduled,
            leadMinutes: leadTimeMinutes
        )
    }

    func cancelScheduledPasses() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        lastScheduleSummary = nil
    }
}
