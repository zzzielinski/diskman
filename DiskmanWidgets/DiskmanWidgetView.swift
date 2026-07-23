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
            ContentUnavailableView(
                "No Disks",
                systemImage: "internaldrive",
                description: Text("Open Diskman to refresh storage data.")
            )
        } else {
            SmallDiskRingLayout(volumes: entry.snapshot.volumes)
        }
    }

    @ViewBuilder
    private var largeLayout: some View {
        if entry.snapshot.volumes.isEmpty {
            ContentUnavailableView(
                "No Disks",
                systemImage: "internaldrive",
                description: Text("Open Diskman to refresh storage data.")
            )
        } else {
            diskBarLayout
        }
    }

    private var diskBarLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(entry.snapshot.volumes.prefix(3)) { volume in
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Label(volume.displayName, systemImage: volume.kind.symbolName)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(volume.capacitySummary)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    StorageBar(usedRatio: volume.usedSpaceRatio)
                        .frame(height: 12)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(volume.displayName), \(volume.capacitySummary)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

private struct SmallDiskRingLayout: View {
    let volumes: [VolumeSnapshot]

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
        DiskRingView(
            volume: volumes[0],
            diameter: 82,
            labelStyle: .expanded
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var twoDiskLayout: some View {
        HStack(spacing: 10) {
            ForEach(volumes.prefix(2)) { volume in
                DiskRingView(
                    volume: volume,
                    diameter: 58,
                    labelStyle: .compact
                )
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
                DiskRingView(
                    volume: volume,
                    diameter: 42,
                    labelStyle: .compact
                )
            }

            if extraDiskCount > 0 {
                AdditionalDisksRingView(
                    extraCount: extraDiskCount,
                    diameter: 42
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

private struct StorageBar: View {
    let usedRatio: Double

    var body: some View {
        GeometryReader { proxy in
            let clampedUsed = max(0, min(usedRatio, 1))
            let usedWidth = proxy.size.width * clampedUsed

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.22))

                Capsule()
                    .fill(.blue)
                    .frame(width: max(8, usedWidth))
            }
        }
    }
}

private struct WidgetGlassBackground: View {
    var body: some View {
        ContainerRelativeShape()
            .fill(.ultraThinMaterial)
            .overlay {
                ContainerRelativeShape()
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
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
