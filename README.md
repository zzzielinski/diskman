# Diskman

Diskman is an open source macOS app that runs in the menu bar and provides WidgetKit widgets. It shows connected disks, free or used space, storage bars, and optional estimated storage categories without opening System Settings.

The idea was born from irritation that macOS does not include a simple, good-looking desktop widget for disk space. Diskman is meant to be that missing piece: it sits in the background, refreshes a local data snapshot, and gives widgets an up-to-date view of your mounted volumes.

## What It Does

- Shows internal disks, external disks, network volumes, and disk images.
- Provides small, medium, and large macOS widgets.
- Lets you click a disk in the widget to open it in Finder.
- Shows either free-space percentage or used-space percentage.
- Supports GB and GiB units.
- Includes optional storage categories: off, basic, or estimated.
- Works offline and stores a local App Group snapshot for widgets to read.
- Includes English and Polish UI.
- Can launch automatically when you sign in.

## Screenshots

Screenshots will be added after the final visual pass for the app and widgets.

## Installation

The simplest install downloads the latest GitHub Release and copies `Diskman.app` to `~/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh | bash
```

Install and open Diskman immediately:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh | bash -s -- --open
```

The installer:

- downloads `Diskman.app.zip` from the latest release,
- quits Diskman if it is already running,
- unregisters the old widget extension,
- copies the app to the selected install folder,
- registers the app and widget extension with macOS,
- refreshes widget and icon caches.

## Custom Install Folder

The default install location is `~/Applications`. You can choose another folder with `DISKMAN_INSTALL_DIR`.

Install to `/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh \
  | DISKMAN_INSTALL_DIR="/Applications" bash
```

Install to a custom folder:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh \
  | DISKMAN_INSTALL_DIR="$HOME/Tools" bash
```

Install to a custom folder and open immediately:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh \
  | DISKMAN_INSTALL_DIR="$HOME/Tools" bash -s -- --open
```

Installing to `/Applications` may require administrator permission if your account cannot write there.

## Opening The App

If Diskman is installed in the default location:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/open.sh | bash
```

The same without the helper script:

```bash
open "$HOME/Applications/Diskman.app"
```

If Diskman is installed in a custom folder:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/open.sh \
  | DISKMAN_INSTALL_DIR="$HOME/Tools" bash
```

The same without the helper script:

```bash
open "$HOME/Tools/Diskman.app"
```

## After Installation

After launch, Diskman appears in the menu bar. From the menu you can refresh now, rebuild widget data, open settings, open the about window, or quit the app.

Add the widget from the standard macOS widget gallery. If macOS still shows an old icon or an old widget version after an update, run the installer again. The installer refreshes WidgetKit registration and icon caches.

## Settings

### Language

`System` follows the macOS language. `English` and `Polish` force a specific language for Diskman only.

### Theme

`System` follows macOS appearance. `Light` and `Dark` force the app appearance independently of the system.

### Percent Mode

`Free` shows the percentage of free space. `Used` shows the percentage of used space.

This setting affects widgets, including the small ring widget. For example, if a disk is 70% used and 30% free, `Free` shows 30%, while `Used` shows 70%.

### Storage Units

`GB` uses decimal units, where 1 GB = 1,000,000,000 bytes.

`GiB` uses binary units, where 1 GiB = 1,073,741,824 bytes.

### Categories

`Off` shows basic disk information without category segments.

`Basic` shows a simple split between used and available space. This is the most reliable mode because it is based on macOS volume capacity data.

`Estimated` tries to break used space into categories such as applications, documents, developer files, photos, messages, system data, and other. These are estimates, not the exact private categories shown by macOS System Settings.

### Deep Folder Scan

Deep folder scan checks additional user folders, including Documents, Photos, Messages, and Downloads. macOS may require Full Disk Access before Diskman can read some of these local folders.

The `Open Full Disk Access` button opens the macOS privacy settings. After granting access, use `Rebuild Data`.

### Disk Visibility

This section controls which volume types appear in the app and widgets:

- `Internal`: the built-in Mac disk.
- `External`: USB, Thunderbolt, and similar attached storage.
- `Network`: mounted network shares.
- `Disk Images`: mounted `.dmg` files and similar disk images.

### Launch At Login

Starts Diskman automatically after you sign in to macOS. The app then runs in the background and keeps widget data up to date.

### Refresh, Snapshot, And Rebuild Data

`Refresh Automatic` means Diskman periodically checks volumes and also reacts to Disk Arbitration events, such as connecting or disconnecting a disk.

`Snapshot Shared` means the app writes a local snapshot in the App Group container, and widgets read from that snapshot.

`Rebuild Data` forces a fresh read and writes a new widget snapshot. Use it after changing settings, granting Full Disk Access, or when a widget still shows older data.

## What Data Diskman Uses

Diskman works locally and offline. It does not send data to any API, does not collect analytics, and does not need the internet to run.

The app reads local macOS volume data:

- volume name,
- mount path,
- volume type,
- total capacity,
- available capacity,
- important available capacity reported by macOS,
- used space calculated from capacity and available capacity.

When estimated categories are enabled, Diskman may scan selected local folders to calculate file sizes. Results are stored locally in a cache and marked as estimated because macOS does not expose the exact same private storage categories that it shows in System Settings.

## Uninstall

Remove the app, settings, widget snapshots, caches, and logs:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh | bash
```

Preview what would be removed:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh | bash -s -- --dry-run
```

Remove the app but keep local data:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh | bash -s -- --keep-data
```

Uninstall Diskman from a custom folder:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh \
  | bash -s -- --app "$HOME/Tools/Diskman.app"
```

The uninstall script intentionally preserves the local project workspace.

## Build From Source

Clone the repository:

```bash
git clone https://github.com/zzzielinski/diskman.git
cd diskman
```

List Xcode schemes:

```bash
xcodebuild -list -project Diskman.xcodeproj
```

Build the app and widget without code signing:

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

Create a `.zip` package and SHA-256 checksum:

```bash
./scripts/package-release.sh
```

Outputs:

```text
build/release/Diskman.app.zip
build/release/Diskman.app.zip.sha256
```

Install and open a local build:

```bash
./scripts/package-release.sh
./scripts/install.sh --zip build/release/Diskman.app.zip --open
```

Current release builds are signed ad-hoc but are not notarized. macOS may show the standard Gatekeeper warning on first launch.

## Project Structure

```text
DiskmanApp/       macOS app, menu, settings, and about window
DiskmanWidgets/   WidgetKit extension
DiskmanCore/      shared models, disk monitoring, cache, localization, and category scanning
scripts/          install, uninstall, open, and release packaging scripts
```

## License

Diskman is released under the MIT License. See [LICENSE](LICENSE) for details.
