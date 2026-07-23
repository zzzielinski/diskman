import Foundation

public enum DiskmanLanguageMode: String, Codable, CaseIterable, Sendable {
    case system
    case english
    case polish
}

public enum DiskmanLanguage: String, Codable, Sendable {
    case english = "en"
    case polish = "pl"

    init(
        mode: DiskmanLanguageMode,
        systemLocale: Locale = .current,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) {
        switch mode {
        case .english:
            self = .english
        case .polish:
            self = .polish
        case .system:
            let languageCode = preferredLanguages
                .lazy
                .compactMap { Locale(identifier: $0).language.languageCode?.identifier }
                .first ?? systemLocale.language.languageCode?.identifier
            self = languageCode == DiskmanLanguage.polish.rawValue ? .polish : .english
        }
    }
}

public enum DiskmanAppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

public enum DiskmanUsageDisplayMode: String, Codable, CaseIterable, Sendable {
    case free
    case used
}

public enum DiskmanStorageUnitMode: String, Codable, CaseIterable, Sendable {
    case decimal
    case binary

    public var formatter: DiskByteFormatter {
        switch self {
        case .decimal:
            return .decimal
        case .binary:
            return .binary
        }
    }
}

public enum DiskmanCategoryMode: String, Codable, CaseIterable, Sendable {
    case off
    case basic
    case estimated
}

public enum DiskmanVisibleVolumeKind: String, Codable, CaseIterable, Sendable {
    case internalDrive
    case externalDrive
    case network
    case diskImage

    public func includes(_ kind: VolumeKind) -> Bool {
        switch self {
        case .internalDrive:
            return kind == .internalDrive
        case .externalDrive:
            return kind == .externalDrive || kind == .removable || kind == .unknown
        case .network:
            return kind == .network
        case .diskImage:
            return kind == .diskImage
        }
    }
}

public struct DiskmanSettingsStore {
    public static let languageModeKey = "diskman.languageMode"
    public static let launchAtLoginKey = "diskman.launchAtLogin"
    public static let visibleVolumeKindsKey = "diskman.visibleVolumeKinds"
    public static let appearanceModeKey = "diskman.appearanceMode"
    public static let usageDisplayModeKey = "diskman.usageDisplayMode"
    public static let storageUnitModeKey = "diskman.storageUnitMode"
    public static let categoryModeKey = "diskman.categoryMode"
    public static let deepCategoryScanKey = "diskman.deepCategoryScan"

    private let userDefaults: UserDefaults

    public init(
        appGroupIdentifier: String = StorageSnapshotStore.defaultAppGroupIdentifier
    ) {
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    public var languageMode: DiskmanLanguageMode {
        get {
            guard let rawValue = userDefaults.string(forKey: Self.languageModeKey),
                  let mode = DiskmanLanguageMode(rawValue: rawValue)
            else {
                return .system
            }

            return mode
        }
        nonmutating set {
            userDefaults.set(newValue.rawValue, forKey: Self.languageModeKey)
        }
    }

    public var launchAtLoginDesired: Bool {
        get {
            userDefaults.bool(forKey: Self.launchAtLoginKey)
        }
        nonmutating set {
            userDefaults.set(newValue, forKey: Self.launchAtLoginKey)
        }
    }

    public var appearanceMode: DiskmanAppearanceMode {
        get {
            guard let rawValue = userDefaults.string(forKey: Self.appearanceModeKey),
                  let mode = DiskmanAppearanceMode(rawValue: rawValue)
            else {
                return .system
            }

            return mode
        }
        nonmutating set {
            userDefaults.set(newValue.rawValue, forKey: Self.appearanceModeKey)
        }
    }

    public var usageDisplayMode: DiskmanUsageDisplayMode {
        get {
            guard let rawValue = userDefaults.string(forKey: Self.usageDisplayModeKey),
                  let mode = DiskmanUsageDisplayMode(rawValue: rawValue)
            else {
                return .free
            }

            return mode
        }
        nonmutating set {
            userDefaults.set(newValue.rawValue, forKey: Self.usageDisplayModeKey)
        }
    }

    public var storageUnitMode: DiskmanStorageUnitMode {
        get {
            guard let rawValue = userDefaults.string(forKey: Self.storageUnitModeKey),
                  let mode = DiskmanStorageUnitMode(rawValue: rawValue)
            else {
                return .decimal
            }

            return mode
        }
        nonmutating set {
            userDefaults.set(newValue.rawValue, forKey: Self.storageUnitModeKey)
        }
    }

    public var categoryMode: DiskmanCategoryMode {
        get {
            guard let rawValue = userDefaults.string(forKey: Self.categoryModeKey),
                  let mode = DiskmanCategoryMode(rawValue: rawValue)
            else {
                return .basic
            }

            return mode
        }
        nonmutating set {
            userDefaults.set(newValue.rawValue, forKey: Self.categoryModeKey)
        }
    }

    public var deepCategoryScanEnabled: Bool {
        get {
            userDefaults.bool(forKey: Self.deepCategoryScanKey)
        }
        nonmutating set {
            userDefaults.set(newValue, forKey: Self.deepCategoryScanKey)
        }
    }

    public var visibleVolumeKinds: Set<DiskmanVisibleVolumeKind> {
        get {
            guard let rawValues = userDefaults.array(forKey: Self.visibleVolumeKindsKey) as? [String] else {
                return Set(DiskmanVisibleVolumeKind.allCases)
            }

            return Set(rawValues.compactMap(DiskmanVisibleVolumeKind.init(rawValue:)))
        }
        nonmutating set {
            userDefaults.set(newValue.map(\.rawValue), forKey: Self.visibleVolumeKindsKey)
        }
    }

    public func isVolumeKindVisible(_ kind: DiskmanVisibleVolumeKind) -> Bool {
        visibleVolumeKinds.contains(kind)
    }

    public func setVolumeKind(_ kind: DiskmanVisibleVolumeKind, isVisible: Bool) {
        var visibleKinds = visibleVolumeKinds
        if isVisible {
            visibleKinds.insert(kind)
        } else {
            visibleKinds.remove(kind)
        }
        visibleVolumeKinds = visibleKinds
    }
}

public struct LocalizationProvider: Sendable {
    public let language: DiskmanLanguage
    public let usageDisplayMode: DiskmanUsageDisplayMode
    public let storageUnitMode: DiskmanStorageUnitMode
    public let categoryMode: DiskmanCategoryMode

