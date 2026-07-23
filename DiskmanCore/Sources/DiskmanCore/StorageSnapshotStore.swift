import Foundation

public struct StorageSnapshotStore {
    public enum Error: Swift.Error, Equatable {
        case appGroupContainerUnavailable(String)
        case unableToCreateDirectory(String)
        case unableToWriteSnapshot(String)
        case unableToReadSnapshot(String)
        case unableToDecodeSnapshot(String)
    }

    public static let defaultAppGroupIdentifier = "group.com.zzzielinski.diskman"
    public static let fallbackApplicationSupportDirectoryName = "Diskman"
    public static let defaultSnapshotFileName = "diskman-snapshot.json"

    private let fileManager: FileManager
    private let snapshotURLProvider: () throws -> URL

    public init(
        appGroupIdentifier: String = Self.defaultAppGroupIdentifier,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.snapshotURLProvider = {
            try Self.sharedContainerURL(
                appGroupIdentifier: appGroupIdentifier,
                fileManager: fileManager
            )
            .appending(path: Self.defaultSnapshotFileName)
        }
    }

    public init(snapshotDirectoryURL: URL, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.snapshotURLProvider = {
            snapshotDirectoryURL.appending(path: Self.defaultSnapshotFileName)
        }
    }

    public func write(_ snapshot: DiskSnapshot) throws {
        let snapshotURL = try snapshotURLProvider()
        let directoryURL = snapshotURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw Error.unableToCreateDirectory(directoryURL.path)
        }

        do {
            let data = try Self.encoder.encode(snapshot)
            try data.write(to: snapshotURL, options: [.atomic])
        } catch {
            throw Error.unableToWriteSnapshot(snapshotURL.path)
        }
    }

    public func read() throws -> DiskSnapshot? {
        let snapshotURL = try snapshotURLProvider()

        guard fileManager.fileExists(atPath: snapshotURL.path) else {
            return nil
        }

        let data: Data
        do {
            data = try Data(contentsOf: snapshotURL)
        } catch {
            throw Error.unableToReadSnapshot(snapshotURL.path)
        }

        do {
            return try Self.decoder.decode(DiskSnapshot.self, from: data)
        } catch {
            throw Error.unableToDecodeSnapshot(snapshotURL.path)
        }
    }

    public func readOrPlaceholder() -> DiskSnapshot {
        (try? read()) ?? .placeholder
    }

    public func readOrEmpty() -> DiskSnapshot {
        (try? read()) ?? .empty
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

    public static func sharedContainerURL(
        appGroupIdentifier: String = Self.defaultAppGroupIdentifier,
        fileManager: FileManager = .default
    ) throws -> URL {
        if let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            return containerURL
        }

        let groupContainerURL = fileManager.homeDirectoryForCurrentUser
            .appending(path: "Library")
            .appending(path: "Group Containers")
            .appending(path: appGroupIdentifier)
        if fileManager.fileExists(atPath: groupContainerURL.path) {
            return groupContainerURL
        }

        if let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            return applicationSupportURL.appending(path: fallbackApplicationSupportDirectoryName)
        }

        throw Error.appGroupContainerUnavailable(appGroupIdentifier)
    }
}
