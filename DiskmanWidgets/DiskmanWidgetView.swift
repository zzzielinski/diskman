import DiskmanCore
import SwiftUI
import WidgetKit

struct DiskmanWidgetView: View {
    let entry: DiskmanEntry

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width < 220 {
                smallLayout
            } else {
                largeLayout
            }
        }
        .containerBackground(.ultraThinMaterial, for: .widget)
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
            diskRingLayout
        }
    }

    private var diskRingLayout: some View {
        HStack(spacing: 14) {
            ForEach(entry.snapshot.volumes.prefix(3)) { volume in
                VStack(spacing: 8) {
                    ProgressRing(progress: volume.freeSpaceRatio)
                        .frame(width: 54, height: 54)
                        .overlay {
                            Image(systemName: volume.kind.symbolName)
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(.primary)
                        }

                    Text(volume.freePercentText)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(volume.displayName), \(volume.freePercentText) free")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.22), lineWidth: 8)

            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }

    private var ringColor: Color {
        switch progress {
        case 0.25...:
            return .green
        case 0.10..<0.25:
            return .yellow
        default:
            return .red
        }
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
