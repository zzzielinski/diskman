import DiskmanCore
import SwiftUI
import WidgetKit

struct DiskmanEntry: TimelineEntry {
    let date: Date
    let snapshot: DiskSnapshot
    let state: DiskmanEntryState

    static let placeholder = DiskmanEntry(
        date: Date(),
        snapshot: .placeholder,
        state: .placeholder
    )
}

enum DiskmanEntryState {
    case placeholder
    case loaded
    case missingSnapshot
    case readError
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
        do {
            if let snapshot = try snapshotStore.read() {
                return DiskmanEntry(
                    date: Date(),
                    snapshot: snapshot,
                    state: .loaded
                )
            }

            return DiskmanEntry(
                date: Date(),
                snapshot: .empty,
                state: .missingSnapshot
            )
        } catch {
            return DiskmanEntry(
                date: Date(),
                snapshot: .empty,
                state: .readError
            )
        }
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