    public init(
        languageMode: DiskmanLanguageMode = .system,
        systemLocale: Locale = .current,
        preferredLanguages: [String] = Locale.preferredLanguages,
        usageDisplayMode: DiskmanUsageDisplayMode = .free,
        storageUnitMode: DiskmanStorageUnitMode = .decimal,
        categoryMode: DiskmanCategoryMode = .basic
    ) {
        self.language = DiskmanLanguage(
            mode: languageMode,
            systemLocale: systemLocale,
            preferredLanguages: preferredLanguages
        )
        self.usageDisplayMode = usageDisplayMode
        self.storageUnitMode = storageUnitMode
        self.categoryMode = categoryMode
    }

    public init(settingsStore: DiskmanSettingsStore) {
        self.init(
            languageMode: settingsStore.languageMode,
            usageDisplayMode: settingsStore.usageDisplayMode,
            storageUnitMode: settingsStore.storageUnitMode,
            categoryMode: settingsStore.categoryMode
        )
    }

    public func string(_ key: LocalizationKey) -> String {
        bundle.localizedString(
            forKey: key.rawValue,
            value: key.fallbackValue,
            table: nil
        )
    }

    public func string(_ key: LocalizationKey, _ arguments: CVarArg...) -> String {
        String(
            format: string(key),
            locale: Locale(identifier: language.rawValue),
            arguments: arguments
        )
    }

    public func categoryName(for id: StorageCategoryID) -> String {
        string(id.localizationKey)
    }

    public func volumeKindName(for kind: DiskmanVisibleVolumeKind) -> String {
        string(kind.localizationKey)
    }

    public func usageModeName(for mode: DiskmanUsageDisplayMode) -> String {
        string(mode.localizationKey)
    }

    public func usageModeAbbreviation(for mode: DiskmanUsageDisplayMode) -> String {
        string(mode.abbreviationLocalizationKey)
    }

    public func storageUnitName(for mode: DiskmanStorageUnitMode) -> String {
        string(mode.localizationKey)
    }

    public func categoryModeName(for mode: DiskmanCategoryMode) -> String {
        string(mode.localizationKey)
    }

    public func capacitySummary(for volume: VolumeSnapshot) -> String {
        return string(
            .capacityFreeOf,
            storageUnitMode.formatter.string(fromByteCount: volume.displayAvailableBytes),
            storageUnitMode.formatter.string(fromByteCount: volume.totalBytes)
        )
    }

