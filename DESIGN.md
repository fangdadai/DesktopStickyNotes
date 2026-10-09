# DesktopStickyNotes design

A quiet, native macOS writing tool: independent paper-like notes plus a compact management window, no onboarding. English UI; notes support arbitrary Unicode plain text.

- Runtime palette owner: `NoteColor.nsColor` in `StickyNote.swift`. Yellow #FFF0A8, pink #FFCFD9, blue #C7E3FF, green #D1EDC4, lavender #E3D4FA (rounded RGB values).
- Runtime layout owner: `NoteView.swift`. System 18pt semibold title, 16pt editor, 13pt utility icons, 12pt content padding; dark warm ink on pastels in both OS appearance modes.
- Signature: an uninterrupted pastel writing surface with a subtly shaded actions strip. Native title bar, traffic lights, dragging, shadows and resize affordances remain familiar.
- New Note always creates an independent yellow note. Pin is a labeled two-state control. Colors use a labeled native Picker. Actions share the same names in all menus.
- Close/Hide preserves content. Notes menu restores hidden notes. Delete uses an AppKit confirmation sheet with Cancel first. Errors remain visible; failed saves can be retried and block ordinary quit until acknowledged.
- Window geometry and visibility persist. Restoring fits the current visible displays. Minimum note frame 260×260; large text scrolls. No custom animation or motion.
- Verification: core executable tests and xcodebuild; actual UI checks must be reported separately.

## App icon

A yellow note with a folded lower-right corner and three warm ink strokes sits over pink and blue notes. Soft paper shading and shadows match the app's pastel surfaces; the silhouette stays recognizable at Dock and Finder sizes. `scripts/generate-icon.swift` draws the artwork with AppKit and exports transparent PNGs from 16 to 1024 pixels into the AppIcon asset catalog. No runtime dependency or generated-image service is required.

## Notes management window

`NotesLibraryView.swift` owns the system-styled notes list. It opens at launch and on a Dock reopen, including when all sticky notes are hidden. A persistent New Note button creates and focuses a sticky note. Rows use a small pastel marker, a 14pt semibold title, one-line text preview, compact priority/date metadata, pin status, borderless Show/Hide and an actions menu for opening, pinning, recoloring and confirmed deletion. Empty and save-error states retain a useful action. Native colors support light and dark appearance; no custom dashboard styling or animation.

`WindowManager.showLibrary()` owns a single reusable, resizable window. Closing it preserves the notes and their visibility. Library deletion presents its confirmation sheet on the library, including for hidden notes with no instantiated note window. Manage Notes is also available in each note's actions menu and via ⇧⌘N.

## Note titles and text alignment

Each note has a single-line editable title above its multiline body. Both fields autosave. `StickyNote.title` stores the entered title; `displayTitle` trims it for display and falls back to the first body line or New Note when blank. JSON without a title loads with an empty title, preserving all previous fields. Window names, manager rows, accessibility labels, menus and deletion confirmation share `displayTitle`.

The empty-body placeholder uses the editor's first-line origin (no extra top padding), the same 16pt font, and the native 5pt horizontal line-fragment inset. It ignores pointer events so clicking it focuses the editor.

## Deadlines and priority

Notes optionally store `deadline: Date?` and `priority: NotePriority?` (Low, Medium, High). New and legacy notes default to neither. The note footer has a calendar button and compact priority menu. The calendar button opens a native popover containing a Set a deadline checkbox and date/time field; unchecking it removes the saved deadline. Priority None clears the selection. Both autosave through NoteStore. The manager displays selected priority and local date/time below the body preview. No reminders or notifications are implied by these fields.

StickyNote.minimumSize owns the 260×260 minimum note frame so title, metadata and the scrolling body remain usable when resized or restored. Native date and priority controls retain keyboard operation and accessible labels.

## UI refinement

The writing surface has three clear zones: a compact quick-action strip, title plus uninterrupted scrolling body, and a quiet metadata footer. Deadline editing lives in a native popover; the footer shows a short date and exposes the complete local date/time via tooltip and accessibility. Priority is a small flag menu. All overflow menus hide redundant disclosure arrows. Note padding aligns title and body text at 17pt from the edge; placeholder and caret keep the same first-line origin.

The manager opens at 560×500 with a compact Notes header and a prominent New Note action. Native list rows have a 52pt minimum content height plus native row insets, small pastel markers, a two-line text hierarchy, and one metadata row; complete deadlines remain accessible through tooltips and labels. Secondary actions are borderless. Appearance and keyboard behaviors remain native.
