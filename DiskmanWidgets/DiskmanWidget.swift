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
    private let snapshotStore = StorageSnapshotStore()

    func placeholder(in context: Context) -> DiskmanEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DiskmanEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DiskmanEntry>) -> Void) {
        let nextRefresh = Date().addingTimeInterval(5 * 60)
        let timeline = Timeline<DiskmanEntry>(
            entries: [entry()],
            policy: .after(nextRefresh)
        )
        completion(timeline)
    }

    private func entry() -> DiskmanEntry {
        DiskmanEntry(
            date: Date(),
            snapshot: snapshotStore.readOrPlaceholder()
        )
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
