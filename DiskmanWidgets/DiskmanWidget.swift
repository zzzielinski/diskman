import DiskmanCore
import SwiftUI
import WidgetKit

struct DiskmanEntry: TimelineEntry, Sendable {
    let date: Date
    let snapshot: DiskSnapshot
    let state: DiskmanEntryState
    let localization: LocalizationProvider

    static let placeholder = DiskmanEntry(
        date: Date(),
        snapshot: .placeholder,
        state: .placeholder,
        localization: LocalizationProvider()
    )
}

enum DiskmanEntryState: Sendable {
    case placeholder
    case loaded
    case missingSnapshot
    case readError
}

struct DiskmanTimelineProvider: TimelineProvider {
    private let snapshotStore = StorageSnapshotStore()
    private let settingsStore = DiskmanSettingsStore()
    private let volumeProvider = VolumeProvider()
    private let categoryScanner = EstimatedStorageCategoryScanner()
    private let categoryCacheStore = StorageCategoryCacheStore()

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
                    state: .loaded,
                    localization: localization
                )
            }
        } catch {
            if let snapshot = liveSnapshot() {
                return DiskmanEntry(
                    date: Date(),
                    snapshot: snapshot,
                    state: .loaded,
                    localization: localization
                )
            }

            return DiskmanEntry(
                date: Date(),
                snapshot: .empty,
                state: .readError,
                localization: localization
            )
        }

        guard let snapshot = liveSnapshot() else {
            return DiskmanEntry(
                date: Date(),
                snapshot: .empty,
                state: .missingSnapshot,
                localization: localization
            )
        }

        return DiskmanEntry(
            date: Date(),
            snapshot: snapshot,
            state: .loaded,
            localization: localization
        )
    }

    private func liveSnapshot() -> DiskSnapshot? {
        try? volumeProvider
            .snapshot()
            .applyingCategoryMode(
                settingsStore.categoryMode,
                scanner: categoryScanner,
                cacheStore: categoryCacheStore
            )
            .filtered(visibleKinds: settingsStore.visibleVolumeKinds)
    }

    private var localization: LocalizationProvider {
        LocalizationProvider(settingsStore: settingsStore)
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
