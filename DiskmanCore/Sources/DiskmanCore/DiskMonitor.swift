import DiskArbitration
import Foundation
import OSLog

@MainActor
public final class DiskMonitor {
    public struct Configuration: Sendable {
        public let pollingInterval: TimeInterval
        public let debounceInterval: TimeInterval

        public init(
            pollingInterval: TimeInterval = 60,
            debounceInterval: TimeInterval = 1
        ) {
            self.pollingInterval = pollingInterval
            self.debounceInterval = debounceInterval
        }
    }

    public enum RefreshReason: String, Sendable {
        case initial
        case timer
        case diskAppeared
        case diskDisappeared
        case diskDescriptionChanged
        case manual
    }

    public struct RefreshEvent {
        public let reason: RefreshReason
        public let date: Date
        public let result: Result<DiskSnapshot, Swift.Error>
        public let snapshotWriteError: Swift.Error?

        public init(
            reason: RefreshReason,
            date: Date,
            result: Result<DiskSnapshot, Swift.Error>,
            snapshotWriteError: Swift.Error?
        ) {
            self.reason = reason
            self.date = date
            self.result = result
            self.snapshotWriteError = snapshotWriteError
        }
    }

    public var onRefresh: ((RefreshEvent) -> Void)?

    private let volumeProvider: VolumeProviding
    private let snapshotStore: StorageSnapshotStore
    private let configuration: Configuration
    private let logger = Logger(subsystem: "com.zzzielinski.diskman", category: "DiskMonitor")

    private var pollingTimer: Timer?
    private var debounceTimer: Timer?
    private var diskSession: DASession?
    private var isRunning = false

    public init(
        volumeProvider: VolumeProviding = VolumeProvider(),
        snapshotStore: StorageSnapshotStore = StorageSnapshotStore(),
        configuration: Configuration = Configuration()
    ) {
        self.volumeProvider = volumeProvider
        self.snapshotStore = snapshotStore
        self.configuration = configuration
    }

    public func start() {
        guard !isRunning else { return }

        isRunning = true
        startPolling()
        startDiskArbitration()
        refresh(reason: .initial)
    }

    public func stop() {
        guard isRunning else { return }

        pollingTimer?.invalidate()
        pollingTimer = nil

        debounceTimer?.invalidate()
        debounceTimer = nil

        if let diskSession {
            DASessionSetDispatchQueue(diskSession, nil)
        }
        diskSession = nil

        isRunning = false
    }

    public func refreshNow() {
        debounceTimer?.invalidate()
        debounceTimer = nil
        refresh(reason: .manual)
    }

    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.pollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh(reason: .timer)
            }
        }
    }

    private func startDiskArbitration() {
        guard let session = DASessionCreate(kCFAllocatorDefault) else {
            logger.error("Unable to create Disk Arbitration session")
            return
        }

        let context = Unmanaged.passUnretained(self).toOpaque()

        DARegisterDiskAppearedCallback(session, nil, { _, context in
            guard let context else { return }
            let monitor = Unmanaged<DiskMonitor>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                monitor.scheduleRefresh(reason: .diskAppeared)
            }
        }, context)

        DARegisterDiskDisappearedCallback(session, nil, { _, context in
            guard let context else { return }
            let monitor = Unmanaged<DiskMonitor>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                monitor.scheduleRefresh(reason: .diskDisappeared)
            }
        }, context)

        DARegisterDiskDescriptionChangedCallback(session, nil, nil, { _, _, context in
            guard let context else { return }
            let monitor = Unmanaged<DiskMonitor>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                monitor.scheduleRefresh(reason: .diskDescriptionChanged)
            }
        }, context)

        DASessionSetDispatchQueue(session, DispatchQueue.main)
        diskSession = session
    }

    private func scheduleRefresh(reason: RefreshReason) {
        logger.debug("Scheduling refresh: \(reason.rawValue, privacy: .public)")

        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.debounceInterval,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh(reason: reason)
            }
        }
    }

    private func refresh(reason: RefreshReason) {
        logger.debug("Refreshing disks: \(reason.rawValue, privacy: .public)")

        do {
            let snapshot = try volumeProvider.snapshot()
            var writeError: Swift.Error?

            do {
                try snapshotStore.write(snapshot)
            } catch {
                writeError = error
                logger.error("Snapshot write failed: \(String(describing: error), privacy: .public)")
            }

            onRefresh?(
                RefreshEvent(
                    reason: reason,
                    date: Date(),
                    result: .success(snapshot),
                    snapshotWriteError: writeError
                )
            )
        } catch {
            logger.error("Disk refresh failed: \(String(describing: error), privacy: .public)")
            onRefresh?(
                RefreshEvent(
                    reason: reason,
                    date: Date(),
                    result: .failure(error),
                    snapshotWriteError: nil
                )
            )
        }
    }
}
