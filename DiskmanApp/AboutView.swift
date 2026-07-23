import SwiftUI
import DiskmanCore

struct AboutView: View {
    let localization: LocalizationProvider

    init(localization: LocalizationProvider = LocalizationProvider(settingsStore: DiskmanSettingsStore())) {
        self.localization = localization
    }

    var body: some View {
        VStack(spacing: 18) {
            DiskmanAppIconMark()

            VStack(spacing: 5) {
                Text("Diskman")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text(localization.string(.aboutSubtitle))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                AboutBadge(text: localization.string(.aboutVersion))
                AboutBadge(text: localization.string(.aboutOpenSource))
            }
        }
        .padding(28)
        .frame(width: 360, height: 250)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.clear)
                .diskmanAppGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(10)
        }
    }
}

private struct AboutBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.secondary.opacity(0.10), in: Capsule())
    }
}
