import DiskmanCore
import SwiftUI

struct DiskRingView: View {
    let volume: VolumeSnapshot
    let diameter: CGFloat
    let labelStyle: LabelStyle

    enum LabelStyle {
        case compact
        case expanded
    }

    var body: some View {
        VStack(spacing: labelStyle == .expanded ? 8 : 4) {
            ring
                .frame(width: diameter, height: diameter)
                .overlay {
                    Image(systemName: volume.kind.symbolName)
                        .font(.system(size: iconSize, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary)
                }

            VStack(spacing: 1) {
                Text(volume.freePercentText)
                    .font(.system(size: percentFontSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if labelStyle == .expanded {
                    Text(volume.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(width: max(diameter + 10, minimumWidth))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(volume.displayName), \(volume.freePercentText) free")
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.18), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: volume.freeSpaceRatio)
                .stroke(
                    statusColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(.snappy(duration: 0.25), value: volume.freeSpaceRatio)
    }

    private var lineWidth: CGFloat {
        max(5, diameter * 0.12)
    }

    private var iconSize: CGFloat {
        max(15, diameter * 0.38)
    }

    private var percentFontSize: CGFloat {
        labelStyle == .expanded ? 20 : 13
    }

    private var minimumWidth: CGFloat {
        labelStyle == .expanded ? 96 : 54
    }

    private var statusColor: Color {
        switch volume.freeSpaceRatio {
        case 0.25...:
            return .green
        case 0.10..<0.25:
            return .yellow
        default:
            return .red
        }
    }
}

struct AdditionalDisksRingView: View {
    let extraCount: Int
    let diameter: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.18), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(
                        .secondary,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("+\(extraCount)")
                    .font(.system(size: max(13, diameter * 0.28), weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: diameter, height: diameter)

            Text("more")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: max(diameter + 10, 54))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(extraCount) more disks")
    }

    private var lineWidth: CGFloat {
        max(5, diameter * 0.12)
    }
}
