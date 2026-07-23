# Diskman - Project Roadmap

This file is the working project map. It is updated after each meaningful step so it stays clear what already works, what is in progress, and what blocks later stages.

Statuses:

- `[ ]` todo
- `[~]` in progress
- `[x]` done
- `[!]` blocked or needs a decision

## MVP Goal

The first working Diskman version should:

- run as a macOS menu bar app,
- continuously collect information about connected disks,
- write a data snapshot for widgets,
- show a small widget with circular free-space indicators,
- show a large widget with a `used/free` storage bar,
- provide a menu with `Refresh`, `Language`, `About`, and `Quit Diskman`,
- support the system language plus manual `English` / `Polish` selection,
- build locally and install from a GitHub Release through a simple terminal script.

## Stage 0 - Repository Foundation

- [x] Initialize a local git repository in the project directory.
- [x] Add remote `https://github.com/zzzielinski/diskman.git`.
- [x] Set the main branch to `main`.
- [x] Add `.gitignore` for Xcode, SwiftPM, build artifacts, and macOS files.
- [x] Add a basic `README.md`.
- [x] Add an open source license.
- [x] Set bundle identifier: `com.zzzielinski.diskman`.
- [x] Set the MVP deployment target: macOS 26+ as the primary target.
- [x] Push the first documentation version to GitHub.

Done when:

- the local repo and GitHub are synchronized,
- `README.md`, `info.md`, `roadmap.md`, `.gitignore`, and the license are on `main`,
- the Xcode project can be created without structural clutter.

## Stage 1 - macOS App Skeleton

- [x] Create the Xcode project `Diskman`.
- [x] Add the macOS app target `DiskmanApp`.
- [x] Add the `DiskmanWidgets` target for WidgetKit.
- [x] Add the shared module/core package `DiskmanCore`.
- [x] Configure App Group for the app and widget extension.
- [x] Add a basic menu bar app without a main window.
- [x] Add `NSStatusItem` with an icon in the macOS menu bar.
- [x] Add a minimal menu:
  - [x] `Refresh Now`
  - [x] `Language`
  - [x] `About Diskman`
  - [x] `Quit Diskman`
- [x] Add an About placeholder.

Done when:

- the app launches locally,
- the Diskman icon is visible in the menu bar,
- `Quit Diskman` exits the app,
- the widget target compiles with the app.

## Stage 2 - Disk Data Core

- [x] Define models:
  - [x] `DiskSnapshot`
  - [x] `VolumeSnapshot`
  - [x] `VolumeKind`
  - [x] `StorageCategorySnapshot`
  - [x] `StorageCategoryID`
- [x] Add `ByteFormatter` for GB/GiB and localized strings.
- [x] Add `VolumeProvider` based on `FileManager.mountedVolumeURLs`.
- [x] Read for each volume:
  - [x] name,
  - [x] localized name, if returned by the system,
  - [x] mount path,
  - [x] total bytes,
  - [x] available bytes,
  - [x] used bytes,
  - [x] file system description,
  - [x] browsable/internal/ejectable/removable information when available.
- [x] Filter technical volumes the user should not see.
- [x] Add classification:
  - [x] internal,
  - [x] external,
  - [x] removable,
  - [x] network,
  - [x] disk image,
  - [x] unknown.
- [x] Add unit tests for percentage calculations and byte formatting.

Done when:

- core can return a correct list of visible disks,
- each disk has `used/free/total`,
- core tests pass locally.

## Stage 3 - Snapshot And Widget Communication

- [x] Add `StorageSnapshotStore`.
- [x] Write snapshots as JSON or plist in the App Group container.
- [x] Read snapshots from both the app and widget extension.
- [x] Add a fallback snapshot for empty state.
- [x] Add read/write error handling.
- [x] Call `WidgetCenter.reloadAllTimelines()` after writing a snapshot.
- [x] Add snapshot encode/decode tests.

Done when:

- the app writes a snapshot on startup,
- widgets can read a snapshot without launching the app,
- missing data shows a clean empty state instead of crashing.

## Stage 4 - Background Monitoring

- [x] Add `DiskMonitor`.
- [x] Add polling every 30-60 seconds for free-space changes.
- [x] Add manual refresh from the menu bar.
- [x] Add Disk Arbitration for mount/unmount/eject.
- [x] Refresh the snapshot after disk events.
- [x] Add debounce so event bursts do not trigger many refreshes.
- [x] Add OSLog for important events.

Done when:

- connecting a disk updates the snapshot,
- disconnecting a disk updates the snapshot,
- free-space changes refresh periodically,
- manual refresh works from the menu.

## Stage 5 - Small Widget

- [x] Add the widget family for the small view.
- [x] Build `DiskRingView`.
- [x] Show free-space percentage.
- [x] Show the disk-type icon.
- [x] Handle 1, 2, 3, and 4+ disks.
- [x] Choose status colors:
  - [x] ok,
  - [x] warning,
  - [x] critical.
- [x] Add glass/fallback material.
- [x] Add accessibility labels.
- [ ] Test light and dark mode.

Done when:

- the small widget shows current disks,
- layout does not jump when percentages change,
- the view is readable on the desktop and in Notification Center.

## Stage 6 - Large Widget

- [x] Add medium/large widget variants.
- [x] Build `StorageSegmentBar`.
- [x] For MVP, show segments:
  - [x] `Used`
  - [x] `Available`
