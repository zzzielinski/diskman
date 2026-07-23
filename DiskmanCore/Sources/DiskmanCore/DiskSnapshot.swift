import Foundation

public struct DiskSnapshot: Codable, Hashable, Sendable {
    public let generatedAt: Date
    public let volumes: [VolumeSnapshot]

    public init(generatedAt: Date, volumes: [VolumeSnapshot]) {
        self.generatedAt = generatedAt
        self.volumes = volumes
    }
}

public struct VolumeSnapshot: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let localizedName: String?
    public let mountPath: String
    public let kind: VolumeKind
    public let fileSystemName: String?
    public let totalBytes: Int64
    public let availableBytes: Int64
    public let importantAvailableBytes: Int64?
    public let usedBytes: Int64
    public let categories: [StorageCategorySnapshot]

    public init(
        id: String,
        name: String,
        localizedName: String?,
        mountPath: String,
        kind: VolumeKind,
        fileSystemName: String?,
        totalBytes: Int64,
        availableBytes: Int64,
        importantAvailableBytes: Int64?,
        usedBytes: Int64,
        categories: [StorageCategorySnapshot]
    ) {
        self.id = id
        self.name = name
        self.localizedName = localizedName
        self.mountPath = mountPath
        self.kind = kind
        self.fileSystemName = fileSystemName
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.importantAvailableBytes = importantAvailableBytes
        self.usedBytes = usedBytes
        self.categories = categories
    }

    public var displayName: String {
        localizedName ?? name
    }

    public var displayAvailableBytes: Int64 {
        Self.displayAvailableBytes(
            totalBytes: totalBytes,
            availableBytes: availableBytes,
            importantAvailableBytes: importantAvailableBytes
        )
    }

    public var displayUsedBytes: Int64 {
        max(0, totalBytes - displayAvailableBytes)
    }

    public var freeSpaceRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Self.ratio(displayAvailableBytes, totalBytes)
    }

    public var usedSpaceRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Self.ratio(displayUsedBytes, totalBytes)
    }

    public var freePercentText: String {
        freeSpaceRatio.formatted(.percent.precision(.fractionLength(0)))
    }

    public var usedPercentText: String {
        usedSpaceRatio.formatted(.percent.precision(.fractionLength(0)))
    }

    public var capacitySummary: String {
        "\(DiskByteFormatter.decimal.string(fromByteCount: displayAvailableBytes)) free of \(DiskByteFormatter.decimal.string(fromByteCount: totalBytes))"
    }

    public static func ratio(_ value: Int64, _ total: Int64) -> Double {
        guard total > 0 else { return 0 }
        return max(0, min(Double(value) / Double(total), 1))
    }

    public static func displayAvailableBytes(
        totalBytes: Int64,
        availableBytes: Int64,
        importantAvailableBytes: Int64?
    ) -> Int64 {
        let normalizedAvailableBytes = max(0, min(availableBytes, totalBytes))

        guard let importantAvailableBytes else {
            return normalizedAvailableBytes
        }

        let normalizedImportantAvailableBytes = max(0, min(importantAvailableBytes, totalBytes))
        guard normalizedImportantAvailableBytes > normalizedAvailableBytes else {
            return normalizedAvailableBytes
        }

        return normalizedImportantAvailableBytes
    }

    public func replacingCategories(_ categories: [StorageCategorySnapshot]) -> VolumeSnapshot {
        VolumeSnapshot(
            id: id,
            name: name,
            localizedName: localizedName,
            mountPath: mountPath,
            kind: kind,
            fileSystemName: fileSystemName,
            totalBytes: totalBytes,
            availableBytes: availableBytes,
            importantAvailableBytes: importantAvailableBytes,
            usedBytes: usedBytes,
            categories: categories
        )
    }

    public var basicCategories: [StorageCategorySnapshot] {
        Self.basicCategories(
            usedBytes: displayUsedBytes,
            availableBytes: displayAvailableBytes
        )
    }

    public static func basicCategories(
        usedBytes: Int64,
        availableBytes: Int64
    ) -> [StorageCategorySnapshot] {
        [
            StorageCategorySnapshot(
                id: .used,
                localizedName: "Used",
                colorToken: "used",
                bytes: usedBytes,
                confidence: .exact
            ),
            StorageCategorySnapshot(
                id: .available,
                localizedName: "Available",
                colorToken: "available",
                bytes: availableBytes,
                confidence: .exact
            )
        ]
    }
}

