import Foundation
import Testing
@testable import DiskmanCore

@Test
func placeholderSnapshotContainsVolume() {
    #expect(DiskSnapshot.placeholder.volumes.isEmpty == false)
}

@Test
func volumeRatiosAreClamped() {
    #expect(VolumeSnapshot.ratio(25, 100) == 0.25)
    #expect(VolumeSnapshot.ratio(-10, 100) == 0)
    #expect(VolumeSnapshot.ratio(120, 100) == 1)
    #expect(VolumeSnapshot.ratio(50, 0) == 0)
}

@Test
func byteFormatterProducesUnits() {
    let formatted = DiskByteFormatter.decimal.string(fromByteCount: 1_000_000_000)

    #expect(formatted.contains("GB"))
}

@Test
func binaryByteFormatterProducesGibUnits() {
    let formatted = DiskByteFormatter.binary.string(fromByteCount: 1_073_741_824)

    #expect(formatted.contains("GiB"))
}

@Test
func resourceSnapshotBuildsVolumeSnapshot() throws {
    let resource = VolumeResourceSnapshot(
        url: URL(filePath: "/Volumes/Backup"),
        name: "Backup",
        localizedName: nil,
        localizedFormatDescription: "APFS",
        totalCapacity: 1_000,
        availableCapacity: 250,
        importantAvailableCapacity: 200,
        isBrowsable: true,
        isInternal: false,
        isEjectable: true,
        isRemovable: false,
        isLocal: true,
        isAutomounted: false
    )

    let volume = try #require(VolumeSnapshot(resource: resource))

    #expect(volume.name == "Backup")
    #expect(volume.mountPath == "/Volumes/Backup")
    #expect(volume.kind == VolumeKind.externalDrive)
    #expect(volume.totalBytes == 1_000)
    #expect(volume.availableBytes == 250)
    #expect(volume.importantAvailableBytes == 200)
    #expect(volume.usedBytes == 750)
    #expect(volume.categories.map(\StorageCategorySnapshot.id) == [StorageCategoryID.used, .available])
}

@Test
func resourceSnapshotFiltersTechnicalVolumes() {
    let hidden = VolumeResourceSnapshot(
        url: URL(filePath: "/System/Volumes/Preboot"),
        name: "Preboot",
        localizedName: nil,
        localizedFormatDescription: "APFS",
        totalCapacity: 1_000,
        availableCapacity: 250,
        importantAvailableCapacity: nil,
        isBrowsable: false,
        isInternal: true,
        isEjectable: false,
        isRemovable: false,
        isLocal: true,
        isAutomounted: false
    )

    #expect(VolumeSnapshot(resource: hidden) == nil)
}

@Test
func resourceSnapshotClassifiesNetworkAndDiskImages() {
    let network = VolumeResourceSnapshot(
        url: URL(filePath: "/Volumes/TeamShare"),
        name: "TeamShare",
        localizedName: nil,
        localizedFormatDescription: "SMB",
        totalCapacity: 1_000,
        availableCapacity: 250,
        importantAvailableCapacity: nil,
        isBrowsable: true,
        isInternal: false,
        isEjectable: false,
        isRemovable: false,
        isLocal: false,
        isAutomounted: false
    )

    let diskImage = VolumeResourceSnapshot(
        url: URL(filePath: "/Volumes/Installer"),
        name: "Installer",
        localizedName: nil,
        localizedFormatDescription: "Disk Image",
        totalCapacity: 1_000,
        availableCapacity: 250,
        importantAvailableCapacity: nil,
        isBrowsable: true,
        isInternal: false,
        isEjectable: true,
        isRemovable: false,
        isLocal: true,
        isAutomounted: false
    )

    #expect(VolumeSnapshot(resource: network)?.kind == .network)
    #expect(VolumeSnapshot(resource: diskImage)?.kind == .diskImage)
}

@Test
func snapshotStoreRoundTripsSnapshot() throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appending(path: "diskman-store-tests")
        .appending(path: UUID().uuidString)
    let store = StorageSnapshotStore(snapshotDirectoryURL: directoryURL)
    let snapshot = DiskSnapshot.placeholder

    try store.write(snapshot)

    let savedSnapshot = try #require(try store.read())
    #expect(savedSnapshot == snapshot)
}

