import Foundation
import Testing
@testable import ISSTracker

struct PassHighlightLogicTests {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 24, hour: hour, minute: minute))!
    }

    @Test func nextPassTonightPicksSoonestBeforeMidnight() {
        let now = date(18)
        let passes = [
            samplePass(startHour: 20),
            samplePass(startHour: 22),
            samplePass(startHour: 23, minute: 30),
        ]

        let tonight = PassHighlightLogic.nextPassTonight(from: passes, now: now, calendar: calendar)
        #expect(tonight?.startUTC == passes[0].startUTC)
    }

    @Test func nextPassTonightIgnoresPassesAfterMidnight() {
        let now = date(22)
        let eveningPass = samplePass(startHour: 23, minute: 30)
        let tomorrowStart = calendar.date(from: DateComponents(year: 2026, month: 7, day: 25, hour: 1))!
        let tomorrowPass = ISSPass(
            startUTC: tomorrowStart.timeIntervalSince1970,
            endUTC: tomorrowStart.addingTimeInterval(300).timeIntervalSince1970,
            duration: 300,
            startAzCompass: "N",
            endAzCompass: "E",
            startEl: 1,
            maxEl: 20
        )

        let tonight = PassHighlightLogic.nextPassTonight(
            from: [eveningPass, tomorrowPass],
            now: now,
            calendar: calendar
        )
        #expect(tonight?.startUTC == eveningPass.startUTC)
    }

    private func samplePass(startHour: Int, minute: Int = 0) -> ISSPass {
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 24, hour: startHour, minute: minute))!
        return ISSPass(
            startUTC: start.timeIntervalSince1970,
            endUTC: start.addingTimeInterval(300).timeIntervalSince1970,
            duration: 300,
            startAzCompass: "NW",
            endAzCompass: "SE",
            startEl: 5,
            maxEl: 40,
            magnitude: -2
        )
    }
}
