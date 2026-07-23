import Foundation

public protocol StorageCategoryScanning {
    func categories(
        for volume: VolumeSnapshot,
        cacheStore: StorageCategoryCacheStore
    ) -> [StorageCategorySnapshot]
}

public struct StorageCategoryCacheStore {
    public enum Error: Swift.Error, Equatable {
        case appGroupContainerUnavailable(String)
        case unableToCreateDirectory(String)
        case unableToWriteCache(String)
        case unableToReadCache(String)
        case unableToDecodeCache(String)
    }

    public static let defaultCacheFileName = "diskman-category-cache.json"
    public static let defaultTimeToLive: TimeInterval = 30 * 60

    private let fileManager: FileManager
    private let cacheURLProvider: () throws -> URL

    public init(
        appGroupIdentifier: String = StorageSnapshotStore.defaultAppGroupIdentifier,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.cacheURLProvider = {
            try StorageSnapshotStore.sharedContainerURL(
                appGroupIdentifier: appGroupIdentifier,
                fileManager: fileManager
            )
            .appending(path: Self.defaultCacheFileName)
        }
    }

    public init(cacheDirectoryURL: URL, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.cacheURLProvider = {
            cacheDirectoryURL.appending(path: Self.defaultCacheFileName)
        }
    }

    public func cachedResult(
        for volumeID: String,
        now: Date = Date(),
        timeToLive: TimeInterval = Self.defaultTimeToLive
    ) throws -> StorageCategoryScanResult? {
        guard let cache = try readCache(),
              let result = cache.results[volumeID]
        else {
            return nil
        }

        guard now.timeIntervalSince(result.generatedAt) <= timeToLive else {
            return nil
        }

        return result
    }

    public func write(_ result: StorageCategoryScanResult) throws {
        let cacheURL = try cacheURLProvider()
        let directoryURL = cacheURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw Error.unableToCreateDirectory(directoryURL.path)
        }

        var cache = (try? readCache()) ?? StorageCategoryCache(results: [:])
        cache.results[result.volumeID] = result

