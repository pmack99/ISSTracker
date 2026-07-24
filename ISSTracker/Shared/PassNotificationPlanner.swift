import Foundation

enum PassNotificationPlanner {
    static let defaultScheduleLimit = 32
    static let minimumFireLeadSeconds: TimeInterval = 5

    static func fireDate(for pass: ISSPass, leadMinutes: Int) -> Date {
        pass.startDate.addingTimeInterval(-TimeInterval(leadMinutes * 60))
    }

    static func shouldSchedule(fireDate: Date, now: Date = .now) -> Bool {
        fireDate > now.addingTimeInterval(minimumFireLeadSeconds)
    }

    static func passesToSchedule(
        from passes: [ISSPass],
        leadMinutes: Int,
        now: Date = .now,
        limit: Int = defaultScheduleLimit
    ) -> [ISSPass] {
        var scheduled: [ISSPass] = []
        for pass in passes {
            guard scheduled.count < limit else { break }
            let fire = fireDate(for: pass, leadMinutes: leadMinutes)
            if shouldSchedule(fireDate: fire, now: now) {
                scheduled.append(pass)
            }
        }
        return scheduled
    }

    static func reminderBody(pass: ISSPass, placeName: String) -> String {
        let time = pass.startDate.formatted(date: .omitted, time: .shortened)
        let maxEl = String(format: "%.0f", pass.maxEl)
        return "Pass over \(placeName) at \(time). Look \(pass.startAzCompass), up to \(maxEl)°."
    }

    static func notificationIdentifier(startUTC: TimeInterval) -> String {
        "iss-pass-\(Int(startUTC))"
    }

    static func scheduleSummary(scheduledCount: Int, failedCount: Int = 0, leadMinutes: Int) -> String {
        if scheduledCount == 0 {
            if failedCount > 0 {
                return "Could not schedule pass reminders (\(failedCount) failed). Check notification settings."
            }
            return "No upcoming passes were far enough out to schedule (\(leadMinutes) min notice)."
        }
        let noun = scheduledCount == 1 ? "reminder" : "reminders"
        var summary = "Scheduled \(scheduledCount) \(noun) (\(leadMinutes) min before each pass)."
        if failedCount > 0 {
            summary += " \(failedCount) could not be scheduled."
        }
        return summary
    }
}
