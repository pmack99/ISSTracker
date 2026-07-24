import ActivityKit
import SwiftUI
import WidgetKit

struct PassLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PassActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 6) {
                Text("ISS Tracker")
                    .font(.caption.weight(.semibold))
                Text(context.state.statusLine)
                    .font(.headline)
                Text("\(context.attributes.placeName) · look \(context.attributes.startAzCompass)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.05, green: 0.08, blue: 0.16))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "globe.americas.fill")
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.statusLine)
                        .font(.caption)
                        .lineLimit(2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startAzCompass)
                        .font(.caption.weight(.bold))
                }
            } compactLeading: {
                Image(systemName: "dot.radiowaves.left.and.right")
            } compactTrailing: {
                Text(context.attributes.startAzCompass)
                    .font(.caption2)
            } minimal: {
                Image(systemName: "dot.radiowaves.left.and.right")
            }
        }
    }
}