        do {
            let data = try Self.encoder.encode(cache)
            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            throw Error.unableToWriteCache(cacheURL.path)
        }
    }

    private func readCache() throws -> StorageCategoryCache? {
        let cacheURL = try cacheURLProvider()

        guard fileManager.fileExists(atPath: cacheURL.path) else {
            return nil
        }

        let data: Data
        do {
            data = try Data(contentsOf: cacheURL)
        } catch {
            throw Error.unableToReadCache(cacheURL.path)
        }

        do {
            return try Self.decoder.decode(StorageCategoryCache.self, from: data)
        } catch {
            throw Error.unableToDecodeCache(cacheURL.path)
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

public struct StorageCategoryCache: Codable, Hashable, Sendable {
    public var results: [String: StorageCategoryScanResult]

    public init(results: [String: StorageCategoryScanResult]) {
        self.results = results
    }
}

public struct StorageCategoryScanResult: Codable, Hashable, Sendable {
    public let volumeID: String
    public let generatedAt: Date
    public let categories: [StorageCategorySnapshot]

    public init(
        volumeID: String,
        generatedAt: Date,
        categories: [StorageCategorySnapshot]
    ) {
        self.volumeID = volumeID
        self.generatedAt = generatedAt
        self.categories = categories
    }
}

public struct EstimatedStorageCategoryScanner: StorageCategoryScanning {
    private let fileManager: FileManager
    private let homeDirectoryURL: URL
    private let applicationDirectoryURLs: [URL]
    private let deepCategoryScanOverride: Bool?

    public init(
        fileManager: FileManager = .default,
        homeDirectoryURL: URL = FileManager.default.homeDirectoryForCurrentUser,
        applicationDirectoryURLs: [URL] = [
            URL(filePath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications")
        ],
        deepCategoryScanEnabled: Bool? = nil
    ) {
        self.fileManager = fileManager
        self.homeDirectoryURL = homeDirectoryURL
        self.applicationDirectoryURLs = applicationDirectoryURLs
        self.deepCategoryScanOverride = deepCategoryScanEnabled
    }

    public func categories(
        for volume: VolumeSnapshot,
        cacheStore: StorageCategoryCacheStore
    ) -> [StorageCategorySnapshot] {
        let cacheVolumeID = cacheVolumeID(for: volume)
        if let cachedResult = try? cacheStore.cachedResult(for: cacheVolumeID) {
            return composeCategories(
                from: cachedResult.categories,
                for: volume
            )
        }

        let estimates = scanEstimatedCategories(for: volume)
        let result = StorageCategoryScanResult(
            volumeID: cacheVolumeID,
            generatedAt: Date(),
            categories: estimates
        )
        try? cacheStore.write(result)

        return composeCategories(from: estimates, for: volume)
    }

    private func scanEstimatedCategories(for volume: VolumeSnapshot) -> [StorageCategorySnapshot] {
        guard volumeSupportsHomeScopes(volume) else {
            return []
        }

        var categoryRoots: [(StorageCategoryID, [URL])] = [
            (.applications, applicationDirectoryURLs),
            (.developer, developerDirectoryURLs)
        ]

        if deepCategoryScanEnabled {
            categoryRoots.append(contentsOf: [
                (.documents, documentDirectoryURLs),
                (.iCloudDrive, iCloudDriveDirectoryURLs),
                (.photos, photoDirectoryURLs),
                (.messages, messageDirectoryURLs)
            ])
        }

        return categoryRoots.compactMap { id, urls in
            let bytes = urls
                .filter { isURL($0, inside: volume) }
                .reduce(Int64(0)) { partialResult, url in
                    partialResult + directorySize(at: url)
                }

            guard bytes > 0 else {
                return nil
            }

            return StorageCategorySnapshot(
                id: id,
                localizedName: id.rawValue,
                colorToken: id.rawValue,
                bytes: bytes,
                confidence: .estimated
            )
        }
    }

    private func composeCategories(
        from estimates: [StorageCategorySnapshot],
        for volume: VolumeSnapshot
    ) -> [StorageCategorySnapshot] {
        let cappedEstimates = cap(estimates, maxTotalBytes: volume.displayUsedBytes)
        let estimatedBytes = cappedEstimates.reduce(Int64(0)) { $0 + $1.bytes }
        let remainderBytes = max(0, volume.displayUsedBytes - estimatedBytes)
        let remainderID: StorageCategoryID = volume.mountPath == "/" ? .systemData : .other

        var categories = cappedEstimates
        if remainderBytes > 0 {
            categories.append(
                StorageCategorySnapshot(
                    id: remainderID,
                    localizedName: remainderID.rawValue,
                    colorToken: remainderID.rawValue,
                    bytes: remainderBytes,
                    confidence: .estimated
                )
            )
        }

        categories.append(
            StorageCategorySnapshot(
                id: .available,
                localizedName: "Available",
                colorToken: "available",
                bytes: volume.displayAvailableBytes,
                confidence: .exact
            )
        )

        return categories
    }

    private func cap(
        _ categories: [StorageCategorySnapshot],
        maxTotalBytes: Int64
    ) -> [StorageCategorySnapshot] {
        var remainingBytes = maxTotalBytes
        return categories.compactMap { category in
            guard remainingBytes > 0 else {
                return nil
            }

            let bytes = min(category.bytes, remainingBytes)
            remainingBytes -= bytes

            return StorageCategorySnapshot(
                id: category.id,
                localizedName: category.localizedName,
                colorToken: category.colorToken,
                bytes: bytes,
                confidence: category.confidence
            )
        }
    }

    private var developerDirectoryURLs: [URL] {
        [
            homeDirectoryURL.appending(path: "Developer"),
            homeDirectoryURL.appending(path: "Code"),
            homeDirectoryURL.appending(path: "Projects"),
            homeDirectoryURL.appending(path: "Library/Developer"),
            homeDirectoryURL.appending(path: ".gradle"),
            homeDirectoryURL.appending(path: ".pub-cache")
        ]
    }

    private var documentDirectoryURLs: [URL] {
        [
            homeDirectoryURL.appending(path: "Desktop"),
            homeDirectoryURL.appending(path: "Documents"),
            homeDirectoryURL.appending(path: "Downloads")
        ]
    }

    private var iCloudDriveDirectoryURLs: [URL] {
        [
            homeDirectoryURL
                .appending(path: "Library/Mobile Documents/com~apple~CloudDocs")
        ]
    }

    private var photoDirectoryURLs: [URL] {
        [
            homeDirectoryURL.appending(path: "Pictures")
        ]
    }

    private var messageDirectoryURLs: [URL] {
        [
            homeDirectoryURL.appending(path: "Library/Messages")
        ]
    }

    private func volumeSupportsHomeScopes(_ volume: VolumeSnapshot) -> Bool {
        isURL(homeDirectoryURL, inside: volume)
    }

    private func isURL(_ url: URL, inside volume: VolumeSnapshot) -> Bool {
        let standardizedPath = url.standardizedFileURL.path
        let mountPath = URL(filePath: volume.mountPath).standardizedFileURL.path

        guard mountPath != "/" else {
            return standardizedPath.hasPrefix("/")
        }

        return standardizedPath == mountPath || standardizedPath.hasPrefix("\(mountPath)/")
    }

    private var deepCategoryScanEnabled: Bool {
        deepCategoryScanOverride ?? DiskmanSettingsStore().deepCategoryScanEnabled
    }

    private func cacheVolumeID(for volume: VolumeSnapshot) -> String {
        let scanMode = deepCategoryScanEnabled ? "deep" : "safe"
        return "\(volume.id)#\(scanMode)#v2"
    }

    private func directorySize(at url: URL) -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else {
            return 0
        }

        var totalBytes: Int64 = 0
        let resourceKeys: [URLResourceKey] = [
            .isRegularFileKey,
            .fileSizeKey,
            .totalFileAllocatedSizeKey,
            .isSymbolicLinkKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return fileSize(at: url)
        }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  values.isSymbolicLink != true,
                  values.isRegularFile == true
            else {
                continue
            }

            let allocatedSize = values.totalFileAllocatedSize.map(Int64.init)
            let fileSize = values.fileSize.map(Int64.init)
            totalBytes += allocatedSize ?? fileSize ?? 0
        }

        return totalBytes
    }

    private func fileSize(at url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [
            .isRegularFileKey,
            .fileSizeKey,
            .totalFileAllocatedSizeKey
        ]),
              values.isRegularFile == true
        else {
            return 0
        }

        return values.totalFileAllocatedSize.map(Int64.init) ?? values.fileSize.map(Int64.init) ?? 0
    }
}
