import DiskmanCore
import SwiftUI

struct StorageSegmentBar: View {
    let categories: [StorageCategorySnapshot]
    let totalBytes: Int64
    let localization: LocalizationProvider

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.secondary.opacity(0.12))

                ForEach(positionedSegments(in: proxy.size.width)) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: segment.width)
                        .offset(x: segment.offset)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(.primary.opacity(0.07), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var visibleCategories: [StorageCategorySnapshot] {
        categories
            .filter { $0.bytes > 0 }
            .sortedForStorageBar()
    }

    private func positionedSegments(in width: CGFloat) -> [PositionedStorageSegment] {
        guard totalBytes > 0, width > 0 else { return [] }

        var offset: CGFloat = 0
        return visibleCategories.enumerated().map { index, category in
            let isLast = index == visibleCategories.count - 1
            let ratio = VolumeSnapshot.ratio(category.bytes, totalBytes)
            let rawWidth = isLast ? max(0, width - offset) : width * ratio
            let segmentWidth = ratio > 0 ? max(2, rawWidth) : 0
            defer { offset = min(width, offset + segmentWidth) }

            return PositionedStorageSegment(
                id: category.id.rawValue,
                offset: offset,
                width: min(segmentWidth, max(0, width - offset)),
                color: category.segmentColor
            )
        }
    }

    private var accessibilityText: String {
        visibleCategories
            .map { category in
                "\(localization.categoryName(for: category.id)) \(localization.storageUnitMode.formatter.string(fromByteCount: category.bytes))"
            }
            .joined(separator: ", ")
    }
}

struct StorageSegmentLegend: View {
    let categories: [StorageCategorySnapshot]
    let localization: LocalizationProvider

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(categories.sortedForStorageBar()) { category in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(category.segmentColor)
                            .frame(width: 7, height: 7)

                        Text(localization.categoryName(for: category.id))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
            .layoutPriority(1)

            if containsEstimatedCategories {
                Text(localization.string(.categoryConfidenceEstimated))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.10), in: Capsule())
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var containsEstimatedCategories: Bool {
        categories.contains { $0.confidence == .estimated }
    }
}

private struct PositionedStorageSegment: Identifiable {
    let id: String
    let offset: CGFloat
    let width: CGFloat
    let color: Color
}

private extension Array where Element == StorageCategorySnapshot {
    func sortedForStorageBar() -> [StorageCategorySnapshot] {
        sorted { lhs, rhs in
            lhs.id.storageBarPriority < rhs.id.storageBarPriority
        }
    }
}

private extension StorageCategoryID {
    var storageBarPriority: Int {
        switch self {
        case .applications:
            return 0
        case .documents:
            return 1
        case .developer:
            return 2
        case .iCloudDrive:
            return 3
        case .photos:
            return 4
        case .messages:
            return 5
        case .systemData:
            return 6
        case .other:
            return 7
        case .used:
            return 8
        case .available:
            return 9
        }
    }
}

private extension StorageCategorySnapshot {
    var segmentColor: Color {
        DiskmanPalette.categoryColor(for: id)
    }
}
