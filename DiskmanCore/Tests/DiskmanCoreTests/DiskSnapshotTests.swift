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
    #expect(store.categoryMode == .basic)

    store.usageDisplayMode = .used
    store.storageUnitMode = .binary
    store.visibleVolumeKinds = []
    store.categoryMode = .estimated

    let restoredStore = DiskmanSettingsStore(userDefaults: userDefaults)
    #expect(restoredStore.usageDisplayMode == .used)
    #expect(restoredStore.storageUnitMode == .binary)
    #expect(restoredStore.visibleVolumeKinds == [])
    #expect(restoredStore.categoryMode == .estimated)
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

@Test
func categoryCacheStorePersistsFreshResults() throws {
    let cacheDirectoryURL = FileManager.default.temporaryDirectory
        .appending(path: "diskman-category-cache-tests")
        .appending(path: UUID().uuidString)
    let store = StorageCategoryCacheStore(cacheDirectoryURL: cacheDirectoryURL)
    let result = StorageCategoryScanResult(
        volumeID: "volume",
        generatedAt: Date(),
        categories: [
            StorageCategorySnapshot(
                id: .documents,
                localizedName: "Documents",
                colorToken: "documents",
                bytes: 42,
                confidence: .estimated
            )
        ]
    )

    try store.write(result)

    let restoredResult = try #require(try store.cachedResult(for: "volume"))
    #expect(restoredResult.categories.map(\.id) == [.documents])
}

@Test
func estimatedScannerBuildsCategoriesFromArtificialDirectories() throws {
    let rootURL = FileManager.default.temporaryDirectory
        .appending(path: "diskman-category-scan-tests")
        .appending(path: UUID().uuidString)
    let homeURL = rootURL.appending(path: "Users/Test")
    let cacheURL = rootURL.appending(path: "Cache")
    let applicationsURL = rootURL.appending(path: "Applications")
    let documentsURL = homeURL.appending(path: "Documents")
    let developerURL = homeURL.appending(path: "Developer")
    let photosURL = homeURL.appending(path: "Pictures")

    try FileManager.default.createDirectory(
        at: documentsURL,
        withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
        at: developerURL,
        withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
        at: photosURL,
        withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
        at: applicationsURL,
        withIntermediateDirectories: true
    )

    try Data(repeating: 1, count: 10).write(to: documentsURL.appending(path: "document.bin"))
    try Data(repeating: 1, count: 20).write(to: developerURL.appending(path: "project.bin"))
    try Data(repeating: 1, count: 30).write(to: photosURL.appending(path: "photo.bin"))
    try Data(repeating: 1, count: 40).write(to: applicationsURL.appending(path: "app.bin"))

    let scanner = EstimatedStorageCategoryScanner(
        homeDirectoryURL: homeURL,
        applicationDirectoryURLs: [applicationsURL]
    )
    let cacheStore = StorageCategoryCacheStore(cacheDirectoryURL: cacheURL)
    let volume = VolumeSnapshot(
        id: rootURL.path,
        name: "Test Volume",
        localizedName: nil,
        mountPath: rootURL.path,
        kind: .internalDrive,
        fileSystemName: "APFS",
        totalBytes: 100_000,
        availableBytes: 10_000,
        importantAvailableBytes: nil,
        usedBytes: 90_000,
        categories: []
    )

    let categories = scanner.categories(for: volume, cacheStore: cacheStore)
    let ids = Set(categories.map(\.id))

    #expect(ids.contains(.applications))
    #expect(ids.contains(.developer))
    #expect(ids.contains(.documents))
    #expect(ids.contains(.photos))
    #expect(ids.contains(.other))
    #expect(ids.contains(.available))
    #expect(categories.contains { $0.confidence == .estimated })
}

@Test
func snapshotAppliesCategoryModes() {
    let volume = VolumeSnapshot(
        id: "volume",
        name: "Volume",
        localizedName: nil,
        mountPath: "/",
        kind: .internalDrive,
        fileSystemName: "APFS",
        totalBytes: 1_000,
        availableBytes: 300,
        importantAvailableBytes: nil,
        usedBytes: 700,
        categories: []
    )
    let snapshot = DiskSnapshot(generatedAt: Date(), volumes: [volume])
    let cacheStore = StorageCategoryCacheStore(
        cacheDirectoryURL: FileManager.default.temporaryDirectory
            .appending(path: "diskman-category-mode-tests")
            .appending(path: UUID().uuidString)
    )
    let scanner = StubCategoryScanner(categories: [
        StorageCategorySnapshot(
            id: .applications,
            localizedName: "Applications",
            colorToken: "applications",
            bytes: 100,
            confidence: .estimated
        ),
        StorageCategorySnapshot(
            id: .available,
            localizedName: "Available",
            colorToken: "available",
            bytes: 300,
            confidence: .exact
        )
    ])

    let off = snapshot.applyingCategoryMode(.off, scanner: scanner, cacheStore: cacheStore)
    let basic = snapshot.applyingCategoryMode(.basic, scanner: scanner, cacheStore: cacheStore)
    let estimated = snapshot.applyingCategoryMode(.estimated, scanner: scanner, cacheStore: cacheStore)

    #expect(off.volumes[0].categories.isEmpty)
    #expect(basic.volumes[0].categories.map(\.id) == [.used, .available])
    #expect(estimated.volumes[0].categories.map(\.id) == [.applications, .available])
}

private struct StubCategoryScanner: StorageCategoryScanning {
    let categories: [StorageCategorySnapshot]

    func categories(
        for volume: VolumeSnapshot,
        cacheStore: StorageCategoryCacheStore
    ) -> [StorageCategorySnapshot] {
        categories
    }
}
