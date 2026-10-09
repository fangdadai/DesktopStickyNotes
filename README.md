# DesktopStickyNotes

A lightweight macOS 14+ app with independent pastel sticky notes. Built with SwiftUI and AppKit, without dependencies.

## Launch without Xcode

Double-click `dist/DesktopStickyNotes.app` in Finder. You can drag it to Applications and keep it in your Dock. Xcode is only needed to build the app, not to run it.

The current build is also installed at `~/Applications/DesktopStickyNotes.app`. Double-click that copy for everyday use.

The app icon is a yellow sticky note with a folded corner over pink and blue notes. Its PNGs live in `DesktopStickyNotes/Assets.xcassets/AppIcon.appiconset`; regenerate them with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift scripts/generate-icon.swift`, then repackage. The installed icon was visually checked in the running app's native About window.

To package the latest source, run:

```sh
./scripts/package.sh
# Build and replace the copy in your personal Applications folder:
./scripts/package.sh --install
```

This builds a Release app for Apple silicon and Intel Macs, plus `dist/DesktopStickyNotes.zip`. The app is locally ad-hoc signed and keeps the same sandbox and bundle identifier as Xcode builds, so it uses the same saved notes. This package is for local use; distribution to other people requires [Developer ID signing and notarization](https://developer.apple.com/macos/distribution/). Build output is recorded in `build/package.log`.

Packaging and core checks passed. Both the packaged and installed apps were launched directly without Xcode; the management window displayed the existing sandboxed note. The installed app's signature and sandbox entitlement were verified. This is a launch smoke check, not full GUI coverage; the Intel build has not been run on Intel hardware.

## Launch in Xcode

1. Open `DesktopStickyNotes.xcodeproj` from this repository's root.
2. Select the **DesktopStickyNotes** scheme and **My Mac** destination.
3. Press **⌘R**. If signing is requested, choose your development team under Signing & Capabilities.

The **DesktopStickyNotes** management window opens at launch. Click **New Note** to create a note, click a row to open it, or use its Show/Hide button and actions menu to pin, recolor or delete it. Click the Dock icon or press **⇧⌘N** to reopen the manager. You can also use **⌘N** or File → New Note. Enter a title above the note body; titles autosave and appear in the manager and menus. Click Add deadline (or the calendar/date in the note footer) to open deadline editing, and use the flag menu to choose None, Low, Medium or High. Both autosave and appear in the manager. Existing notes without these fields remain compatible. Drag the native title bar and resize the edges. The pin button floats a note above normal windows. The actions menu changes color, hides or deletes (with confirmation). Closing a note hides it. Use the **Notes** menu to restore individual notes or show all notes. The app stays running when all notes are hidden.

Notes autosave after 300 ms of inactivity and when hiding or quitting. JSON contains title, text, optional deadline and priority, color, window frame, visibility and pin state. It lives in `Application Support/DesktopStickyNotes/notes.json` within the app's sandbox container (normally `~/Library/Containers/fangda.DesktopStickyNotes/Data/Library/Application Support/DesktopStickyNotes/notes.json`). An unsandboxed development build uses `~/Library/Application Support/DesktopStickyNotes/notes.json`. Unreadable files are preserved and reported.

## Build and checks

See [AGENTS.md](AGENTS.md) for the xcodebuild command. Run `./scripts/test.sh` for the standalone core checks. There is no XCTest target or UI test suite.

Verified: Debug xcodebuild and core checks pass. GUI smoke checks confirmed multiline editing, Cmd+N, independent contents, pin control state and JSON autosave. The initial pastel window was visually inspected. The management window was also visually inspected in dark appearance and smoke-tested for New Note, hide, Show, and hidden-note delete confirmation/cancel. Title/body editing, title updates in the manager, and empty-body placeholder/caret alignment were also verified in the running app. Core checks cover title persistence and older JSON without titles. Deadline entry, High priority selection, manager metadata, and the 260×260 minimum note layout were also checked in the running app. Core checks cover optional metadata persistence, clearing and legacy JSON. The refined manager and note layouts were visually inspected; deadline popover opening/Escape dismissal, priority clearing/reselection, and the minimum note width were checked. This does not establish complete GUI coverage.

Remaining manual verification checklist:
- Management window: empty library, create/open/show/hide, pin/color actions, confirmed deletion of a hidden note, and Dock reopen.
- Create multiple notes; type/paste multiline Unicode text and verify independent editing.
- Drag and resize; select all five colors; verify title-bar and editor appearance.
- Pin/unpin while another app is active; check floating and normal window levels.
- Close/hide, restore through Notes, minimize/restore, and cancel/confirm deletion.
- Quit/relaunch; verify text, color, frame, pin and hidden state. Delete all, relaunch and ensure the library stays empty.
- Change connected displays and restore; verify notes stay inside visible bounds.
- Check keyboard editing, Cmd+N, menu navigation and VoiceOver labels.
