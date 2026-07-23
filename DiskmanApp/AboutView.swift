import SwiftUI
import DiskmanCore

struct AboutView: View {
    let localization: LocalizationProvider

    init(localization: LocalizationProvider = LocalizationProvider(settingsStore: DiskmanSettingsStore())) {
        self.localization = localization
    }

    var body: some View {
        VStack(spacing: 16) {
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
                AboutBadge(text: versionText)
                AboutBadge(text: localization.string(.aboutOpenSource))
                AboutBadge(text: localization.string(.aboutLicense))
            }

            Link(destination: URL(string: "https://github.com/zzzielinski/diskman")!) {
                Label(localization.string(.aboutGithub), systemImage: "arrow.up.right.square")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.link)

            Text(localization.string(.aboutPrivacy))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
        }
        .padding(28)
        .frame(width: 400, height: 330)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.clear)
                .diskmanAppGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(10)
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.2"
        return localization.string(.aboutVersion, version)
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
