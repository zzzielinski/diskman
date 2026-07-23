# Diskman - Project Analysis

## Project Goal

Diskman is a lightweight open source macOS app that runs continuously in the background, monitors currently connected disks, and displays storage usage in polished widgets inspired by Apple's Liquid Glass visual language.

The project has three visible surfaces:

1. A background macOS menu bar app responsible for collecting disk data.
2. Desktop widgets:
   - a small widget with circular free-space indicators for disks,
   - a larger widget with a segmented storage bar, categories, and a legend.
3. A macOS menu bar item with core actions such as `Quit Diskman`, `Language`, `About`, `Refresh`, and later `Launch at Login` plus quick visibility settings.

Target repository name: `diskman`.

## UX Assumptions

The visual direction should feel close to Apple's glass aesthetic: translucency, background blur, soft highlights, calm contrast, and subtle pointer-aware interactions. The goal is not to copy the reference screenshots literally, but to borrow their product logic:

- macOS Storage settings: horizontal segmented storage bars,
- Apple peripheral widgets: circular percentage indicators,
- macOS menu bar: compact system-native status item.

The interface should feel more considered than a raw system chart:

- readable disk icons for internal SSDs, external drives, network disks, removable media, and disk images,
- a restrained category palette rather than a loud random rainbow,
- subtle glass/tint behavior that works in light and dark mode,
- no heavy cards inside other cards,
- stable dimensions so widgets do not jump when disk values change,
- "last updated" status only in the larger widget or menu, keeping the small widget clean.

## Important Limitation: Real Time vs WidgetKit

A native macOS widget does not behave like a normal process rendering UI every second. WidgetKit receives data through snapshots and timelines, while macOS decides exactly when to refresh the rendered widget. That means:

- true real-time monitoring belongs in the main menu bar app,
- the widget displays the latest saved snapshot,
- after disk changes, the app can request a refresh with `WidgetCenter.reloadAllTimelines()`,
- the app should also refresh periodically, for example every 30-60 seconds, while widget timelines can refresh every few minutes,
- Diskman should not promise second-level accuracy inside WidgetKit because macOS may throttle updates.

If the project later needs a truly live desktop surface, the alternative is a separate floating desktop panel built with AppKit/SwiftUI. That would not be a native system-added widget, so the MVP should stay native: WidgetKit plus a background collector.

## Technologies

Recommended stack:

- Swift 6 or the current Swift version shipped with Xcode.
- SwiftUI for app UI, widgets, About, and Settings.
- WidgetKit for native macOS desktop and Notification Center widgets.
- AppKit through `NSStatusItem` for the macOS menu bar icon and menu.
- Foundation `FileManager` and `URLResourceValues` for listing volumes and reading capacity values.
- Disk Arbitration for quick reaction to mount, unmount, eject, and volume description changes.
- App Groups for sharing the latest snapshot between the app and widget extension.
- ServiceManagement `SMAppService` for `Launch at Login`.
- OSLog for diagnostics.
- Swift Package Manager for the shared core layer and unit tests.

Liquid Glass:

- on macOS Tahoe 26+, use SwiftUI `glassEffect(_:in:)`, `Glass`, `GlassEffectContainer`, and system components,
- on older systems, use a fallback based on `.background(.ultraThinMaterial)`, rounded shapes, subtle strokes, and shadows,
- UI code should use availability checks so the project can support older macOS versions if that becomes a goal.

## Minimum System Versions

Suggested split:

- best experience: macOS Tahoe 26+ because of Liquid Glass,
- minimum technical support: macOS 14+ or macOS 15+, where desktop widgets and modern SwiftUI/WidgetKit are reasonably available,
- if MVP maintenance cost should stay low, start at macOS 15+ or 26+ and add fallback support later.

MVP decision:

- `Diskman 0.1`: macOS 26+ as the primary target so the app can immediately look like a Liquid Glass app.
- `Diskman 0.2+`: visual fallback for older macOS versions if there is real demand.

## Architecture

Suggested modules:

```text
Diskman/
  DiskmanApp/               # menu bar app + settings/about
  DiskmanWidgets/           # WidgetKit extension
  DiskmanCore/              # models, collector, formatters, storage, localization
  DiskmanCLI/               # optional helper for debugging and install scripts
  scripts/
    install.sh
    uninstall.sh
  README.md
  info.md
```

Logical layers:

- `DiskMonitor`: watches disks appear and disappear.
- `VolumeProvider`: reads mounted volumes and raw system values.
- `VolumeClassifier`: identifies disk kind, for example internal, external, network, removable, Time Machine.
- `StorageSnapshotStore`: writes the latest snapshot to the App Group container as JSON or plist.
- `WidgetTimelineProvider`: reads the snapshot and builds widget views.
- `CategoryScanner`: optionally estimates storage categories.
- `LocalizationProvider`: chooses language and maps category IDs to display names.
- `MenuBarController`: owns the status item, menu, and app actions.

## Data Model

Example core model:

```swift
struct DiskSnapshot: Codable, Hashable {
    let generatedAt: Date
    let volumes: [VolumeSnapshot]
}

struct VolumeSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let localizedName: String?
    let mountPath: String
    let kind: VolumeKind
    let fileSystemName: String?
    let totalBytes: Int64
    let availableBytes: Int64
    let usedBytes: Int64
    let importantAvailableBytes: Int64?
    let categories: [StorageCategorySnapshot]
}

struct StorageCategorySnapshot: Codable, Hashable, Identifiable {
    let id: StorageCategoryID
    let localizedName: String
    let colorToken: String
    let bytes: Int64
    let confidence: CategoryConfidence
}
```

The percentage in the ring should default to free space, because that is the product behavior requested for the widget. A later setting can add `Show free space` / `Show used space`, but the default behavior should be `availableBytes / totalBytes`.

## Reading Connected Disks

Primary APIs:

- `FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys:options:)`,
- `URLResourceKey`: `volumeNameKey`, `volumeLocalizedNameKey`, `volumeTotalCapacityKey`, `volumeAvailableCapacityKey`, `volumeAvailableCapacityForImportantUsageKey`, `volumeIsBrowsableKey`, `volumeIsInternalKey`, `volumeIsEjectableKey`, `volumeIsRemovableKey`, `volumeLocalizedFormatDescriptionKey`.

Logic:

1. Load all mounted volumes.
2. Filter out technical/system helper volumes that should not be shown to users:
   - non-browsable volumes,
   - automounted helper volumes,
   - synthetic/system helper volumes,
   - mounts without meaningful capacity.
3. Keep the main system disk, external disks, USB drives, SD cards, network disks, and DMG images when they are browsable.
4. For each volume, calculate:
   - total,
   - available,
   - used,
   - free percent,
   - used percent,
   - disk kind,
   - display name.
5. Write the snapshot to the shared container.
6. Ask WidgetKit to refresh.

Fallback:

- if `URLResourceValues` cannot return complete data, use `statfs`.

## Runtime Change Handling

Diskman needs three refresh mechanisms because each catches a different class of changes:

- Disk Arbitration:
  - mount,
  - unmount,
  - eject,
  - disk name/description changes.
- Periodic polling:
  - for example every 30 seconds,
  - catches free-space changes even without mount/unmount events.
- Manual refresh:
  - exposed in the menu bar,
  - useful for debugging and users.

Flow:

```text
Disk event or timer
  -> VolumeProvider.refresh()
  -> DiskSnapshot
  -> StorageSnapshotStore.write()
  -> WidgetCenter.reloadAllTimelines()
  -> menu bar popover/status updates
```

## Storage Categories

This is the hardest part of the project.

macOS Settings shows categories such as Applications, Documents, Developer, Photos, Messages, and System Data. Apple does not expose a stable public API that lets third-party apps read exactly the same categories and localized names used by the Storage settings panel. The MVP should not pretend it can clone System Settings 1:1.

Current approach:

### Basic Mode

Show these values for each disk:

- used,
- available,
- purgeable/important/opportunistic available if the API returns useful data,
- disk kind.

The large widget should use a bar with:

- `Used`,
- `Available`,
- optionally `Purgeable` / `Available for opportunistic usage` when values are meaningful.

### Estimated Mode

Add a careful opt-in category scanner:

- Applications: `/Applications`, `~/Applications`, `.app` bundles,
- Developer: `~/Developer`, Xcode DerivedData, SwiftPM cache, `node_modules`, repositories,
- Photos: Photos libraries, images, and videos in known locations,
- Documents: Documents, Desktop, Downloads, and document file types,
- Messages: Messages attachments if the user grants access,
- System Data: remaining or unrecognized categories.

The scanner must be:

- opt-in through `Categories: Estimated`,
- cached in the App Group container,
- resilient to permission denied,
- clearly labelled as estimated in the widget legend.
- labeled with confidence, for example `Estimated`.

Diskman should not aggressively scan the whole disk without user consent. That would be slow, energy-hungry, and bad for privacy.

## Localization And Language

Priority:

1. Detect the system language through `Locale.current` / `Bundle.main.preferredLocalizations`.
2. Use `Localizable.strings` or a String Catalog (`.xcstrings`) for app UI, menu text, widgets, and categories.
3. Let the user override language:
   - `System`,
   - `English`,
   - `Polish`.

Categories should not be hardcoded as view text. Code should use stable IDs:

```swift
enum StorageCategoryID: String, Codable {
    case applications
    case documents
    case developer
    case photos
    case messages
    case systemData
    case other
    case used
    case available
}
```

Views ask `LocalizationProvider` for the display name for an ID. That allows more languages to be added later without changing storage logic.

If macOS returns a localized volume name through `volumeLocalizedNameKey`, Diskman should use it. Category names from System Settings probably cannot be fetched through public APIs, so Diskman should translate its own category names.

## Small Widget

Goal: quick free-space glance.

Layout:

- glass container,
- up to 3-4 disks in one widget,
- each disk as a circular progress ring,
- disk icon in the middle,
- percentage below,
- minimal text, usually only percentage or a shortened name through accessibility/expanded states.

Presentation logic:

- one disk: larger ring,
- 2-3 disks: equal rings,
- more than 4 disks: show the three most important disks and a fourth `+N` slot,
- ring color:
  - green: plenty of free space,
  - yellow: warning,
  - red: low free space,
  - neutral blue/gray for network disks or offline cache if needed later.

Thresholds:

- >= 25% free: ok,
- 10-25% free: warning,
- < 10% free: critical.

## Large Widget

Goal: a more detailed breakdown similar to macOS Storage.

Layout:

- disk name,
- `X GB free of Y GB` or localized equivalent,
- segmented storage bar,
- category legend,
- list of several disks or details for one selected disk.

Suggested variants:

- `systemMedium`: one selected disk with bar and legend,
- `systemLarge`: 2-3 disks, each with its own bar,
- widget configuration through App Intent: selected disk or `All disks`.

Bar:

- segments sorted descending by size,
- minimum visual width for tiny segments, while tooltips/accessibility keep true values,
- available space on the right as a separate neutral segment,
- central label only when it fits.

## Menu Bar

macOS menu bar item:

- SF Symbols icon, for example `externaldrive`, `internaldrive`, `chart.pie`,
- warning state when any disk is low on free space,
- menu:
  - `Refresh Now`,
  - `Open Settings`,
  - `Language`,
    - `System`,
    - `English`,
    - `Polish`,
  - `Show Internal Drives`,
  - `Show External Drives`,
  - `Show Network Volumes`,
  - `Launch at Login`,
  - `About Diskman`,
  - `Quit Diskman`.

A later version can also make clicking the icon open a compact popover with a disk list and mini bars.

## Settings

Initial scope:

- language,
- launch at login,
- which disk kinds to show,
- default disk for the large widget,
- free percent vs used percent,
- units: decimal GB or binary GiB,
- category mode:
  - Off,
  - Basic,
  - Estimated scanner.

Second scope:

- reset cache,
- deeper privacy screen explaining what is scanned,
- diagnostics export without personal data.

## Privacy And Permissions

Diskman should be privacy-conservative:

- no data is sent by default,
- no backend,
- no analytics,
- widget snapshots contain only disk names, mount paths, and sizes,
- category scanning is optional,
- if scanning needs access to user directories, show a clear explanation,
- if Required Reason APIs are used, add `PrivacyInfo.xcprivacy` with the correct reason.

