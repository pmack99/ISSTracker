import SwiftUI
import WidgetKit

@main
struct ISSTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextPassWidget()
        PassLiveActivityWidget()
    }
}
