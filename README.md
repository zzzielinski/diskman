# Diskman

Diskman is an open source macOS menu bar app and widget set for monitoring connected disks.

The goal is to provide a clean Liquid Glass-inspired disk widget for macOS:

- a small desktop widget with circular free-space indicators,
- a larger desktop widget with storage bars,
- a menu bar controller for refresh, language, about, settings, and quit,
- real disk data collected by a lightweight background app,
- English and Polish localization.

## Project Status

Diskman is currently in early scaffolding. The repository already contains:

- `DiskmanApp`: the macOS menu bar app target,
- `DiskmanWidgets`: the WidgetKit extension target,
- `DiskmanCore`: a local Swift package shared by the app and widgets,
- `VolumeProvider`: the first real mounted-volume reader based on Foundation volume APIs,
- `StorageSnapshotStore`: the JSON snapshot bridge between the app and WidgetKit extension,
- `DiskMonitor`: polling plus Disk Arbitration-driven refreshes,
- small WidgetKit disk rings for connected-volume free space,
- medium and large WidgetKit storage bars for used and available space,
- `DiskmanGlass`: a SwiftUI visual wrapper for Liquid Glass with material fallback,
- polished menu actions, Settings surface, and About window,
- shared English/Polish localization through `LocalizationProvider`.

See:

- [info.md](info.md) for the technical/product analysis,
- [roadmap.md](roadmap.md) for the implementation checklist.

## Planned Tech Stack

- Swift and SwiftUI
- WidgetKit
- AppKit `NSStatusItem`
- Foundation volume APIs
- Disk Arbitration
- App Groups
- ServiceManagement for launch at login

## Local Development

Requirements:

- macOS with Xcode 26+
- Swift 6

List project targets:

```bash
xcodebuild -list -project Diskman.xcodeproj
```

Build the app and widget extension without signing:

```bash
xcodebuild \
  -project Diskman.xcodeproj \
  -scheme DiskmanApp \
  -configuration Debug \
  -destination platform=macOS \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run core package tests:

```bash
cd DiskmanCore
swift test
```

## Privacy

Diskman is designed to work locally. The app should not send analytics or disk data anywhere. The MVP will only read mounted volume metadata such as name, mount path, total capacity, and available capacity.

Future category scanning will be opt-in and documented separately.

## Installation

Installation is not available yet. The planned flow is:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh | bash
```

## License

MIT License. See [LICENSE](LICENSE).
