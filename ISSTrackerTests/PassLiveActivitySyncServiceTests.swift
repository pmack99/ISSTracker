import Foundation
import Testing
@testable import ISSTracker

struct PassLiveActivitySyncServiceTests {
    @Test func passStartMatchesWithinOneSecond() {
        #expect(PassLiveActivitySyncService.passStartMatches(1_700_000_000, 1_700_000_000.5))
        #expect(!PassLiveActivitySyncService.passStartMatches(1_700_000_000, 1_700_000_002))
    }
}
