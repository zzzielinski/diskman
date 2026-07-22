import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Diskman") {
                Text("Settings will land after the disk monitor and widget snapshot pipeline are in place.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 220)
    }
}