@Test
func snapshotStoreReturnsNilWhenSnapshotDoesNotExist() throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appending(path: "diskman-store-tests")
        .appending(path: UUID().uuidString)
    let store = StorageSnapshotStore(snapshotDirectoryURL: directoryURL)

    let savedSnapshot = try store.read()

    #expect(savedSnapshot == nil)
}

@Test
func localizationProviderUsesForcedLanguageMode() {
    let english = LocalizationProvider(languageMode: .english)
    let polish = LocalizationProvider(languageMode: .polish)

    #expect(english.categoryName(for: .available) == "Available")
    #expect(polish.categoryName(for: .available) == "Dostępne")
}

@Test
func localizationProviderResolvesSystemLanguage() {
    let polish = LocalizationProvider(
        languageMode: .system,
        systemLocale: Locale(identifier: "pl_PL")
    )
    let english = LocalizationProvider(
        languageMode: .system,
        systemLocale: Locale(identifier: "en_US")
    )

    #expect(polish.language == .polish)
    #expect(english.language == .english)
}

@Test
func settingsStorePersistsLanguageMode() throws {
    let suiteName = "diskman-tests-\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    let store = DiskmanSettingsStore(userDefaults: userDefaults)
    #expect(store.languageMode == .system)

    store.languageMode = .polish

    let restoredStore = DiskmanSettingsStore(userDefaults: userDefaults)
    #expect(restoredStore.languageMode == .polish)
}

@Test
func settingsStorePersistsDisplaySettings() throws {
    let suiteName = "diskman-tests-\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    let store = DiskmanSettingsStore(userDefaults: userDefaults)
    #expect(store.usageDisplayMode == .free)
    #expect(store.storageUnitMode == .decimal)
    #expect(store.visibleVolumeKinds == Set(DiskmanVisibleVolumeKind.allCases))

    store.usageDisplayMode = .used
    store.storageUnitMode = .binary
    store.visibleVolumeKinds = []

    let restoredStore = DiskmanSettingsStore(userDefaults: userDefaults)
    #expect(restoredStore.usageDisplayMode == .used)
    #expect(restoredStore.storageUnitMode == .binary)
    #expect(restoredStore.visibleVolumeKinds == [])
}

@Test
func snapshotFiltersVolumesByVisibleKinds() {
    let internalVolume = VolumeSnapshot(
        id: "internal",
        name: "Internal",
        localizedName: nil,
        mountPath: "/",
        kind: .internalDrive,
        fileSystemName: "APFS",
        totalBytes: 1_000,
        availableBytes: 400,
        importantAvailableBytes: nil,
        usedBytes: 600,
        categories: []
    )
    let networkVolume = VolumeSnapshot(
        id: "network",
        name: "Network",
        localizedName: nil,
        mountPath: "/Volumes/Network",
        kind: .network,
        fileSystemName: "SMB",
        totalBytes: 1_000,
        availableBytes: 400,
        importantAvailableBytes: nil,
        usedBytes: 600,
        categories: []
    )
    let snapshot = DiskSnapshot(generatedAt: Date(), volumes: [internalVolume, networkVolume])

    let filtered = snapshot.filtered(visibleKinds: [.network])

    #expect(filtered.volumes.map(\.id) == ["network"])
}

@Test
func localizationProviderUsesUsageAndUnitSettings() {
    let volume = VolumeSnapshot(
        id: "volume",
        name: "Volume",
        localizedName: nil,
        mountPath: "/Volumes/Volume",
        kind: .externalDrive,
        fileSystemName: "APFS",
        totalBytes: 1_073_741_824,
        availableBytes: 268_435_456,
        importantAvailableBytes: nil,
        usedBytes: 805_306_368,
        categories: []
    )
    let localization = LocalizationProvider(
        languageMode: .english,
        usageDisplayMode: .used,
        storageUnitMode: .binary
    )

    #expect(localization.usagePercentText(for: volume) == "75%")
    #expect(localization.capacitySummary(for: volume).contains("GiB"))
}
