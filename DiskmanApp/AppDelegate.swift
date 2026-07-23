import AppKit
import DiskmanCore
import SwiftUI
import WidgetKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = DiskmanSettingsStore()
    private lazy var diskMonitor = DiskMonitor(settingsStore: settingsStore)
    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?
    private var aboutWindowController: NSWindowController?
    private var settingsWindowController: NSWindowController?
    private var settingsObserver: NSObjectProtocol?

    private var localization: LocalizationProvider {
        LocalizationProvider(settingsStore: settingsStore)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard terminateIfAnotherInstanceIsRunning() == false else {
            return
        }

        NSApp.setActivationPolicy(.accessory)
        observeSettingsChanges()
        configureStatusItem()
        configureDiskMonitor()
        diskMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }
        diskMonitor.stop()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleDeepLink(url)
        }
    }

    private func terminateIfAnotherInstanceIsRunning() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return false
        }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        let otherInstances = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .filter { $0.processIdentifier != currentPID && !$0.isTerminated }

        guard let existingInstance = otherInstances.first else {
            return false
        }

        existingInstance.activate()
        NSApp.terminate(nil)
        return true
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "internaldrive",
                accessibilityDescription: "Diskman"
            )
            image?.isTemplate = true

            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
            button.toolTip = "Diskman"
        }

        statusItem.menu = makeMenu()
        self.statusItem = statusItem
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let localization = localization
        let status = NSMenuItem(title: localization.string(.menuLoadingDisks), action: nil, keyEquivalent: "")
        status.isEnabled = false
        statusMenuItem = status
        menu.addItem(status)
        menu.addItem(.separator())

        menu.addItem(makeMenuItem(
            title: localization.string(.menuRefreshNow),
            action: #selector(refreshNow),
            keyEquivalent: "r"
        ))

        menu.addItem(makeMenuItem(
            title: localization.string(.menuSettings),
            action: #selector(showSettings),
            keyEquivalent: ","
        ))

        let languageMenu = NSMenu()
        languageMenu.addItem(languageMenuItem(for: .system, localization: localization))
        languageMenu.addItem(languageMenuItem(for: .english, localization: localization))
        languageMenu.addItem(languageMenuItem(for: .polish, localization: localization))

        let languageItem = NSMenuItem(title: localization.string(.menuLanguage), action: nil, keyEquivalent: "")
        menu.setSubmenu(languageMenu, for: languageItem)
        menu.addItem(languageItem)

        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: localization.string(.menuAboutDiskman), action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(makeMenuItem(title: localization.string(.menuQuitDiskman), action: #selector(quit), keyEquivalent: "q"))

        return menu
    }

    private func makeMenuItem(
        title: String,
        action: Selector?,
        keyEquivalent: String
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func languageMenuItem(
        for mode: DiskmanLanguageMode,
        localization: LocalizationProvider
    ) -> NSMenuItem {
        let action: Selector = switch mode {
        case .system:
            #selector(selectSystemLanguage)
        case .english:
            #selector(selectEnglish)
        case .polish:
            #selector(selectPolish)
        }

        let item = makeMenuItem(
            title: localization.languageDisplayName(for: mode),
            action: action,
            keyEquivalent: ""
        )
        item.state = settingsStore.languageMode == mode ? .on : .off
        return item
    }

    @objc private func refreshNow() {
        diskMonitor.refreshNow()
    }

    @objc private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)

        if let settingsWindowController {
            settingsWindowController.showWindow(nil)
            settingsWindowController.window?.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = localization.string(.menuSettings)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: SettingsView(settingsStore: settingsStore))
        window.center()

        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
    }

    private func configureDiskMonitor() {
        diskMonitor.onRefresh = { [weak self] event in
            DispatchQueue.main.async {
                self?.handleRefreshEvent(event)
            }
        }
    }

    private func handleRefreshEvent(_ event: DiskMonitor.RefreshEvent) {
        switch event.result {
        case .success(let snapshot):
            statusMenuItem?.title = menuStatusTitle(
                for: snapshot,
                snapshotWriteError: event.snapshotWriteError
            )
        case .failure:
            statusMenuItem?.title = localization.string(.menuUnableToReadDisks)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func menuStatusTitle(
        for snapshot: DiskSnapshot,
        snapshotWriteError: Error? = nil
    ) -> String {
        let localization = localization

        guard let primaryVolume = snapshot.volumes.first else {
            return localization.string(.menuNoDisksFound)
        }

        let title = localization.string(
            localization.usageDisplayMode == .free ? .menuStatusFree : .menuStatusUsed,
            snapshot.volumes.count,
            localization.diskLabel(count: snapshot.volumes.count),
            primaryVolume.displayName,
            localization.usagePercentText(for: primaryVolume)
        )

        guard snapshotWriteError != nil else {
            return title
        }

        return "\(title) - \(localization.string(.menuWidgetSnapshotUnavailable))"
    }

    @objc private func selectSystemLanguage() {
        setLanguageMode(.system)
    }

    @objc private func selectEnglish() {
        setLanguageMode(.english)
    }

    @objc private func selectPolish() {
        setLanguageMode(.polish)
    }

    private func setLanguageMode(_ mode: DiskmanLanguageMode) {
        settingsStore.languageMode = mode
        NotificationCenter.default.post(name: .diskmanSettingsDidChange, object: nil)
    }

    private func observeSettingsChanges() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: .diskmanSettingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.applySettingsChange()
            }
        }
    }

    private func applySettingsChange() {
        statusItem?.menu = makeMenu()
        settingsWindowController?.window?.title = localization.string(.menuSettings)
        aboutWindowController?.close()
        aboutWindowController = nil
        diskMonitor.refreshNow()
        WidgetCenter.shared.reloadAllTimelines()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)

        if let aboutWindowController {
            aboutWindowController.showWindow(nil)
            aboutWindowController.window?.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 330),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = localization.string(.menuAboutDiskman)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: AboutView(localization: localization))
        window.center()

        let controller = NSWindowController(window: window)
        aboutWindowController = controller
        controller.showWindow(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "diskman",
              url.host == "open-volume",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let mountPath = components.queryItems?.first(where: { $0.name == "path" })?.value,
              mountPath.isEmpty == false
        else {
            return
        }

        openVolumeInFinder(at: mountPath)
    }

    private func openVolumeInFinder(at mountPath: String) {
        let url = URL(filePath: mountPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
