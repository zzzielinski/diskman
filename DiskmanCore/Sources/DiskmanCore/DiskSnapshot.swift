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
        self.usedBytes = usedBytes
        self.categories = categories
    }

    public var displayName: String {
        localizedName ?? name
    }

    public var freeSpaceRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(availableBytes) / Double(totalBytes)
    }

    public var usedSpaceRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    public var freePercentText: String {
        freeSpaceRatio.formatted(.percent.precision(.fractionLength(0)))
    }

    public var capacitySummary: String {
        "\(ByteCountFormatter.diskmanString(fromByteCount: availableBytes)) free of \(ByteCountFormatter.diskmanString(fromByteCount: totalBytes))"
    }
}

public enum VolumeKind: String, Codable, Hashable, Sendable {
    case internalDrive
    case externalDrive
    case removable
    case network
    case diskImage
    case unknown

    public var symbolName: String {
        switch self {
        case .internalDrive:
            return "internaldrive"
        case .externalDrive:
            return "externaldrive"
        case .removable:
            return "mediastick"
        case .network:
            return "network"
        case .diskImage:
            return "opticaldiscdrive"
        case .unknown:
            return "externaldrive.badge.questionmark"
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

public extension ByteCountFormatter {
    static func diskmanString(fromByteCount byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = .decimal
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: byteCount)
    }
}
