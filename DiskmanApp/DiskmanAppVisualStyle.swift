import SwiftUI

struct DiskmanAppGlass<S: Shape>: ViewModifier {
    let shape: S
    let strokeOpacity: Double

    init(shape: S, strokeOpacity: Double = 0.14) {
        self.shape = shape
        self.strokeOpacity = strokeOpacity
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
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
    func diskmanAppGlass<S: Shape>(
        in shape: S,
        strokeOpacity: Double = 0.14
    ) -> some View {
        modifier(DiskmanAppGlass(
            shape: shape,
            strokeOpacity: strokeOpacity
        ))
    }
}

struct DiskmanAppIconMark: View {
    var body: some View {
        Image(systemName: "internaldrive.fill")
            .font(.system(size: 34, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.blue)
            .frame(width: 62, height: 62)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.blue.opacity(0.12))
            }
            .diskmanAppGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
