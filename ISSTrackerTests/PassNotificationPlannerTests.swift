import Foundation
import Testing
@testable import ISSTracker

struct PassNotificationPlannerTests {
    private func pass(startOffset: TimeInterval) -> ISSPass {
        let start = Date(timeIntervalSince1970: 1_700_000_000 + startOffset)
        return ISSPass(
            startUTC: start.timeIntervalSince1970,
            endUTC: start.addingTimeInterval(300).timeIntervalSince1970,
            duration: 300,
            startAzCompass: "NW",
            endAzCompass: "SE",
            startEl: 5,
            maxEl: 35,
            magnitude: -1
        )
    }

    @Test func shouldScheduleWhenFireDateIsFarEnoughOut() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fire = now.addingTimeInterval(600)
        #expect(PassNotificationPlanner.shouldSchedule(fireDate: fire, now: now))
    }

    @Test func skipsWhenFireDateIsTooSoon() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fire = now.addingTimeInterval(2)
        #expect(!PassNotificationPlanner.shouldSchedule(fireDate: fire, now: now))
    }

    @Test func passesToScheduleRespectsLeadTimeAndLimit() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let passes = (1 ... 40).map { pass(startOffset: TimeInterval($0 * 3600)) }
        let selected = PassNotificationPlanner.passesToSchedule(
            from: passes,
            leadMinutes: 10,
            now: now,
            limit: 5
        )
        #expect(selected.count == 5)
    }

    @Test func reminderBodyIncludesDirectionAndElevation() {
        let pass = pass(startOffset: 3600)
        let body = PassNotificationPlanner.reminderBody(pass: pass, placeName: "Orlando")
        #expect(body.contains("Orlando"))
        #expect(body.contains("NW"))
        #expect(body.contains("35"))
    }

    @Test func scheduleSummaryUsesSingularGrammar() {
        #expect(PassNotificationPlanner.scheduleSummary(scheduledCount: 1, leadMinutes: 10).contains("1 reminder"))
    }
}