    public func statusSummary(
        volumeCount: Int,
        primaryVolume: VolumeSnapshot
    ) -> String {
        let key: LocalizationKey = usageDisplayMode == .free ? .menuStatusFree : .menuStatusUsed
        return string(
            key,
            volumeCount,
            diskLabel(count: volumeCount),
            primaryVolume.displayName,
            usagePercentText(for: primaryVolume)
        )
    }

    public func usagePercentText(for volume: VolumeSnapshot) -> String {
        switch usageDisplayMode {
        case .free:
            return volume.freePercentText
        case .used:
            return volume.usedPercentText
        }
    }

    public func usageRatio(for volume: VolumeSnapshot) -> Double {
        switch usageDisplayMode {
        case .free:
            return volume.freeSpaceRatio
        case .used:
            return volume.usedSpaceRatio
        }
    }

    public func freeSpaceAccessibility(for volume: VolumeSnapshot) -> String {
        switch usageDisplayMode {
        case .free:
            return string(.accessibilityDiskFree, volume.displayName, volume.freePercentText)
        case .used:
            return string(.accessibilityDiskUsed, volume.displayName, volume.usedPercentText)
        }
    }

    public func moreDisksLabel(_ count: Int) -> String {
        string(.moreDisksFormat, count)
    }

    public func diskLabel(count: Int) -> String {
        count == 1 ? string(.diskSingular) : string(.diskPlural)
    }

    public func languageDisplayName(for mode: DiskmanLanguageMode) -> String {
        switch mode {
        case .system:
            return string(.languageSystem)
        case .english:
            return string(.languageEnglish)
        case .polish:
            return string(.languagePolish)
        }
    }

    public func appearanceModeName(for mode: DiskmanAppearanceMode) -> String {
        string(mode.localizationKey)
    }

    private var bundle: Bundle {
        guard let path = Bundle.module.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return .module
        }

        return bundle
    }
}

public enum LocalizationKey: String, CaseIterable, Sendable {
    case menuLoadingDisks = "menu.loadingDisks"
    case menuRefreshNow = "menu.refreshNow"
    case menuRebuildWidgetData = "menu.rebuildWidgetData"
    case menuSettings = "menu.settings"
    case menuLanguage = "menu.language"
    case menuAboutDiskman = "menu.aboutDiskman"
    case menuQuitDiskman = "menu.quitDiskman"
    case menuUnableToReadDisks = "menu.unableToReadDisks"
    case menuNoDisksFound = "menu.noDisksFound"
    case menuStatus = "menu.status"
    case menuStatusFree = "menu.status.free"
    case menuStatusUsed = "menu.status.used"
    case menuWidgetSnapshotUnavailable = "menu.widgetSnapshotUnavailable"
    case languageSystem = "language.system"
    case languageEnglish = "language.english"
    case languagePolish = "language.polish"
    case appearanceSystem = "appearance.system"
    case appearanceLight = "appearance.light"
    case appearanceDark = "appearance.dark"
    case diskSingular = "disk.singular"
    case diskPlural = "disk.plural"
    case capacityFreeOf = "capacity.freeOf"
    case accessibilityDiskFree = "accessibility.diskFree"
    case accessibilityDiskUsed = "accessibility.diskUsed"
    case widgetNoDisks = "widget.noDisks"
    case widgetNoData = "widget.noData"
    case widgetUnableToLoad = "widget.unableToLoad"
    case widgetOpenDiskmanRefresh = "widget.openDiskmanRefresh"
    case widgetOpenDiskmanRebuild = "widget.openDiskmanRebuild"
    case widgetMore = "widget.more"
    case moreDisksFormat = "widget.moreDisksFormat"
    case settingsSubtitle = "settings.subtitle"
    case settingsRefresh = "settings.refresh"
    case settingsAutomatic = "settings.automatic"
    case settingsSnapshot = "settings.snapshot"
    case settingsWidgetShared = "settings.widgetShared"
    case settingsRebuildWidgetData = "settings.rebuildWidgetData"
    case settingsLanguage = "settings.language"
    case settingsAppearance = "settings.appearance"
    case settingsLaunchAtLogin = "settings.launchAtLogin"
    case settingsLaunchAtLoginHelp = "settings.launchAtLoginHelp"
    case settingsDisplay = "settings.display"
    case settingsDiskVisibility = "settings.diskVisibility"
    case settingsStorageUnits = "settings.storageUnits"
    case settingsPercentMode = "settings.percentMode"
    case settingsCategories = "settings.categories"
    case settingsCategoryPrivacy = "settings.categoryPrivacy"
    case settingsDeepCategoryScan = "settings.deepCategoryScan"
    case settingsDeepCategoryScanHelp = "settings.deepCategoryScanHelp"
    case settingsOpenFullDiskAccess = "settings.openFullDiskAccess"
    case settingsLaunchAtLoginError = "settings.launchAtLoginError"
    case aboutSubtitle = "about.subtitle"
    case aboutVersion = "about.version"
    case aboutOpenSource = "about.openSource"
    case aboutGithub = "about.github"
    case aboutLicense = "about.license"
    case aboutPrivacy = "about.privacy"
    case categoryApplications = "category.applications"
    case categoryDocuments = "category.documents"
    case categoryDeveloper = "category.developer"
    case categoryPhotos = "category.photos"
    case categoryMessages = "category.messages"
    case categorySystemData = "category.systemData"
    case categoryOther = "category.other"
    case categoryUsed = "category.used"
    case categoryAvailable = "category.available"
    case categoryConfidenceEstimated = "categoryConfidence.estimated"
    case volumeKindInternal = "volumeKind.internal"
    case volumeKindExternal = "volumeKind.external"
    case volumeKindNetwork = "volumeKind.network"
    case volumeKindDiskImage = "volumeKind.diskImage"
    case usageModeFree = "usageMode.free"
    case usageModeUsed = "usageMode.used"
    case usageModeFreeShort = "usageMode.free.short"
    case usageModeUsedShort = "usageMode.used.short"
    case storageUnitDecimal = "storageUnit.decimal"
    case storageUnitBinary = "storageUnit.binary"
    case categoryModeOff = "categoryMode.off"
    case categoryModeBasic = "categoryMode.basic"
    case categoryModeEstimated = "categoryMode.estimated"

