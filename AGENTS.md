# DesktopStickyNotes conventions

- Native macOS 14+ app; Swift, SwiftUI, AppKit. No external dependencies.
- Open `DesktopStickyNotes.xcodeproj` at the repository root. App sources and assets live in `DesktopStickyNotes/`; checks live in `Tests/`.
- `StickyNote` is the Codable value model. Its stored title is editable; `displayTitle` supplies the shared fallback label. Deadlines are required and default to today at 5 PM in the local calendar. Decode missing/null legacy deadlines with that default and persist `deadlineNeedsReview` until an explicit deadline edit/confirmation; preserve existing deadlines. Missing titles decode as empty and optional priority as nil. No reminder service. `NoteStore` owns mutations and debounced autosave on the main actor. `NoteStorage` reads/writes atomic local JSON. `WindowManager` owns NSWindow lifecycle, levels and frames, the single management window and calendar window. `NoteView` owns note presentation; `NotesLibraryView` owns the management list; `NotesCalendarView` owns the month grid and selected-day agenda. `DeadlineButton`/`DeadlineEditor` share date-entry behavior across notes and calendar rows. `NoteCalendar` owns local-calendar day arithmetic/grouping; avoid fixed 24-hour date offsets.
- Closing a note hides it; deletion requires confirmation. Never overwrite unreadable storage. Keep empty libraries empty after first launch.
- Persist NSWindow frames in AppKit screen coordinates; constrain restored frames to NSScreen.visibleFrame. Pin uses `.floating`, unpin `.normal`.
- Use system controls, accessible labels, plain text and the five pastel colors recorded in DESIGN.md. Keep changes focused and avoid speculative abstractions.
- `PriorityLabel` shares priority icons/colors across notes, menus, management rows and calendar. Day markers aggregate each priority present (High first, including None); keep text/accessibility labels so color is not the only cue. Preserve chronological agenda ordering and independent note background colors.

## Commands

If xcode-select points to CommandLineTools, prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project DesktopStickyNotes.xcodeproj -scheme DesktopStickyNotes -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/DesktopStickyNotes-build CODE_SIGNING_ALLOWED=NO build
./scripts/test.sh
./scripts/package.sh
./scripts/package.sh --install
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift scripts/generate-icon.swift
```

Packaging creates a locally ad-hoc signed, sandboxed universal Release app and ZIP in `dist/`; `--install` replaces the copy in `~/Applications`. Compile in a temporary folder and archive the verified source to avoid Documents file-provider metadata interfering with signing. Generated `build/` and `dist/` files are ignored. Keep the bundle identifier stable so packaged and Xcode builds share saved notes. Public distribution requires Developer ID signing and notarization separately.

Tests use a standalone Swift executable and temporary storage; they never touch real notes. There is no XCTest target. Do not claim GUI verification without exercising the running app.