- [x] Show disk name.
- [x] Show `X free of Y`.
- [x] Add a legend.
- [x] Handle multiple disks in the large layout.
- [x] Add empty/error states.
- [x] Add accessibility labels for segments.

Done when:

- the large widget follows macOS Storage logic,
- data is real,
- missing system categories are clearly handled through `Used/Available` in the MVP.

## Stage 7 - Liquid Glass And Design Polish

- [x] Add `DiskmanGlass` wrapper/modifier.
- [x] Use `glassEffect(_:in:)` on macOS 26+.
- [x] Use `.ultraThinMaterial` fallback on older systems.
- [ ] Refine shapes:
  - [x] rings,
  - [x] segment bar,
  - [x] menu popover,
  - [x] about/settings.
- [x] Set the final category color palette.
- [x] Choose SF Symbols for disk kinds.
- [ ] Review PL and EN text.
- [ ] Create reference screenshots.

Done when:

- UI looks coherent with macOS,
- the widget is not visually loud,
- Liquid Glass has a fallback and does not block builds on older targets if they are supported.

## Stage 8 - Language And Localization

- [x] Add String Catalog or `Localizable.strings`.
- [x] Add languages:
  - [x] English
  - [x] Polish
- [x] Add language mode:
  - [x] System
  - [x] English
  - [x] Polish
- [x] Localize the menu bar.
- [x] Localize widgets.
- [x] Localize MVP categories:
  - [x] Used
  - [x] Available
  - [x] Other
  - [x] System Data
- [x] Add `LocalizationProvider` so views do not hardcode category text.

Done when:

- the app starts in the system language,
- the user can force PL or EN,
- widgets and menu use the same translations.

## Stage 9 - Settings And About

- [x] Add a Settings window/panel.
- [x] Add `Launch at Login`.
- [x] Add language setting.
- [x] Add disk-kind visibility settings:
  - [x] internal,
  - [x] external,
  - [x] network,
  - [x] disk images.
- [x] Add `show free percent` / `show used percent`.
- [x] Add GB/GiB selection.
- [x] Add About:
  - [x] name,
  - [x] version,
  - [x] GitHub link,
  - [x] license,
  - [x] privacy note.

Done when:

- basic settings are saved in `UserDefaults`,
- setting changes refresh the snapshot and widget,
- About is ready for open source users.

## Stage 10 - Storage Categories

This stage does not block the MVP. Build it only after `used/free` is stable.

- [x] Define the category scanner scope.
- [x] Add `Categories: Off / Basic / Estimated` mode.
- [x] Add scan-result cache.
- [x] Add `Applications` scanner.
- [x] Add `Developer` scanner.
- [x] Add `Documents` scanner.
- [x] Add `Photos` scanner.
- [x] Add `Messages` scanner only if permissions allow it.
- [x] Add `System Data` / `Other` as the remainder.
- [x] Add confidence label: `Estimated`.
- [x] Add a privacy screen explaining scanning.
- [x] Add tests against artificial directories.

Done when:

- categories are optional,
- the scanner does not churn the disk aggressively,
- users understand that categories are estimated and not identical to System Settings.

## Stage 11 - Installation And Release

- [ ] Add `scripts/install.sh`.
- [ ] Add `scripts/uninstall.sh`.
- [ ] Add build/release instructions in README.
- [ ] Add GitHub Actions for builds.
- [ ] Add tests in CI.
- [ ] Prepare `Diskman.app.zip`.
- [ ] Add release checksums.
- [ ] Decide signing/notarization:
  - [ ] unsigned dev release,
  - [ ] signed release,
  - [ ] notarized release.
- [ ] Prepare first GitHub Release `v0.1.0`.
- [ ] Eventually prepare Homebrew Cask.

Done when:

- users can install Diskman through the terminal,
- the release has clear instructions,
- the app launches after download with no manual steps beyond standard Gatekeeper limitations.

## Stage 12 - QA Before v0.1

- [ ] Test on the main system disk.
- [ ] Test with a USB stick.
- [ ] Test with an external SSD.
- [ ] Test with a DMG.
- [ ] Test with a network disk.
- [ ] Test disconnecting a disk while the app is running.
- [ ] Test low free space.
- [ ] Test 4+ disks.
- [ ] Test light/dark mode.
- [ ] Test PL/EN/System language.
- [ ] Test launch after login.
- [ ] Test after Mac restart.
- [ ] Test widget without the app currently running.

Done when:

- there are no crashes in basic scenarios,
- widget data matches Finder/System Settings within normal API differences,
- README describes known limitations.

## Current Status

- [x] Project analysis document exists: `info.md`.
- [x] Project roadmap exists: `roadmap.md`.
- [x] Local git repository has been initialized.
- [x] GitHub repository `zzzielinski/diskman` exists and has starter documentation.
- [x] Xcode project skeleton exists with the app, widgets, and `DiskmanCore`.
- [x] Shared English/Polish localization is wired through `DiskmanCore`.
- [x] Settings persist display, language, launch, and disk visibility preferences.
- [x] Optional estimated storage categories are cached and labelled as estimates.

## Nearest Next Step

1. Start Stage 11: Installation and Release.
2. Add `scripts/install.sh`.
3. Add `scripts/uninstall.sh`.
