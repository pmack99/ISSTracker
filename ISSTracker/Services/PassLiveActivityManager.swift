import ActivityKit
import Foundation

@MainActor
enum PassLiveActivityManager {
    private static var syncTask: Task<Void, Never>?

    static func sync(with snapshot: SharedPassSnapshot?) {
        syncTask?.cancel()
        syncTask = Task {
            await endAllActivities()

            guard !Task.isCancelled, let snapshot else { return }

            let now = Date()
            guard now >= snapshot.startDate.addingTimeInterval(-120), now <= snapshot.endDate else {
                if now > snapshot.endDate {
                    await endAllActivities()
                }
                return
            }

            await startOrUpdate(snapshot: snapshot)

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                if Date() > snapshot.endDate {
                    await endAllActivities()
                    return
                }
                await startOrUpdate(snapshot: snapshot)
            }
        }
    }

    static func endAll() {
        syncTask?.cancel()
        syncTask = Task {
            await endAllActivities()
        }
    }

    private static func endAllActivities() async {
        for activity in Activity<PassActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func startOrUpdate(snapshot: SharedPassSnapshot) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = PassActivityAttributes.ContentState(
            endDate: snapshot.endDate,
            statusLine: statusLine(for: snapshot)
        )
        let attributes = PassActivityAttributes(
            placeName: snapshot.placeName,
            startAzCompass: snapshot.startAzCompass
        )

        if let existing = Activity<PassActivityAttributes>.activities.first {
            await existing.update(.init(state: state, staleDate: snapshot.endDate))
            return
        }

        let content = ActivityContent(state: state, staleDate: snapshot.endDate)
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            return
        }
    }

    private static func statusLine(for snapshot: SharedPassSnapshot) -> String {
        let now = Date()
        if now < snapshot.startDate {
            let minutes = Int(snapshot.startDate.timeIntervalSince(now) / 60)
            return "Starts in \(minutes)m · look \(snapshot.startAzCompass)"
        }
        let remaining = max(0, Int(snapshot.endDate.timeIntervalSince(now)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        if minutes > 0 {
            return "ISS visible now · \(minutes)m \(seconds)s left"
        }
        return "ISS visible now · \(seconds)s left"
    }
}
