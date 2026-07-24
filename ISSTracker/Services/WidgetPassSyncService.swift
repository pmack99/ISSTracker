import Foundation
import WidgetKit

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

    static func publish(passes: [ISSPass], placeName: String) {
        let snapshot = snapshot(from: passes, placeName: placeName)
        SharedPassStorage.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func publish(snapshot: SharedPassSnapshot?) {
        SharedPassStorage.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func makeSnapshot(pass: ISSPass, placeName: String) -> SharedPassSnapshot {
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
