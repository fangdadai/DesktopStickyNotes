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

The **DesktopStickyNotes** management window opens at launch. Click **New Note** to create a note, click a row to open it, or use its Show/Hide button and actions menu to pin, recolor or delete it. Click the Dock icon or press **⇧⌘N** to reopen the manager. You can also use **⌘N** or File → New Note. Enter a title above the note body; titles autosave and appear in the manager and menus. Every note has a deadline, defaulting to today at 5 PM. Click the date/time in the footer to pick a day from the calendar, edit the separate time field, or use Today, Tomorrow and Next Week. Changes autosave; Done or Escape closes the editor. Use the priority menu to choose None, Low, Medium or High. High uses red double exclamation marks, Medium an amber dash, Low a blue down arrow, and None a neutral dashed circle. Native note menus use monochrome symbols; the manager and calendar add these priority colors. Note background colors stay independent. Existing deadlines remain unchanged; older notes without deadlines receive today at 5 PM and a Review deadline flag until their deadline is edited or confirmed. Drag the native title bar and resize the edges. The pin button floats a note above normal windows. The actions menu changes color, hides or deletes (with confirmation). Closing a note hides it. Use the **Notes** menu to restore individual notes or show all notes. The app stays running when all notes are hidden.

Notes autosave after 300 ms of inactivity and when hiding or quitting. JSON contains title, text, required deadline, deadline-review flag, optional priority, color, window frame, visibility and pin state. It lives in `Application Support/DesktopStickyNotes/notes.json` within the app's sandbox container (normally `~/Library/Containers/fangda.DesktopStickyNotes/Data/Library/Application Support/DesktopStickyNotes/notes.json`). An unsandboxed development build uses `~/Library/Application Support/DesktopStickyNotes/notes.json`. Unreadable files are preserved and reported.

## Calendar view

Click **Calendar** in the manager, choose Notes → Calendar, or press **⇧⌘C**. The month grid shows the priority levels present on each day and the total note count, with a compact priority key above it. Hover over a day for counts by priority. Select a day to see all notes due then, including hidden notes, sorted by deadline time. Use Open to show a note or click its deadline to reschedule it. The calendar follows the edited note to its new day. Previous/next month, Today, and arrow-key day/week navigation are available. New Note in this window uses the selected day at 5 PM. All dates and times use the Mac's local calendar/time zone; deadlines do not send notifications.

## Build and checks

See [AGENTS.md](AGENTS.md) for the xcodebuild command. Run `./scripts/test.sh` for the standalone core checks. There is no XCTest target or UI test suite.

Verified: Debug and universal Release xcodebuilds and standalone core checks pass. Core checks cover required deadlines, missing/null legacy deadlines and persistent review flags, JSON round trips, autosave, empty libraries, corrupt-file protection, duplicate IDs, write recovery, screen bounds, leap days, locale week starts, year boundaries, hidden-note day grouping, priority aggregation on crowded days, and daylight-saving date arithmetic. GUI smoke checks in a separate sandboxed preview covered the calendar month grid and empty-day state, arrow-key day navigation, creating a note for the selected day, hidden-note display/opening, native date/time editing, Tomorrow/Next Week shortcuts preserving the time, following a rescheduled note in the agenda, Done/Escape dismissal, and deadline persistence after quit/relaunch. The manager and sticky-note layouts were visually inspected. This is focused smoke coverage, not complete GUI or accessibility coverage.

The installed app's calendar launch, final keyboard focus appearance, minimum note width and minimum calendar empty-day layout were also visually checked. Priority smoke checks in the isolated preview covered all four symbols in the manager and calendar key/day markers, native menu choices, live calendar count changes, persistence after relaunch, and the minimum calendar layout. The strict UI static audit reported no findings. Preview smoke data uses a separate app sandbox; it is not bundled or tracked in Git.

Remaining manual verification checklist:
- Management window: empty library, create/open/show/hide, pin/color actions, confirmed deletion of a hidden note, and Dock reopen.
- Create multiple notes; type/paste multiline Unicode text and verify independent editing.
- Drag and resize; select all five colors; verify title-bar and editor appearance.
- Pin/unpin while another app is active; check floating and normal window levels.
- Close/hide, restore through Notes, minimize/restore, and cancel/confirm deletion.
- Quit/relaunch; verify text, color, frame, pin and hidden state. Delete all, relaunch and ensure the library stays empty.
- Change connected displays and restore; verify notes stay inside visible bounds.
- Check keyboard editing, Cmd+N, menu navigation and VoiceOver labels.
