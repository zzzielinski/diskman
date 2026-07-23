import AppKit
import DiskmanCore
import SwiftUI
import WidgetKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let diskMonitor = DiskMonitor()
    private let settingsStore = DiskmanSettingsStore()
    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?
    private var aboutWindowController: NSWindowController?

    private var localization: LocalizationProvider {
        LocalizationProvider(settingsStore: settingsStore)
    }

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
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
            .menuStatus,
            snapshot.volumes.count,
            localization.diskLabel(count: snapshot.volumes.count),
            primaryVolume.displayName,
            primaryVolume.freePercentText
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
        statusItem?.menu = makeMenu()
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
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 250),
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
}
