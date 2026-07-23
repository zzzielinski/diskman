import DiskmanCore
import SwiftUI

struct DiskmanGlass<S: Shape>: ViewModifier {
    let tint: Color?
    let shape: S
    let strokeOpacity: Double

    init(
        tint: Color? = nil,
        shape: S,
        strokeOpacity: Double = 0.16
    ) {
        self.tint = tint
        self.shape = shape
        self.strokeOpacity = strokeOpacity
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular.tint(tint), in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(.white.opacity(strokeOpacity), lineWidth: 1)
                }
        }
    }
}

extension View {
    func diskmanGlass<S: Shape>(
        tint: Color? = nil,
        in shape: S,
        strokeOpacity: Double = 0.16
    ) -> some View {
        modifier(DiskmanGlass(
            tint: tint,
            shape: shape,
            strokeOpacity: strokeOpacity
        ))
    }
}

enum DiskmanPalette {
    static func statusColor(forFreeSpaceRatio ratio: Double) -> Color {
        switch ratio {
        case 0.25...:
            return .green
        case 0.10..<0.25:
            return .yellow
        default:
            return .red
        }
    }

    static func categoryColor(for id: StorageCategoryID) -> Color {
        switch id {
        case .applications:
            return .red
        case .documents:
            return .orange
        case .developer:
            return .yellow
        case .iCloudDrive:
            return .cyan
        case .photos:
            return .green
        case .messages:
            return .teal
        case .systemData:
            return .gray
        case .other:
            return .indigo
        case .used:
            return .blue
        case .available:
            return .secondary.opacity(0.30)
        }
    }
}