    public var fallbackValue: String {
        switch self {
        case .menuLoadingDisks:
            return "Loading disks..."
        case .menuRefreshNow:
            return "Refresh Now"
        case .menuRebuildWidgetData:
            return "Rebuild Widget Data"
        case .menuSettings:
            return "Settings..."
        case .menuLanguage:
            return "Language"
        case .menuAboutDiskman:
            return "About Diskman"
        case .menuQuitDiskman:
            return "Quit Diskman"
        case .menuUnableToReadDisks:
            return "Unable to read disks"
        case .menuNoDisksFound:
            return "No disks found"
        case .menuStatus:
            return "%d %@ - %@: %@ free"
        case .menuStatusFree:
            return "%d %@ - %@: %@ free"
        case .menuStatusUsed:
            return "%d %@ - %@: %@ used"
        case .menuWidgetSnapshotUnavailable:
            return "Widget snapshot unavailable"
        case .languageSystem:
            return "System"
        case .languageEnglish:
            return "English"
        case .languagePolish:
            return "Polish"
        case .appearanceSystem:
            return "System"
        case .appearanceLight:
            return "Light"
        case .appearanceDark:
            return "Dark"
        case .diskSingular:
            return "disk"
        case .diskPlural:
            return "disks"
        case .capacityFreeOf:
            return "%@ free of %@"
        case .accessibilityDiskFree:
            return "%@, %@ free"
        case .accessibilityDiskUsed:
            return "%@, %@ used"
        case .widgetNoDisks:
            return "No Disks"
        case .widgetNoData:
            return "No Data"
        case .widgetUnableToLoad:
            return "Unable to Load"
        case .widgetOpenDiskmanRefresh:
            return "Open Diskman to refresh storage data."
        case .widgetOpenDiskmanRebuild:
            return "Open Diskman to rebuild widget data."
        case .widgetMore:
            return "more"
        case .moreDisksFormat:
            return "%d more disks"
        case .settingsSubtitle:
            return "Background disk monitor"
        case .settingsRefresh:
            return "Refresh"
        case .settingsAutomatic:
            return "Automatic"
        case .settingsSnapshot:
            return "Snapshot"
        case .settingsWidgetShared:
            return "Shared"
        case .settingsRebuildWidgetData:
            return "Rebuild Data"
        case .settingsLanguage:
            return "Language"
        case .settingsAppearance:
            return "Theme"
        case .settingsLaunchAtLogin:
            return "Launch at Login"
        case .settingsLaunchAtLoginHelp:
            return "Start Diskman automatically when you sign in."
        case .settingsDisplay:
            return "Display"
        case .settingsDiskVisibility:
            return "Disk Visibility"
        case .settingsStorageUnits:
            return "Storage Units"
        case .settingsPercentMode:
            return "Percent Mode"
        case .settingsCategories:
            return "Categories"
        case .settingsCategoryPrivacy:
            return "Estimated categories use safe local folders by default. Enable deep scan after granting Full Disk Access for more detail."
        case .settingsDeepCategoryScan:
            return "Deep Folder Scan"
        case .settingsDeepCategoryScanHelp:
            return "Scans Documents, Photos, Messages, and Downloads. macOS may require Full Disk Access."
        case .settingsOpenFullDiskAccess:
            return "Open Full Disk Access"
        case .settingsLaunchAtLoginError:
            return "Unable to update Launch at Login."
        case .aboutSubtitle:
            return "A Liquid Glass-inspired disk monitor for macOS."
        case .aboutVersion:
            return "Version %@"
        case .aboutOpenSource:
            return "Open Source"
        case .aboutGithub:
            return "GitHub"
        case .aboutLicense:
            return "MIT License"
        case .aboutPrivacy:
            return "Diskman reads local volume metadata only. It does not send analytics or disk data anywhere."
        case .categoryApplications:
            return "Applications"
        case .categoryDocuments:
            return "Documents"
        case .categoryDeveloper:
            return "Developer"
        case .categoryPhotos:
            return "Photos"
        case .categoryMessages:
            return "Messages"
        case .categorySystemData:
            return "System Data"
        case .categoryOther:
            return "Other"
        case .categoryUsed:
            return "Used"
        case .categoryAvailable:
            return "Available"
        case .categoryConfidenceEstimated:
            return "Estimated"
        case .volumeKindInternal:
            return "Internal"
        case .volumeKindExternal:
            return "External"
        case .volumeKindNetwork:
            return "Network"
        case .volumeKindDiskImage:
            return "Disk Images"
        case .usageModeFree:
            return "Free"
        case .usageModeUsed:
            return "Used"
        case .usageModeFreeShort:
            return "F"
        case .usageModeUsedShort:
            return "U"
        case .storageUnitDecimal:
            return "GB"
        case .storageUnitBinary:
            return "GiB"
        case .categoryModeOff:
            return "Off"
        case .categoryModeBasic:
            return "Basic"
        case .categoryModeEstimated:
            return "Estimated"
        }
    }
}

