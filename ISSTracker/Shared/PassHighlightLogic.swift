import Foundation

enum PassHighlightLogic {
    static func endOfTonight(calendar: Calendar = .current, now: Date = .now) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday)
            ?? now.addingTimeInterval(86_400)
    }

    static func isTonight(_ date: Date, calendar: Calendar = .current, now: Date = .now) -> Bool {
        date >= now && date < endOfTonight(calendar: calendar, now: now)
    }

    static func nextPassTonight(from passes: [ISSPass], now: Date = .now, calendar: Calendar = .current) -> ISSPass? {
        let cutoff = endOfTonight(calendar: calendar, now: now)
        return passes
            .filter { $0.startDate >= now && $0.startDate < cutoff }
            .min(by: { $0.startUTC < $1.startUTC })
    }

    static func nextUpcomingPass(from passes: [ISSPass], now: Date = .now) -> ISSPass? {
        passes
            .filter { $0.startDate >= now }
            .min(by: { $0.startUTC < $1.startUTC })
    }
}
