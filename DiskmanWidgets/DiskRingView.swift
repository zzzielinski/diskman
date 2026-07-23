import DiskmanCore
import SwiftUI

struct DiskRingView: View {
    let volume: VolumeSnapshot
    let diameter: CGFloat
    let labelStyle: LabelStyle
    let localization: LocalizationProvider

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
                Text(primaryUsageText)
                    .font(.system(size: percentFontSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                if labelStyle == .expanded {
                    Text(secondaryLabelText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(width: max(diameter + 10, minimumWidth))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(localization.freeSpaceAccessibility(for: volume))
    }

    private var ring: some View {
        ZStack {
            Circle()
                .fill(.clear)
                .diskmanGlass(
                    tint: statusColor.opacity(0.10),
                    in: Circle(),
                    strokeOpacity: 0.10
                )
                .padding(lineWidth / 2)

            Circle()
                .stroke(.secondary.opacity(0.16), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: localization.usageRatio(for: volume))
                .stroke(
                    statusColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(.snappy(duration: 0.25), value: localization.usageRatio(for: volume))
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

    private var primaryUsageText: String {
        return "\(localization.usagePercentText(for: volume)) \(localization.usageModeAbbreviation(for: localization.usageDisplayMode))"
    }

    private var secondaryLabelText: String {
        return "\(volume.displayName) - \(localization.usageModeName(for: localization.usageDisplayMode))"
    }

    private var minimumWidth: CGFloat {
        labelStyle == .expanded ? 96 : 54
    }

    private var statusColor: Color {
        return DiskmanPalette.statusColor(forFreeSpaceRatio: volume.freeSpaceRatio)
    }
}

struct AdditionalDisksRingView: View {
    let extraCount: Int
    let diameter: CGFloat
    let localization: LocalizationProvider

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(.clear)
                    .diskmanGlass(in: Circle(), strokeOpacity: 0.10)
                    .padding(lineWidth / 2)

                Circle()
                    .stroke(.secondary.opacity(0.16), lineWidth: lineWidth)

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

            Text(localization.string(.widgetMore))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: max(diameter + 10, 54))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(localization.moreDisksLabel(extraCount))
    }

    private var lineWidth: CGFloat {
        max(5, diameter * 0.12)
    }
}
