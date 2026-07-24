import ActivityKit
import Foundation

@MainActor
enum PassLiveActivityManager {
    private static var updateTask: Task<Void, Never>?

    static func sync(with snapshot: SharedPassSnapshot?) {
        updateTask?.cancel()
        guard let snapshot else {
            endAll()
            return
        }

        let now = Date()
        guard now >= snapshot.startDate.addingTimeInterval(-120), now <= snapshot.endDate else {
            if now > snapshot.endDate { endAll() }
            return
        }

        Task {
            await startOrUpdate(snapshot: snapshot)
            updateTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(15))
                    guard !Task.isCancelled else { return }
                    if Date() > snapshot.endDate {
                        endAll()
                        return
                    }
                    await startOrUpdate(snapshot: snapshot)
                }
            }
        }
    }

    static func endAll() {
        updateTask?.cancel()
        updateTask = nil
        Task {
            for activity in Activity<PassActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
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
