import DiskmanCore
import SwiftUI
import WidgetKit

struct DiskmanEntry: TimelineEntry {
    let date: Date
    let snapshot: DiskSnapshot

    static let placeholder = DiskmanEntry(
        date: Date(),
        snapshot: .placeholder
    )
}

struct DiskmanTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DiskmanEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DiskmanEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DiskmanEntry>) -> Void) {
        let nextRefresh = Date().addingTimeInterval(5 * 60)
        let timeline = Timeline<DiskmanEntry>(
            entries: [DiskmanEntry.placeholder],
            policy: .after(nextRefresh)
        )
        completion(timeline)
    }
}

struct DiskmanWidget: Widget {
    let kind = "DiskmanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DiskmanTimelineProvider()) { entry in
            DiskmanWidgetView(entry: entry)
        }
        .configurationDisplayName("Diskman")
        .description("Monitor connected disks and free space.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
