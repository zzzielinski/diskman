import AppKit
import ServiceManagement
import SwiftUI
import DiskmanCore

struct SettingsView: View {
    private let settingsStore: DiskmanSettingsStore
    private let rebuildWidgetData: () -> Void

    @State private var languageMode: DiskmanLanguageMode
    @State private var appearanceMode: DiskmanAppearanceMode
    @State private var launchAtLoginEnabled: Bool
    @State private var visibleVolumeKinds: Set<DiskmanVisibleVolumeKind>
    @State private var usageDisplayMode: DiskmanUsageDisplayMode
    @State private var storageUnitMode: DiskmanStorageUnitMode
    @State private var categoryMode: DiskmanCategoryMode
    @State private var deepCategoryScanEnabled: Bool
    @State private var settingsError: String?

    init(
        settingsStore: DiskmanSettingsStore = DiskmanSettingsStore(),
        rebuildWidgetData: @escaping () -> Void = {
            NotificationCenter.default.post(name: .diskmanRebuildWidgetData, object: nil)
        }
    ) {
        self.settingsStore = settingsStore
        self.rebuildWidgetData = rebuildWidgetData
        _languageMode = State(initialValue: settingsStore.languageMode)
        _appearanceMode = State(initialValue: settingsStore.appearanceMode)
        _launchAtLoginEnabled = State(initialValue: settingsStore.launchAtLoginDesired)
        _visibleVolumeKinds = State(initialValue: settingsStore.visibleVolumeKinds)
        _usageDisplayMode = State(initialValue: settingsStore.usageDisplayMode)
        _storageUnitMode = State(initialValue: settingsStore.storageUnitMode)
        _categoryMode = State(initialValue: settingsStore.categoryMode)
        _deepCategoryScanEnabled = State(initialValue: settingsStore.deepCategoryScanEnabled)
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

        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
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
                SettingsPickerRow(title: localization.string(.settingsLanguage)) {
                    Picker(localization.string(.settingsLanguage), selection: $languageMode) {
                        ForEach(DiskmanLanguageMode.allCases, id: \.self) { mode in
                            Text(localization.languageDisplayName(for: mode)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                SettingsPickerRow(title: localization.string(.settingsAppearance)) {
                    Picker(localization.string(.settingsAppearance), selection: $appearanceMode) {
                        ForEach(DiskmanAppearanceMode.allCases, id: \.self) { mode in
                            Text(localization.appearanceModeName(for: mode)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                SettingsPickerRow(title: localization.string(.settingsPercentMode)) {
                    Picker(localization.string(.settingsPercentMode), selection: $usageDisplayMode) {
                        ForEach(DiskmanUsageDisplayMode.allCases, id: \.self) { mode in
                            Text(localization.usageModeName(for: mode)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                SettingsPickerRow(title: localization.string(.settingsStorageUnits)) {
                    Picker(localization.string(.settingsStorageUnits), selection: $storageUnitMode) {
                        ForEach(DiskmanStorageUnitMode.allCases, id: \.self) { mode in
                            Text(localization.storageUnitName(for: mode)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                SettingsPickerRow(title: localization.string(.settingsCategories)) {
                    Picker(localization.string(.settingsCategories), selection: $categoryMode) {
                        ForEach(DiskmanCategoryMode.allCases, id: \.self) { mode in
                            Text(localization.categoryModeName(for: mode)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                if categoryMode == .estimated {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(localization.string(.settingsCategoryPrivacy), systemImage: "hand.raised")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Toggle(isOn: $deepCategoryScanEnabled) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(localization.string(.settingsDeepCategoryScan))
                                    .font(.system(size: 12, weight: .semibold))

                                Text(localization.string(.settingsDeepCategoryScanHelp))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        }
                        .toggleStyle(.checkbox)

                        Button {
                            openFullDiskAccessSettings()
                        } label: {
                            Label(localization.string(.settingsOpenFullDiskAccess), systemImage: "lock.shield")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
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
                    HStack(alignment: .center, spacing: 18) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(localization.string(.settingsLaunchAtLogin))
                                .font(.system(size: 13, weight: .semibold))

                            Text(localization.string(.settingsLaunchAtLoginHelp))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 12)
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

            HStack(spacing: 10) {
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

                Spacer(minLength: 8)

                Button {
                    rebuildWidgetData()
                } label: {
                    SettingsFooterPillContent(
                        title: localization.string(.settingsRebuildWidgetData),
                        value: nil,
                        symbolName: "arrow.trianglehead.2.clockwise"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(26)
        .frame(width: 640)
        .fixedSize(horizontal: false, vertical: true)
        .preferredColorScheme(preferredColorScheme)
        .onChange(of: languageMode) { _, newValue in
            settingsStore.languageMode = newValue
            notifySettingsChanged()
        }
        .onChange(of: appearanceMode) { _, newValue in
            settingsStore.appearanceMode = newValue
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
        .onChange(of: deepCategoryScanEnabled) { _, newValue in
            settingsStore.deepCategoryScanEnabled = newValue
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
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
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
        appearanceMode = settingsStore.appearanceMode
        launchAtLoginEnabled = settingsStore.launchAtLoginDesired
        visibleVolumeKinds = settingsStore.visibleVolumeKinds
        usageDisplayMode = settingsStore.usageDisplayMode
        storageUnitMode = settingsStore.storageUnitMode
        categoryMode = settingsStore.categoryMode
        deepCategoryScanEnabled = settingsStore.deepCategoryScanEnabled
    }

    private func notifySettingsChanged() {
        NotificationCenter.default.post(name: .diskmanSettingsDidChange, object: nil)
    }

    private func openFullDiskAccessSettings() {
        let settingsURLs = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
        ]

        for settingsURL in settingsURLs {
            guard let url = URL(string: settingsURL) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}

private struct SettingsPickerRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 118, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            content
                .frame(maxWidth: 360, alignment: .leading)

            Spacer(minLength: 0)
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let symbolName: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 14, weight: .bold, design: .rounded))

            content
        }
        .padding(16)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .diskmanAppGlass(in: RoundedRectangle(cornerRadius: 12, style: .continuous), strokeOpacity: 0.10)
    }
}

private struct SettingsStatusPill: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        SettingsFooterPillContent(
            title: title,
            value: value,
            symbolName: symbolName
        )
    }
}

private struct SettingsFooterPillContent: View {
    let title: String
    let value: String?
    let symbolName: String

    var body: some View {
        Label {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)

                if let value {
                    Text(value)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .minimumScaleFactor(0.82)
        } icon: {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(.secondary.opacity(0.08), in: Capsule())
        .contentShape(Capsule())
    }
}
