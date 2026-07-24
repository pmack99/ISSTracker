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

        let lead = TimeInterval(leadTimeMinutes * 60)
        var scheduled = 0
        let limit = 32

        for pass in passes {
            guard scheduled < limit else { break }

            let fireDate = pass.startDate.addingTimeInterval(-lead)
            guard fireDate > Date().addingTimeInterval(5) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "ISS pass reminder"
            content.body = reminderBody(pass: pass, placeName: placeName)
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = Self.identifier(for: pass.startUTC)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
                scheduled += 1
            } catch {
                continue
            }
        }

        if scheduled == 0 {
            lastScheduleSummary = "No upcoming passes were far enough out to schedule (\(leadTimeMinutes) min notice)."
        } else {
            lastScheduleSummary = "Scheduled \(scheduled) reminder\(scheduled == 1 ? "" : "s") (\(leadTimeMinutes) min before each pass)."
        }
    }

    func cancelScheduledPasses() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        lastScheduleSummary = nil
    }

    private func reminderBody(pass: ISSPass, placeName: String) -> String {
        let time = pass.startDate.formatted(date: .omitted, time: .shortened)
        let maxEl = String(format: "%.0f", pass.maxEl)
        return "Pass over \(placeName) at \(time). Look \(pass.startAzCompass), up to \(maxEl)°."
    }

    private static func identifier(for startUTC: TimeInterval) -> String {
        "iss-pass-\(Int(startUTC))"
    }
}
