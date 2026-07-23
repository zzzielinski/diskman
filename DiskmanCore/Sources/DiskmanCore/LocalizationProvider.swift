import Foundation

public enum DiskmanLanguageMode: String, Codable, CaseIterable, Sendable {
    case system
    case english
    case polish
}

public enum DiskmanLanguage: String, Codable, Sendable {
    case english = "en"
    case polish = "pl"

    init(mode: DiskmanLanguageMode, systemLocale: Locale = .current) {
        switch mode {
        case .english:
            self = .english
        case .polish:
            self = .polish
        case .system:
            let languageCode = systemLocale.language.languageCode?.identifier
            self = languageCode == DiskmanLanguage.polish.rawValue ? .polish : .english
        }
    }
}

public struct DiskmanSettingsStore {
    public static let languageModeKey = "diskman.languageMode"

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
}

public struct LocalizationProvider: Sendable {
    public let language: DiskmanLanguage

    public init(
        languageMode: DiskmanLanguageMode = .system,
        systemLocale: Locale = .current
    ) {
        self.language = DiskmanLanguage(mode: languageMode, systemLocale: systemLocale)
    }

    public init(settingsStore: DiskmanSettingsStore) {
        self.init(languageMode: settingsStore.languageMode)
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

    public func capacitySummary(for volume: VolumeSnapshot) -> String {
        string(
            .capacityFreeOf,
            DiskByteFormatter.decimal.string(fromByteCount: volume.availableBytes),
            DiskByteFormatter.decimal.string(fromByteCount: volume.totalBytes)
        )
    }

    public func freeSpaceAccessibility(for volume: VolumeSnapshot) -> String {
        string(.accessibilityDiskFree, volume.displayName, volume.freePercentText)
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
    case menuSettings = "menu.settings"
    case menuLanguage = "menu.language"
    case menuAboutDiskman = "menu.aboutDiskman"
    case menuQuitDiskman = "menu.quitDiskman"
    case menuUnableToReadDisks = "menu.unableToReadDisks"
    case menuNoDisksFound = "menu.noDisksFound"
    case menuStatus = "menu.status"
    case menuWidgetSnapshotUnavailable = "menu.widgetSnapshotUnavailable"
    case languageSystem = "language.system"
    case languageEnglish = "language.english"
    case languagePolish = "language.polish"
    case diskSingular = "disk.singular"
    case diskPlural = "disk.plural"
    case capacityFreeOf = "capacity.freeOf"
    case accessibilityDiskFree = "accessibility.diskFree"
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
    case settingsLanguage = "settings.language"
    case aboutSubtitle = "about.subtitle"
    case aboutVersion = "about.version"
    case aboutOpenSource = "about.openSource"
    case categoryApplications = "category.applications"
    case categoryDocuments = "category.documents"
    case categoryDeveloper = "category.developer"
    case categoryPhotos = "category.photos"
    case categoryMessages = "category.messages"
    case categorySystemData = "category.systemData"
    case categoryOther = "category.other"
    case categoryUsed = "category.used"
    case categoryAvailable = "category.available"

    public var fallbackValue: String {
        switch self {
        case .menuLoadingDisks:
            return "Loading disks..."
        case .menuRefreshNow:
            return "Refresh Now"
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
        case .menuWidgetSnapshotUnavailable:
            return "Widget snapshot unavailable"
        case .languageSystem:
            return "System"
        case .languageEnglish:
            return "English"
        case .languagePolish:
            return "Polish"
        case .diskSingular:
            return "disk"
        case .diskPlural:
            return "disks"
        case .capacityFreeOf:
            return "%@ free of %@"
        case .accessibilityDiskFree:
            return "%@, %@ free"
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
            return "Widget shared"
        case .settingsLanguage:
            return "Language"
        case .aboutSubtitle:
            return "A Liquid Glass-inspired disk monitor for macOS."
        case .aboutVersion:
            return "Version 0.1.0"
        case .aboutOpenSource:
            return "Open Source"
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
        }
    }
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
