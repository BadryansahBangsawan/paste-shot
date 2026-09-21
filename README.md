# Paste Shot

[![Build](https://github.com/BadryansahBangsawan/paste-shot/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/paste-shot/actions/workflows/ci.yml)

Copy each macOS screenshot onto the clipboard so ⌘V pastes the image.

Menu extra for macOS 14+. It lives on the **right** of the menu bar and does not show a Dock icon.

| | |
|---|---|
| Product | `PasteShot` |
| Bundle ID | `engineer.badry.pasteshot` |
| Status item | SF Symbol `doc.on.clipboard` (title: `Paste Shot`, `Copied`, or `Off`) |
| Panel | opaque ~220×108 pt, On/Off switch |

## Features

- Watches the system screenshot folder (`com.apple.screencapture` `location`, else Desktop). Does not capture the screen.
- Copies a new screenshot as PNG onto `NSPasteboard` for ⌘V.
- Leaves the screenshot file on disk.
- Ignores non-screenshot PNGs (and other files) in that folder.
- Allowed types: png, jpg, jpeg, heic, tif, tiff, pdf.
- Panel is an On/Off switch.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later (Xcode or Command Line Tools) only if you build from source

## Install

Homebrew (macOS 14+):

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew trust BadryansahBangsawan/mac-menu-apps
brew install --cask paste-shot
```

`brew trust` is required on Homebrew 6 or `brew install --cask` refuses the tap.

Opens as a menu extra (no Dock icon). The cask is ad-hoc signed. If Gatekeeper blocks it or says it is damaged:

```bash
xattr -cr /Applications/PasteShot.app
open /Applications/PasteShot.app
```

If still blocked: System Settings → Privacy & Security → Open Anyway.

Build from source:

```bash
git clone https://github.com/BadryansahBangsawan/paste-shot.git
cd paste-shot
bash package-app.sh
ditto dist/PasteShot.app /Applications/PasteShot.app
xattr -cr /Applications/PasteShot.app
open /Applications/PasteShot.app
```

Do not run `dist/PasteShot.app` while `/Applications/PasteShot.app` is running (same bundle ID).

Enable **Open at Login** from Settings if you want it after reboot.

## How to open

This is an `LSUIElement` extra. Proof it is running is the **clipboard** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is a small opaque On/Off switch, not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking the app in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

## Usage

1. Click the extra. The panel is an **On / Off** switch.
2. **On** (default): ⌘⇧3 or ⌘⇧4 (file save, not Control) copies the screenshot PNG for ⌘V. The file stays on disk.
3. **Off**: new screenshots are not copied.
4. **Settings** at the bottom: Open at Login, Quit.

A PNG dropped into the folder that is not a screenshot is ignored.

## Permissions

No Screen Recording permission. No Accessibility. The app only watches the folder the Screenshot UI already wrote.

## Data

| What | Where |
|---|---|
| On/Off | `UserDefaults` `engineer.badry.pasteshot.enabled` |
| Screenshot files | The system screenshot folder (unchanged) |
| Open at Login | `SMAppService.mainApp` |

The app does not store a copy of screenshots. It does not crash if the folder is missing; the panel shows a red **Screenshot folder missing.**

## Privacy

Screenshot bytes go to `NSPasteboard.general` on this Mac. Nothing is uploaded.

## Uninstall

```bash
brew uninstall --cask paste-shot
```

Or delete `/Applications/PasteShot.app`. Turn off Open at Login in Settings first if you enabled it.

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **clipboard** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x PasteShot` then `open /Applications/PasteShot.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/PasteShot.app`. `spctl --assess` is `rejected` even when it runs. |
| **Screenshot folder missing.** | Create the folder in Screenshot settings, or restore Desktop. |
| ⌘⇧4 did nothing | Switch **On**. Use file save, not Control (clipboard-only). Filename should start with `Screenshot `, `Screen Shot `, or `Tangkapan Layar `, or Spotlight `kMDItemIsScreenCapture`. |
| Random PNG in the folder was not copied | Intended. Only screenshots are copied. |
| ~10px empty strip under the bar | Reinstall from this repo (compact panel, not a collapsed extra). |

## Development

```bash
swift build
swift build -c release --product PasteShot
bash package-app.sh
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. Never commit `dist/`.

## License

[MIT](LICENSE)