README should include a separate `Privacy` section.

## Open Source Distribution

Repository:

```text
github.com/<owner>/diskman
```

Installation like a polished GitHub project:

MVP option:

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/diskman/main/scripts/install.sh | bash
```

What `install.sh` does:

1. Detects macOS architecture.
2. Downloads the latest GitHub Release.
3. Unpacks `Diskman.app`.
4. Moves the app to `/Applications` or `~/Applications`.
5. Launches the app.
6. Prints instructions for adding the widget to the desktop.

Long-term better option:

```bash
brew install --cask diskman
```

That requires a Homebrew tap or a PR to Homebrew Cask once the project is stable.

Important for macOS:

- ideally sign and notarize the app,
- without notarization, Gatekeeper may warn users,
- open source does not prevent signing, but it requires an Apple Developer account.

## Build And Release

Suggested GitHub Actions pipeline:

- build on `macos-latest`,
- run `DiskmanCore` tests,
- archive the `.app`,
- sign when secrets are available,
- notarize when secrets are available,
- create `.zip` or `.dmg`,
- publish a GitHub Release.

Artifacts:

- `Diskman.app.zip`,
- `SHA256SUMS`,
- optional `.dmg`,
- `install.sh`.

## Tests

Unit tests:

- byte formatting,
- percentage calculations,
- disk sorting,
- category mapping,
- category localization,
- snapshot write/read.

Integration/manual tests:

- internal disk,
- USB stick / USB SSD,
- DMG,
- network disk,
- eject while the app is running,
- language switching,
- missing scan permissions,
- very low free space,
- more than four disks.

## Roadmap

### 0.1 - MVP

- menu bar app,
- disk detection,
- App Group snapshot,
- small widget with rings,
- large widget with used/free bar,
- language modes: System / English / Polish,
- installation through GitHub Release and `install.sh`.

### 0.2 - Category Refinement

- reset scanner cache,
- refine scanner scopes,
- add confidence details,
- improve privacy settings.

### 0.3 - UX Polish

- App Intent for choosing a specific disk in a widget,
- better icons,
- low-space warnings,
- menu bar popover,
- Homebrew cask.

### 1.0

- signed and notarized release,
- stable core API,
- complete documentation,
- useful tests and manual QA matrix,
- polished Liquid Glass appearance.

## Technical Risks

Main risks:

- WidgetKit does not provide fully real-time rendering.
- macOS Storage categories are not publicly available 1:1.
- Directory scanning can be slow and require permissions.
- Liquid Glass requires a new SDK/system, so Diskman needs a fallback or a high deployment target.
- App Groups and WidgetKit require correct signing/capability setup.
- Distribution outside the App Store requires care around signing and notarization.

## Initial Decisions

1. Build a native macOS app using SwiftUI plus an AppKit menu bar item.
2. Build widgets through WidgetKit, while the background collector runs in the main app.
3. MVP shows real disk data: total, used, free, percent.
4. Start categories as `Used/Available`, with an opt-in estimated category scanner.
5. Language follows the system by default, with `English` / `Polish` override.
6. The repo is named `diskman`, with installation through GitHub Releases and `scripts/install.sh`.

## Technical References

- Apple Developer: SwiftUI `Glass` and Liquid Glass: https://developer.apple.com/documentation/swiftui/glass
- Apple Developer: `glassEffect(_:in:)`: https://developer.apple.com/documentation/swiftui/view/glasseffect%28_%3Ain%3A%29
- Apple Developer: WidgetKit on macOS: https://developer.apple.com/documentation/widgetkit
- Apple Developer: `FileManager.mountedVolumeURLs`: https://developer.apple.com/documentation/foundation/filemanager/mountedvolumeurls%28includingresourcevaluesforkeys%3Aoptions%3A%29
- Apple Developer: volume capacity keys: https://developer.apple.com/documentation/foundation/urlresourcekey
- Apple Developer: Disk Arbitration: https://developer.apple.com/documentation/diskarbitration
- Apple Support: macOS Tahoe 26: https://support.apple.com/en-us/122727
