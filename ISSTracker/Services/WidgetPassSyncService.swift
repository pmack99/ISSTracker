import Foundation
import WidgetKit

@MainActor
enum WidgetPassSyncService {
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

    /// Canonical update after a pass search (clears manual pass tracking).
    static func publishFromSearch(passes: [ISSPass], placeName: String) {
        SharedPassStorage.saveTrackedPassStartUTC(nil)
        let snapshot = snapshot(from: passes, placeName: placeName)
        publish(snapshot: snapshot)
        PassLiveActivityManager.sync(with: snapshot)
    }

    static func publish(snapshot: SharedPassSnapshot?) {
        SharedPassStorage.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// User chose a specific pass on the detail screen.
    static func setTrackedPass(_ pass: ISSPass, placeName: String) {
        let snapshot = makeSnapshot(pass: pass, placeName: placeName)
        SharedPassStorage.saveTrackedPassStartUTC(pass.startUTC)
        publish(snapshot: snapshot)
        PassLiveActivityManager.sync(with: snapshot)
    }

    static func clearTrackedPass(matching pass: ISSPass) {
        guard SharedPassStorage.loadTrackedPassStartUTC() == pass.startUTC else { return }
        SharedPassStorage.saveTrackedPassStartUTC(nil)
        publish(snapshot: nil)
        PassLiveActivityManager.endAll()
    }

    static func clearWidgetAndLiveActivity() {
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
}
