import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                DiskmanAppIconMark()
                    .scaleEffect(0.82)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Diskman")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text("Background disk monitor")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 0) {
                SettingsInfoRow(title: "Refresh", value: "Automatic", symbolName: "arrow.clockwise")
                Divider().padding(.leading, 34)
                SettingsInfoRow(title: "Snapshot", value: "Widget shared", symbolName: "widget.small")
                Divider().padding(.leading, 34)
                SettingsInfoRow(title: "Language", value: "System", symbolName: "globe")
            }
            .padding(12)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .diskmanAppGlass(in: RoundedRectangle(cornerRadius: 14, style: .continuous), strokeOpacity: 0.10)
        }
        .padding(24)
        .frame(width: 420, height: 280)
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(height: 34)
    }
}
