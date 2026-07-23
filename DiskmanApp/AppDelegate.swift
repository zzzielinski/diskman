import AppKit
import DiskmanCore
import WidgetKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let diskMonitor = DiskMonitor()
    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureDiskMonitor()
        diskMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        diskMonitor.stop()
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "internaldrive",
                accessibilityDescription: "Diskman"
            )
            button.imagePosition = .imageLeading
            button.title = " Diskman"
        }

        statusItem.menu = makeMenu()
        self.statusItem = statusItem
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let status = NSMenuItem(title: "Loading disks...", action: nil, keyEquivalent: "")
        status.isEnabled = false
        statusMenuItem = status
        menu.addItem(status)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Refresh Now",
            action: #selector(refreshNow),
            keyEquivalent: "r"
        ))

        let languageMenu = NSMenu()
        languageMenu.addItem(NSMenuItem(title: "System", action: #selector(selectSystemLanguage), keyEquivalent: ""))
        languageMenu.addItem(NSMenuItem(title: "English", action: #selector(selectEnglish), keyEquivalent: ""))
        languageMenu.addItem(NSMenuItem(title: "Polski", action: #selector(selectPolish), keyEquivalent: ""))

        let languageItem = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        menu.setSubmenu(languageMenu, for: languageItem)
        menu.addItem(languageItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "About Diskman", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Diskman", action: #selector(quit), keyEquivalent: "q"))

        return menu
    }

    @objc private func refreshNow() {
        diskMonitor.refreshNow()
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
            statusMenuItem?.title = "Unable to read disks"
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func menuStatusTitle(
        for snapshot: DiskSnapshot,
        snapshotWriteError: Error? = nil
    ) -> String {
        guard let primaryVolume = snapshot.volumes.first else {
            return "No disks found"
        }

        let diskLabel = snapshot.volumes.count == 1 ? "disk" : "disks"
        let title = "\(snapshot.volumes.count) \(diskLabel) - \(primaryVolume.displayName): \(primaryVolume.freePercentText) free"

        guard snapshotWriteError != nil else {
            return title
        }

        return "\(title) - Widget snapshot unavailable"
    }

    @objc private func selectSystemLanguage() {
        // Language persistence lands with the localization stage.
    }

    @objc private func selectEnglish() {
        // Language persistence lands with the localization stage.
    }

    @objc private func selectPolish() {
        // Language persistence lands with the localization stage.
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Diskman"
        alert.informativeText = "A Liquid Glass-inspired disk monitor for macOS.\n\nVersion 0.1.0"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
