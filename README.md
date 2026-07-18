# iTake

A fully native macOS menu bar utility for screenshots, screen recording, OCR, and uploads, built in Swift.

Capture a region, a window, or the full screen; record your screen (with system audio); pull text out of anything on-screen with OCR; then save it, copy it, or ship it straight to an HTTP endpoint of your choosing. No Dock icon, no third-party frameworks — just `AppKit`/`SwiftUI`, `ScreenCaptureKit`, `AVFoundation`, and `Vision`.

## Features

- **Screenshots** — region, window, or full screen, via the native `screencapture` picker so selection feels exactly like the system tool.
- **Screen recording** — `ScreenCaptureKit`-based, with pause/resume (paused spans are cut out of the final file, not just frozen) and optional system audio.
- **OCR ("Capture Text")** — select a region and get its text recognized (`Vision`) and copied to your clipboard.
- **Configurable uploader** — define one or more HTTP destinations with your own uploader config file (`.itup`, iTake's own format, see below), or just save straight to disk. Upload progress and link-copy confirmations show as small floating overlays in the corner of your screen (not system notifications).
- **Fully customizable global hotkeys**, with conflict detection (offers to swap if you assign a combo that's already taken) and an option to take over macOS's own `⌘⇧3`/`⌘⇧4`/`⌘⇧5` screenshot shortcuts.
- **Menu bar only** — no Dock icon, no main window; everything lives under one menu bar icon and a Preferences window.

## Requirements

- macOS 14 (Sonoma) or later
- To build: Xcode Command Line Tools (`swiftc`, `codesign`). A full Xcode install is _not_ required, since this is a plain Swift Package.

## Installing

Download the latest [Release](https://github.com/SerStars/iTake/releases)
Apple will show an popup saying: "Apple could not verify iTake is free of malware." This only needs fixing once per download:

1. Drag `iTake.app` into `/Applications`.
2. Right-click (or Control-click) it in Finder and choose **Open**, then confirm **Open**
   in the dialog that appears. (Just double-clicking won't offer this option.)

   Alternatively, from Terminal:

   ```sh
   xattr -cr /Applications/iTake.app
   ```

3. The first time you capture or record, macOS will ask for **Screen Recording**
   permission (System Settings -> Privacy & Security -> Screen Recording). Grant it, you
   may need to quit and reopen iTake afterward for it to take effect.

## Building & Running

iTake is a Swift Package, but `swift run` isn't enough, it needs to be a real .app
<br>Use the provided scripts instead:

```sh
# Build + package + launch iTake.app
scripts/run.sh

# Just build + package, without launching
scripts/build_app.sh

# Tail iTake's own log output
scripts/logs.sh
```

## Default Keyboard Shortcuts

All shortcuts are rebindable in **Preferences -> Shortcuts**. Out of the box, iTake uses
its own combinations so it never collides with macOS's defaults:

| Action              | Default |
| ------------------- | ------- |
| Capture Region      | `⌃⌘⇧2`  |
| Capture Full Screen | `⌃⌘⇧3`  |
| Capture Window      | `⌃⌘⇧4`  |
| Capture Text (OCR)  | `⌃⌘⇧5`  |
| Toggle Recording    | `⌃⌘⇧R`  |

There's also a "Use macOS Default Shortcuts" toggle in Preferences that switches
everything to `⌘⇧3`/`⌘⇧4`/`⌘⇧5` and disables the built-in Screenshot app's response to
those keys so iTake takes over cleanly (and can be switched back at any time).

## The Uploader & `.itup` Files

iTake uses its own small, human-readable config format, a `.itup` file is just JSON:

```json
{
  "name": "My Uploader",
  "request": {
    "url": "https://example.com/api/upload",
    "method": "POST",
    "headers": {
      "Authorization": "Bearer YOUR_API_KEY"
    }
  },
  "body": {
    "type": "multipart",
    "fileField": "file",
    "fields": {}
  },
  "response": {
    "linkPath": "url"
  }
}
```

- `request` — where and how the file is sent (`url`, `method`, any extra `headers`).
- `body` — `"multipart"` (with the field name the file is attached under) or `"raw"` for a
  raw-body `PUT`/`POST`, plus any static extra fields to send alongside it.
- `response` — `linkPath` is a dot-path into the JSON response used to find the resulting
  URL (e.g. `"files.0.url"` for a nested/array response).

`.itup` is registered as iTake's own file type, double-clicking one anywhere in Finder
opens iTake and prompts to import it. Any secret header values (API keys, tokens) you enter are stored in the macOS Keychain, never written into the config file itself, so it's safe to export and share an `.itup` without leaking credentials. Import, export, and remove
uploaders from **Preferences -> Uploader**; a couple of example configs can be found in [`examples/`](examples/).

## Where Things Are Saved

| What | Where                                |
| ------------------------------------------- | ------------------------------------------- |
| Screenshots & recordings                    | `~/Pictures/iTake` by default — changeable in **Preferences -> General**                                     |
| Debug log                                   | `~/Library/Logs/iTake/debug.log`                                                                     |
| Preferences & hotkey bindings               | macOS `UserDefaults`, domain `com.SerStars.iTake` (`~/Library/Preferences/com.SerStars.iTake.plist`) |
| Uploader configs (name, URL, headers, etc.) | Same `UserDefaults` domain as above                                                                  |
| Uploader secrets (API keys/tokens)          | macOS Keychain — never written to disk in plain text                                                 |
| Imported/exported `.itup` files             | Wherever you choose in Finder — iTake doesn't manage a copy once imported                            |

## License

[GPL-3.0](/LICENSE)
