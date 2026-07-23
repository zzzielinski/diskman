# Diskman

Diskman is an open source macOS menu bar app and WidgetKit extension for monitoring mounted disks.

It is useful for people who frequently work with external drives, disk images, network volumes, development machines, or Macs with limited internal storage. Diskman shows connected volumes, free or used space, storage bars, and optional estimated categories directly from macOS desktop widgets and the menu bar.

## Features

- Menu bar app that runs in the background.
- Small widget with circular disk usage indicators.
- Medium and large widgets with segmented storage bars.
- Clickable widget disks that open the selected volume in Finder.
- Mounted volume detection for internal, external, removable, network, and disk image volumes.
- Manual refresh plus automatic refresh using polling and Disk Arbitration events.
- Settings for language, disk visibility, percent mode, units, categories, and launch at login.
- English and Polish localization.
- Optional estimated categories for Applications, Developer, Documents, Photos, Messages, System Data, Other, and Available.
- Local App Group snapshot cache shared between the app and widgets.
- Liquid Glass visual styling on supported macOS versions with a material fallback.

## Screenshots

Screenshots will be added after device testing.

## Privacy

Diskman works 100% offline.

The app does not require an internet connection, does not collect analytics, does not send disk data anywhere, and does not use any network API at runtime. Diskman reads local macOS volume metadata such as name, mount path, total capacity, available capacity, and volume kind.

Estimated storage categories are optional. When enabled, Diskman scans local folders on the Mac, caches the results locally, and labels the categories as estimates because they are not the same private data shown by macOS System Settings.

## Open Source

Diskman is open source under the MIT License. You can fork it, change it, improve it, build your own version, or contribute fixes and features.

## Requirements

- macOS with Xcode 26+
- Swift 6

## Installation

Install the latest GitHub Release:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh | bash
```

The installer downloads `Diskman.app.zip` from the latest release and installs `Diskman.app` into `~/Applications`.
It also registers the embedded widget extension with macOS after copying the app.

Use a custom install directory:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh \
  | DISKMAN_INSTALL_DIR="/Applications" bash
```

Installing into `/Applications` may require administrator write permissions.

Uninstall Diskman:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh | bash
```

Remove local Diskman settings and widget snapshots too:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh | bash -s -- --remove-data
```

## Build From Source

Clone the repository:

```bash
git clone https://github.com/zzzielinski/diskman.git
cd diskman
```

List available schemes:

```bash
xcodebuild -list -project Diskman.xcodeproj
```

Build the app and widget extension without code signing:

```bash
xcodebuild \
  -project Diskman.xcodeproj \
  -scheme DiskmanApp \
  -configuration Debug \
  -destination platform=macOS \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run core tests:

```bash
cd DiskmanCore
swift test
```

## Release Build

Create a distributable zip and SHA-256 checksum:

```bash
./scripts/package-release.sh
```

Outputs:

```text
build/release/Diskman.app.zip
build/release/Diskman.app.zip.sha256
```

Current release builds are ad-hoc signed but not notarized. macOS may show the standard Gatekeeper warning when opening the app for the first time.

## Project Structure

```text
DiskmanApp/       macOS menu bar app, settings, and about window
DiskmanWidgets/   WidgetKit extension
DiskmanCore/      shared models, disk monitoring, persistence, localization, and category scanning
scripts/          install, uninstall, and release packaging scripts
```

## License

Diskman is released under the MIT License. See [LICENSE](LICENSE).
