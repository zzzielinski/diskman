import Foundation

public protocol VolumeProviding {
    func snapshot() throws -> DiskSnapshot
}

public struct VolumeProvider: VolumeProviding {
    public enum Error: Swift.Error {
        case unableToLoadMountedVolumes
    }

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func snapshot() throws -> DiskSnapshot {
        let resourceKeys = VolumeResourceSnapshot.resourceKeys
        guard let mountedVolumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: Array(resourceKeys),
            options: [.skipHiddenVolumes]
        ) else {
            throw Error.unableToLoadMountedVolumes
        }

        let volumes = mountedVolumes.compactMap { volumeURL -> VolumeSnapshot? in
            guard let resources = try? volumeURL.resourceValues(forKeys: resourceKeys) else {
                return nil
            }

            let resourceSnapshot = VolumeResourceSnapshot(url: volumeURL, values: resources)
            return VolumeSnapshot(resource: resourceSnapshot)
        }

        return DiskSnapshot(generatedAt: Date(), volumes: volumes.sortedForDisplay())
    }
}

struct VolumeResourceSnapshot: Sendable {
    static let resourceKeys: Set<URLResourceKey> = [
        .volumeNameKey,
        .volumeLocalizedNameKey,
        .volumeLocalizedFormatDescriptionKey,
        .volumeTotalCapacityKey,
        .volumeAvailableCapacityKey,
        .volumeAvailableCapacityForImportantUsageKey,
        .volumeIsBrowsableKey,
        .volumeIsInternalKey,
        .volumeIsEjectableKey,
        .volumeIsRemovableKey,
        .volumeIsLocalKey,
        .volumeIsAutomountedKey
    ]

    let url: URL
    let name: String?
    let localizedName: String?
    let localizedFormatDescription: String?
    let totalCapacity: Int?
    let availableCapacity: Int?
    let importantAvailableCapacity: Int64?
    let isBrowsable: Bool?
    let isInternal: Bool?
    let isEjectable: Bool?
    let isRemovable: Bool?
    let isLocal: Bool?
    let isAutomounted: Bool?

    init(
        url: URL,
        name: String?,
        localizedName: String?,
        localizedFormatDescription: String?,
        totalCapacity: Int?,
        availableCapacity: Int?,
        importantAvailableCapacity: Int64?,
        isBrowsable: Bool?,
        isInternal: Bool?,
        isEjectable: Bool?,
        isRemovable: Bool?,
        isLocal: Bool?,
        isAutomounted: Bool?
    ) {
        self.url = url
        self.name = name
        self.localizedName = localizedName
        self.localizedFormatDescription = localizedFormatDescription
        self.totalCapacity = totalCapacity
        self.availableCapacity = availableCapacity
        self.importantAvailableCapacity = importantAvailableCapacity
        self.isBrowsable = isBrowsable
        self.isInternal = isInternal
        self.isEjectable = isEjectable
        self.isRemovable = isRemovable
        self.isLocal = isLocal
        self.isAutomounted = isAutomounted
    }

    init(url: URL, values: URLResourceValues) {
        self.init(
            url: url,
            name: values.volumeName,
            localizedName: values.volumeLocalizedName,
            localizedFormatDescription: values.volumeLocalizedFormatDescription,
            totalCapacity: values.volumeTotalCapacity,
            availableCapacity: values.volumeAvailableCapacity,
            importantAvailableCapacity: values.volumeAvailableCapacityForImportantUsage,
            isBrowsable: values.volumeIsBrowsable,
            isInternal: values.volumeIsInternal,
            isEjectable: values.volumeIsEjectable,
            isRemovable: values.volumeIsRemovable,
            isLocal: values.volumeIsLocal,
            isAutomounted: values.volumeIsAutomounted
        )
    }

    var displayableName: String {
        let fallbackName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        return name?.nilIfBlank ?? localizedName?.nilIfBlank ?? fallbackName
    }

    var shouldDisplay: Bool {
        guard isBrowsable ?? true else { return false }
        guard !(isAutomounted ?? false) else { return false }
        guard let totalCapacity, totalCapacity > 0 else { return false }
        guard let availableCapacity, availableCapacity >= 0 else { return false }
        return true
    }

    var kind: VolumeKind {
        if isLocal == false {
            return .network
        }

        if looksLikeDiskImage {
            return .diskImage
        }

        if isInternal == true {
            return .internalDrive
        }

        if isRemovable == true {
            return .removable
        }

        if isEjectable == true {
            return .externalDrive
        }

        return .unknown
    }

    private var looksLikeDiskImage: Bool {
        let lowercasedDescription = localizedFormatDescription?.lowercased() ?? ""
        return lowercasedDescription.contains("disk image") || lowercasedDescription.contains("obraz dysku")
    }
}

extension VolumeSnapshot {
    init?(resource: VolumeResourceSnapshot) {
        guard resource.shouldDisplay,
              let totalCapacity = resource.totalCapacity,
              let availableCapacity = resource.availableCapacity
        else {
            return nil
        }

        let totalBytes = Int64(totalCapacity)
        let availableBytes = Int64(availableCapacity)
        let importantAvailableBytes = resource.importantAvailableCapacity
        let displayAvailableBytes = max(0, min(importantAvailableBytes ?? availableBytes, totalBytes))
        let usedBytes = max(0, totalBytes - availableBytes)
        let displayUsedBytes = max(0, totalBytes - displayAvailableBytes)

        self.init(
            id: resource.url.path,
            name: resource.displayableName,
            localizedName: resource.localizedName?.nilIfBlank,
            mountPath: resource.url.path,
            kind: resource.kind,
            fileSystemName: resource.localizedFormatDescription,
            totalBytes: totalBytes,
            availableBytes: availableBytes,
            importantAvailableBytes: importantAvailableBytes,
            usedBytes: usedBytes,
            categories: VolumeSnapshot.basicCategories(
                usedBytes: displayUsedBytes,
                availableBytes: displayAvailableBytes
            )
        )
    }
}

private extension Array where Element == VolumeSnapshot {
    func sortedForDisplay() -> [VolumeSnapshot] {
        sorted { lhs, rhs in
            if lhs.mountPath == "/" {
                return true
            }

            if rhs.mountPath == "/" {
                return false
            }

            if lhs.kind != rhs.kind {
                return lhs.kind.displayPriority < rhs.kind.displayPriority
            }

            return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        }
    }
}

private extension VolumeKind {
    var displayPriority: Int {
        switch self {
        case .internalDrive:
            return 0
        case .externalDrive:
            return 1
        case .removable:
            return 2
        case .diskImage:
            return 3
        case .network:
            return 4
        case .unknown:
            return 5
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
