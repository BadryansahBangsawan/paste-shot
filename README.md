# Paste Shot

[![Build](https://github.com/BadryansahBangsawan/paste-shot/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/paste-shot/actions/workflows/ci.yml)

Copy each macOS screenshot onto the clipboard so ⌘V pastes the image.

Menu extra for macOS 14+. It lives on the **right** of the menu bar and does not show a Dock icon.

| | |
|---|---|
| Product | `PasteShot` |
| Bundle ID | `engineer.badry.pasteshot` |
| Status item | SF Symbol `doc.on.clipboard` (title: `Copied`, then `Paste Shot`) |
| Panel | opaque ~360×420 pt |

## Features

- Watches the system screenshot folder (`com.apple.screencapture` `location`, else Desktop). Does not capture the screen.
- Copies a new screenshot as PNG onto `NSPasteboard` for ⌘V.
- Leaves the screenshot file on disk.
- Ignores non-screenshot PNGs (and other files) in that folder.
- Allowed types: png, jpg, jpeg, heic, tif, tiff, pdf.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later (Xcode or Command Line Tools) only if you build from source

## Install

```bash
git clone https://github.com/BadryansahBangsawan/paste-shot.git
cd paste-shot
bash package-app.sh
ditto dist/PasteShot.app /Applications/PasteShot.app
xattr -cr /Applications/PasteShot.app
open /Applications/PasteShot.app
```

Ad-hoc signed (`codesign -s -`). If Gatekeeper blocks it or says it is damaged, run the `xattr` line. If it is still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/PasteShot.app` while `/Applications/PasteShot.app` is running (same bundle ID).

Enable **Open at Login** from Settings if you want it after reboot.

## How to open

This is an `LSUIElement` extra. Proof it is running is the **clipboard** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque (~360×420), not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking the app in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

## Usage

1. Click the extra. Status shows `Watching` plus the screenshot folder (`~/Desktop` or the `location` preference).
2. Press ⌘⇧3 or ⌘⇧4 (file save, not Control). A `Screenshot *.png` (or `Screen Shot ` / `Tangkapan Layar `) appears in that folder.
3. The menu title flashes **Copied**. ⌘V pastes that PNG.
4. The file stays on disk.
5. **Settings** at the bottom of the panel: Open at Login, Quit.

A PNG dropped into the folder that is not a screenshot is ignored.

## Permissions

No Screen Recording permission. No Accessibility. The app only watches the folder the Screenshot UI already wrote.

## Data

| What | Where |
|---|---|
| Screenshot files | The system screenshot folder (unchanged) |
| Open at Login | `SMAppService.mainApp` |

The app does not store a copy of screenshots. It does not crash if the folder is missing; the panel shows a red **Screenshot folder missing.**

## Privacy

Screenshot bytes go to `NSPasteboard.general` on this Mac. Nothing is uploaded.

## Uninstall

Delete `/Applications/PasteShot.app`. Turn off Open at Login in Settings first if you enabled it.

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **clipboard** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x PasteShot` then `open /Applications/PasteShot.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/PasteShot.app`. `spctl --assess` is `rejected` even when it runs. |
| **Screenshot folder missing.** | Create the folder in Screenshot settings, or restore Desktop. |
| ⌘⇧4 did nothing in the panel | Use file save, not Control (clipboard-only). Filename should start with `Screenshot `, `Screen Shot `, or `Tangkapan Layar `, or Spotlight `kMDItemIsScreenCapture`. |
| Random PNG in the folder was not copied | Intended. Only screenshots are copied. |
| ~10px empty strip under the bar | Reinstall from this repo (panel min height 420). |

## Development

```bash
swift build
swift build -c release --product PasteShot
bash package-app.sh
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. Never commit `dist/`. `FunTheme.swift` is copied verbatim (no shared package).

## License

[MIT](LICENSE)