public enum VolumeKind: String, Codable, Hashable, Sendable {
    case internalDrive
    case externalDrive
    case removable
    case network
    case diskImage
    case iCloudDrive
    case unknown

    public var symbolName: String {
        switch self {
        case .internalDrive:
            return "internaldrive.fill"
        case .externalDrive:
            return "externaldrive.fill"
        case .removable:
            return "sdcard.fill"
        case .network:
            return "network"
        case .diskImage:
            return "opticaldiscdrive.fill"
        case .iCloudDrive:
            return "icloud.fill"
        case .unknown:
            return "externaldrive.fill.badge.questionmark"
        }
    }
}

public struct StorageCategorySnapshot: Codable, Hashable, Identifiable, Sendable {
    public let id: StorageCategoryID
    public let localizedName: String
    public let colorToken: String
    public let bytes: Int64
    public let confidence: CategoryConfidence

    public init(
        id: StorageCategoryID,
        localizedName: String,
        colorToken: String,
        bytes: Int64,
        confidence: CategoryConfidence
    ) {
        self.id = id
        self.localizedName = localizedName
        self.colorToken = colorToken
        self.bytes = bytes
        self.confidence = confidence
    }
}

public enum StorageCategoryID: String, Codable, Hashable, Sendable {
    case used
    case available
    case applications
    case documents
    case developer
    case iCloudDrive
    case photos
    case messages
    case systemData
    case other
}

public enum CategoryConfidence: String, Codable, Hashable, Sendable {
    case exact
    case estimated
    case placeholder
}

public extension DiskSnapshot {
    func filtered(visibleKinds: Set<DiskmanVisibleVolumeKind>) -> DiskSnapshot {
        DiskSnapshot(
            generatedAt: generatedAt,
            volumes: volumes.filter { volume in
                visibleKinds.contains(where: { visibleKind in
                    visibleKind.includes(volume.kind)
                })
            }
        )
    }

    func applyingCategoryMode(
        _ mode: DiskmanCategoryMode,
        scanner: StorageCategoryScanning,
        cacheStore: StorageCategoryCacheStore,
        preservesExistingEstimatedCategories: Bool = false
    ) -> DiskSnapshot {
        DiskSnapshot(
            generatedAt: generatedAt,
            volumes: volumes.map { volume in
                switch mode {
                case .off:
                    return volume.replacingCategories([])
                case .basic:
                    return volume.replacingCategories(volume.basicCategories)
                case .estimated:
                    if volume.kind == .iCloudDrive {
                        return volume.replacingCategories(volume.basicCategories)
                    }

                    if preservesExistingEstimatedCategories,
                       volume.hasEstimatedCategories {
                        return volume
                    }

                    let categories = scanner.categories(
                        for: volume,
                        cacheStore: cacheStore
                    )
                    return volume.replacingCategories(categories)
                }
            }
        )
    }

    static var empty: DiskSnapshot {
        DiskSnapshot(generatedAt: Date(), volumes: [])
    }

    static let placeholder = DiskSnapshot(
        generatedAt: Date(timeIntervalSince1970: 0),
        volumes: [
            VolumeSnapshot(
                id: "macintosh-hd",
                name: "Macintosh HD",
                localizedName: nil,
                mountPath: "/",
                kind: .internalDrive,
                fileSystemName: "APFS",
                totalBytes: 245_110_000_000,
                availableBytes: 92_400_000_000,
                importantAvailableBytes: nil,
                usedBytes: 152_710_000_000,
                categories: [
                    StorageCategorySnapshot(
                        id: .used,
                        localizedName: "Used",
                        colorToken: "used",
                        bytes: 152_710_000_000,
                        confidence: .placeholder
                    ),
                    StorageCategorySnapshot(
                        id: .available,
                        localizedName: "Available",
                        colorToken: "available",
                        bytes: 92_400_000_000,
                        confidence: .placeholder
                    )
                ]
            )
        ]
    )
}

private extension VolumeSnapshot {
    var hasEstimatedCategories: Bool {
        categories.contains { $0.confidence == .estimated }
    }
}
