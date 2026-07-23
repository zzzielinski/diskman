import DiskmanCore
import SwiftUI
import WidgetKit

struct DiskmanWidgetView: View {
    let entry: DiskmanEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall:
                smallLayout
            default:
                largeLayout
            }
        }
        .containerBackground(for: .widget) {
            WidgetGlassBackground()
        }
    }

    @ViewBuilder
    private var smallLayout: some View {
        if entry.snapshot.volumes.isEmpty {
            unavailableView
        } else {
            SmallDiskRingLayout(
                volumes: entry.snapshot.volumes,
                localization: entry.localization
            )
        }
    }

    @ViewBuilder
    private var largeLayout: some View {
        if entry.snapshot.volumes.isEmpty {
            unavailableView
        } else {
            DiskStorageListLayout(
                volumes: entry.snapshot.volumes,
                widgetFamily: widgetFamily,
                localization: entry.localization
            )
        }
    }

    private var unavailableView: some View {
        ContentUnavailableView(
            unavailableTitle,
            systemImage: unavailableSymbolName,
            description: Text(unavailableDescription)
        )
    }

    private var unavailableTitle: String {
        switch entry.state {
        case .readError:
            return entry.localization.string(.widgetUnableToLoad)
        case .missingSnapshot:
            return entry.localization.string(.widgetNoData)
        default:
            return entry.localization.string(.widgetNoDisks)
        }
    }

    private var unavailableSymbolName: String {
        switch entry.state {
        case .readError:
            return "externaldrive.badge.exclamationmark"
        default:
            return "internaldrive"
        }
    }

    private var unavailableDescription: String {
        switch entry.state {
        case .readError:
            return entry.localization.string(.widgetOpenDiskmanRebuild)
        default:
            return entry.localization.string(.widgetOpenDiskmanRefresh)
        }
    }
}

private struct SmallDiskRingLayout: View {
    let volumes: [VolumeSnapshot]
    let localization: LocalizationProvider

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            Group {
                switch volumes.count {
                case 1:
                    singleDiskLayout
                case 2:
                    twoDiskLayout
                default:
                    gridLayout
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .padding(12)
    }

    private var singleDiskLayout: some View {
        VolumeLink(volume: volumes[0]) {
            DiskRingView(
                volume: volumes[0],
                diameter: 82,
                labelStyle: .expanded,
                localization: localization
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var twoDiskLayout: some View {
        HStack(spacing: 10) {
            ForEach(volumes.prefix(2)) { volume in
                VolumeLink(volume: volume) {
                    DiskRingView(
                        volume: volume,
                        diameter: 58,
                        labelStyle: .compact,
                        localization: localization
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var gridLayout: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(gridVolumes) { volume in
                VolumeLink(volume: volume) {
                    DiskRingView(
                        volume: volume,
                        diameter: 42,
                        labelStyle: .compact,
                        localization: localization
                    )
                }
            }

            if extraDiskCount > 0 {
                AdditionalDisksRingView(
                    extraCount: extraDiskCount,
                    diameter: 42,
                    localization: localization
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var gridVolumes: [VolumeSnapshot] {
        let visibleCount = extraDiskCount > 0 ? 3 : 4
        return Array(volumes.prefix(visibleCount))
    }

    private var extraDiskCount: Int {
        volumes.count > 4 ? volumes.count - 3 : 0
    }
}

private struct DiskStorageListLayout: View {
    let volumes: [VolumeSnapshot]
    let widgetFamily: WidgetFamily
    let localization: LocalizationProvider

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(visibleVolumes) { volume in
                VolumeLink(volume: volume) {
                    DiskStorageRow(
                        volume: volume,
                        isLarge: isLarge,
                        localization: localization
                    )
                }
            }

            if hiddenVolumeCount > 0 {
                Text(localization.moreDisksLabel(hiddenVolumeCount))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .accessibilityLabel(localization.moreDisksLabel(hiddenVolumeCount))
            }

            Spacer(minLength: 0)

            if let legendCategories {
                StorageSegmentLegend(
                    categories: legendCategories,
                    localization: localization
                )
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(isLarge ? 18 : 14)
    }

    private var visibleVolumes: [VolumeSnapshot] {
        Array(volumes.prefix(maxVisibleVolumes))
    }

    private var maxVisibleVolumes: Int {
        isLarge ? 5 : 3
    }

    private var hiddenVolumeCount: Int {
        max(0, volumes.count - maxVisibleVolumes)
    }

    private var legendCategories: [StorageCategorySnapshot]? {
        visibleVolumes.first?.categories
    }

    private var spacing: CGFloat {
        isLarge ? 13 : 11
    }

    private var isLarge: Bool {
        widgetFamily == .systemLarge
    }
}

private struct VolumeLink<Content: View>: View {
    let volume: VolumeSnapshot
    @ViewBuilder let content: Content

    var body: some View {
        if let url = volume.openInFinderURL {
            Link(destination: url) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

private extension VolumeSnapshot {
    var openInFinderURL: URL? {
        var components = URLComponents()
        components.scheme = "diskman"
        components.host = "open-volume"
        components.queryItems = [
            URLQueryItem(name: "path", value: mountPath)
        ]
        return components.url
    }
}

private struct DiskStorageRow: View {
    let volume: VolumeSnapshot
    let isLarge: Bool
    let localization: LocalizationProvider

    var body: some View {
        let capacitySummary = localization.capacitySummary(for: volume)

        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Label(volume.displayName, systemImage: volume.kind.symbolName)
                    .font(.system(size: isLarge ? 15 : 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Spacer(minLength: 8)

                Text(capacitySummary)
                    .font(.system(size: isLarge ? 12 : 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            StorageSegmentBar(
                categories: volume.categories,
                totalBytes: volume.totalBytes,
                localization: localization
            )
            .frame(height: isLarge ? 14 : 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(volume.displayName), \(capacitySummary)")
    }
}

private struct WidgetGlassBackground: View {
    var body: some View {
        Color.clear
            .diskmanGlass(
                tint: .white.opacity(0.04),
                in: ContainerRelativeShape(),
                strokeOpacity: 0.14
            )
    }
}

#Preview(as: .systemSmall) {
    DiskmanWidget()
} timeline: {
    DiskmanEntry.placeholder
}

#Preview(as: .systemMedium) {
    DiskmanWidget()
} timeline: {
    DiskmanEntry.placeholder
}

#Preview(as: .systemLarge) {
    DiskmanWidget()
} timeline: {
    DiskmanEntry.placeholder
}