public extension Notification.Name {
    static let diskmanSettingsDidChange = Notification.Name("com.zzzielinski.diskman.settingsDidChange")
    static let diskmanRebuildWidgetData = Notification.Name("com.zzzielinski.diskman.rebuildWidgetData")
}

private extension StorageCategoryID {
    var localizationKey: LocalizationKey {
        switch self {
        case .applications:
            return .categoryApplications
        case .documents:
            return .categoryDocuments
        case .developer:
            return .categoryDeveloper
        case .photos:
            return .categoryPhotos
        case .messages:
            return .categoryMessages
        case .systemData:
            return .categorySystemData
        case .other:
            return .categoryOther
        case .used:
            return .categoryUsed
        case .available:
            return .categoryAvailable
        }
    }
}

private extension DiskmanVisibleVolumeKind {
    var localizationKey: LocalizationKey {
        switch self {
        case .internalDrive:
            return .volumeKindInternal
        case .externalDrive:
            return .volumeKindExternal
        case .network:
            return .volumeKindNetwork
        case .diskImage:
            return .volumeKindDiskImage
        }
    }
}

private extension DiskmanUsageDisplayMode {
    var localizationKey: LocalizationKey {
        switch self {
        case .free:
            return .usageModeFree
        case .used:
            return .usageModeUsed
        }
    }

    var abbreviationLocalizationKey: LocalizationKey {
        switch self {
        case .free:
            return .usageModeFreeShort
        case .used:
            return .usageModeUsedShort
        }
    }
}

private extension DiskmanAppearanceMode {
    var localizationKey: LocalizationKey {
        switch self {
        case .system:
            return .appearanceSystem
        case .light:
            return .appearanceLight
        case .dark:
            return .appearanceDark
        }
    }
}

private extension DiskmanStorageUnitMode {
    var localizationKey: LocalizationKey {
        switch self {
        case .decimal:
            return .storageUnitDecimal
        case .binary:
            return .storageUnitBinary
        }
    }
}

private extension DiskmanCategoryMode {
    var localizationKey: LocalizationKey {
        switch self {
        case .off:
            return .categoryModeOff
        case .basic:
            return .categoryModeBasic
        case .estimated:
            return .categoryModeEstimated
        }
    }
}
