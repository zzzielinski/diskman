import ServiceManagement
import SwiftUI
import DiskmanCore

struct SettingsView: View {
    private let settingsStore: DiskmanSettingsStore

    @State private var languageMode: DiskmanLanguageMode
    @State private var launchAtLoginEnabled: Bool
    @State private var visibleVolumeKinds: Set<DiskmanVisibleVolumeKind>
    @State private var usageDisplayMode: DiskmanUsageDisplayMode
    @State private var storageUnitMode: DiskmanStorageUnitMode
    @State private var categoryMode: DiskmanCategoryMode
    @State private var settingsError: String?

    init(settingsStore: DiskmanSettingsStore = DiskmanSettingsStore()) {
        self.settingsStore = settingsStore
        _languageMode = State(initialValue: settingsStore.languageMode)
        _launchAtLoginEnabled = State(initialValue: settingsStore.launchAtLoginDesired)
        _visibleVolumeKinds = State(initialValue: settingsStore.visibleVolumeKinds)
        _usageDisplayMode = State(initialValue: settingsStore.usageDisplayMode)
        _storageUnitMode = State(initialValue: settingsStore.storageUnitMode)
        _categoryMode = State(initialValue: settingsStore.categoryMode)
    }

    private var localization: LocalizationProvider {
        LocalizationProvider(
            languageMode: languageMode,
            usageDisplayMode: usageDisplayMode,
            storageUnitMode: storageUnitMode,
            categoryMode: categoryMode
        )
    }

    var body: some View {
        let localization = localization

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                DiskmanAppIconMark()
                    .scaleEffect(0.82)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Diskman")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text(localization.string(.settingsSubtitle))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            SettingsSection(title: localization.string(.settingsDisplay), symbolName: "slider.horizontal.3") {
                Picker(localization.string(.settingsLanguage), selection: $languageMode) {
                    ForEach(DiskmanLanguageMode.allCases, id: \.self) { mode in
                        Text(localization.languageDisplayName(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Picker(localization.string(.settingsPercentMode), selection: $usageDisplayMode) {
                    ForEach(DiskmanUsageDisplayMode.allCases, id: \.self) { mode in
                        Text(localization.usageModeName(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Picker(localization.string(.settingsStorageUnits), selection: $storageUnitMode) {
                    ForEach(DiskmanStorageUnitMode.allCases, id: \.self) { mode in
                        Text(localization.storageUnitName(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Picker(localization.string(.settingsCategories), selection: $categoryMode) {
                    ForEach(DiskmanCategoryMode.allCases, id: \.self) { mode in
                        Text(localization.categoryModeName(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if categoryMode == .estimated {
                    Label(localization.string(.settingsCategoryPrivacy), systemImage: "hand.raised")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SettingsSection(title: localization.string(.settingsDiskVisibility), symbolName: "externaldrive.connected.to.line.below") {
                LazyVGrid(columns: visibilityColumns, alignment: .leading, spacing: 8) {
                    ForEach(DiskmanVisibleVolumeKind.allCases, id: \.self) { kind in
                        Toggle(
                            localization.volumeKindName(for: kind),
                            isOn: visibilityBinding(for: kind)
                        )
                        .toggleStyle(.checkbox)
                    }
                }
            }

            SettingsSection(title: localization.string(.settingsLaunchAtLogin), symbolName: "power") {
                Toggle(isOn: $launchAtLoginEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(localization.string(.settingsLaunchAtLogin))
                            .font(.system(size: 13, weight: .semibold))

                        Text(localization.string(.settingsLaunchAtLoginHelp))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                if let settingsError {
                    Text(settingsError)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 12) {
                SettingsStatusPill(
                    title: localization.string(.settingsRefresh),
                    value: localization.string(.settingsAutomatic),
                    symbolName: "arrow.clockwise"
                )
                SettingsStatusPill(
                    title: localization.string(.settingsSnapshot),
                    value: localization.string(.settingsWidgetShared),
                    symbolName: "widget.small"
                )
            }
        }
        .padding(24)
        .frame(width: 520, height: 620)
        .onChange(of: languageMode) { _, newValue in
            settingsStore.languageMode = newValue
            notifySettingsChanged()
        }
        .onChange(of: usageDisplayMode) { _, newValue in
            settingsStore.usageDisplayMode = newValue
            notifySettingsChanged()
        }
        .onChange(of: storageUnitMode) { _, newValue in
            settingsStore.storageUnitMode = newValue
            notifySettingsChanged()
        }
        .onChange(of: categoryMode) { _, newValue in
            settingsStore.categoryMode = newValue
            notifySettingsChanged()
        }
        .onChange(of: launchAtLoginEnabled) { _, newValue in
            updateLaunchAtLogin(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .diskmanSettingsDidChange)) { _ in
            reloadStoredSettings()
        }
    }

    private var visibilityColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func visibilityBinding(for kind: DiskmanVisibleVolumeKind) -> Binding<Bool> {
        Binding(
            get: {
                visibleVolumeKinds.contains(kind)
            },
            set: { isVisible in
                if isVisible {
                    visibleVolumeKinds.insert(kind)
                } else {
                    visibleVolumeKinds.remove(kind)
                }
                settingsStore.visibleVolumeKinds = visibleVolumeKinds
                notifySettingsChanged()
            }
        )
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            try setLaunchAtLogin(enabled)
            settingsStore.launchAtLoginDesired = enabled
            settingsError = nil
            notifySettingsChanged()
        } catch {
            settingsStore.launchAtLoginDesired = false
            launchAtLoginEnabled = false
            settingsError = localization.string(.settingsLaunchAtLoginError)
            notifySettingsChanged()
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }

    private func reloadStoredSettings() {
        languageMode = settingsStore.languageMode
        launchAtLoginEnabled = settingsStore.launchAtLoginDesired
        visibleVolumeKinds = settingsStore.visibleVolumeKinds
        usageDisplayMode = settingsStore.usageDisplayMode
        storageUnitMode = settingsStore.storageUnitMode
        categoryMode = settingsStore.categoryMode
    }

    private func notifySettingsChanged() {
        NotificationCenter.default.post(name: .diskmanSettingsDidChange, object: nil)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let symbolName: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 13, weight: .bold, design: .rounded))

            content
        }
        .padding(13)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .diskmanAppGlass(in: RoundedRectangle(cornerRadius: 14, style: .continuous), strokeOpacity: 0.10)
    }
}

private struct SettingsStatusPill: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        Label {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))

                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.secondary.opacity(0.08), in: Capsule())
    }
}
