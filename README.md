# Diskman

Diskman is an open source macOS menu bar app and widget set for monitoring connected disks.

The goal is to provide a clean Liquid Glass-inspired disk widget for macOS:

- a small desktop widget with circular free-space indicators,
- a larger desktop widget with storage bars,
- a menu bar controller for refresh, language, about, settings, and quit,
- real disk data collected by a lightweight background app,
- English and Polish localization.

## Project Status

Diskman is currently in the planning and foundation phase.

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
