import Foundation
import Testing
@testable import ISSTracker

struct WidgetPassSyncServiceTests {
    @Test func passStartMatchesWithinOneSecond() {
        #expect(WidgetPassSyncService.passStartMatches(1_700_000_000, 1_700_000_000.5))
        #expect(!WidgetPassSyncService.passStartMatches(1_700_000_000, 1_700_000_002))
    }
}
