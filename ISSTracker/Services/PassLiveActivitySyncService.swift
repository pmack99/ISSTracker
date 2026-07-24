import Foundation

@MainActor
enum PassLiveActivitySyncService {
    static func snapshot(from passes: [ISSPass], placeName: String) -> SharedPassSnapshot? {
        let now = Date()
        let sorted = passes.sorted { $0.startDate < $1.startDate }

        if let active = sorted.first(where: { now >= $0.startDate && now <= $0.endDate }) {
            return makeSnapshot(pass: active, placeName: placeName)
        }
        if let next = sorted.first(where: { $0.startDate > now }) {
            return makeSnapshot(pass: next, placeName: placeName)
        }
        return nil
    }

    /// After a pass search: sync Live Activity to the next pass (does not mark pass detail toggle on).
    static func publishFromSearch(passes: [ISSPass], placeName: String) {
        SharedPassStorage.saveTrackedPassStartUTC(nil)
        let snapshot = snapshot(from: passes, placeName: placeName)
        publish(snapshot: snapshot)
        PassLiveActivityManager.sync(with: snapshot)
    }

    static func publish(snapshot: SharedPassSnapshot?) {
        SharedPassStorage.save(snapshot)
    }

    /// User enabled Live Activity for this pass on the detail screen.
    static func setTrackedPass(_ pass: ISSPass, placeName: String) {
        let snapshot = makeSnapshot(pass: pass, placeName: placeName)
        SharedPassStorage.saveTrackedPassStartUTC(pass.startUTC)
        publish(snapshot: snapshot)
        PassLiveActivityManager.sync(with: snapshot)
    }

    static func clearTrackedPass(matching pass: ISSPass) {
        guard liveActivityShowsPass(pass) else { return }
        SharedPassStorage.saveTrackedPassStartUTC(nil)
        publish(snapshot: nil)
        PassLiveActivityManager.endAll()
    }

    static func clearPassTrackingAndLiveActivity() {
        SharedPassStorage.saveTrackedPassStartUTC(nil)
        publish(snapshot: nil)
        PassLiveActivityManager.endAll()
    }

    static func makeSnapshot(pass: ISSPass, placeName: String) -> SharedPassSnapshot {
        SharedPassSnapshot(
            placeName: placeName,
            startUTC: pass.startUTC,
            endUTC: pass.endUTC,
            startAzCompass: pass.startAzCompass,
            maxEl: pass.maxEl,
            updatedAt: Date().timeIntervalSince1970
        )
    }

    /// Pass detail toggle: on only if the user explicitly enabled Live Activity for this pass.
    static func isLiveActivityEnabled(for pass: ISSPass) -> Bool {
        guard let tracked = SharedPassStorage.loadTrackedPassStartUTC() else { return false }
        return passStartMatches(tracked, pass.startUTC)
    }

    nonisolated static func passStartMatches(_ lhs: TimeInterval, _ rhs: TimeInterval) -> Bool {
        abs(lhs - rhs) < 1.0
    }

    private static func liveActivityShowsPass(_ pass: ISSPass) -> Bool {
        if let tracked = SharedPassStorage.loadTrackedPassStartUTC(),
           passStartMatches(tracked, pass.startUTC) {
            return true
        }
        if let snapshot = SharedPassStorage.load(),
           passStartMatches(snapshot.startUTC, pass.startUTC) {
            return true
        }
        return false
    }
}
