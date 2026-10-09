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

Every note stores a required `deadline: Date`; new notes default to today at 5 PM in the user's local calendar (user-selected policy). Legacy missing/null deadlines receive that default and a persisted `deadlineNeedsReview` flag. The manager identifies notes needing review; choosing a date/time or confirming Done clears the flag. Existing dates and all other note fields remain intact. Priority remains optional (Low, Medium, High), with None to clear it. No reminders or notifications are implied.

`DeadlineButton` and `DeadlineEditor` are the shared deadline entry controls for sticky notes and calendar agenda rows. The footer shows the day plus time on two compact lines, with the complete timestamp in its accessibility label and tooltip. The popover provides a native graphical calendar, a separate native time field, Today/Tomorrow/Next Week shortcuts that preserve the time, and Done. Changes autosave immediately; Escape dismisses without reverting saved changes. OS-owned calendar/time formatting and keyboard behavior are intentional.

StickyNote.minimumSize owns the 260×260 minimum note frame so title, metadata and the scrolling body remain usable when resized or restored. Native date and priority controls retain keyboard operation and accessible labels.

## UI refinement

The writing surface has three clear zones: a compact quick-action strip, title plus uninterrupted scrolling body, and a quiet metadata footer. Deadline editing lives in a native popover; the footer shows both the date and time. Priority is a small flag menu. All overflow menus hide redundant disclosure arrows. Note padding aligns title and body text at 17pt from the edge; placeholder and caret keep the same first-line origin.

The manager opens at 560×500 with a compact Notes header and a prominent New Note action. Native list rows have a 52pt minimum content height plus native row insets, small pastel markers, a two-line text hierarchy, and one metadata row; complete deadlines remain accessible through tooltips and labels. Secondary actions are borderless. Appearance and keyboard behaviors remain native.

## Calendar

Calendar opens from the manager's Calendar button, the Notes menu (⇧⌘C), or a note's actions menu. `WindowManager` reuses one resizable 760×700 window. `NotesCalendarView` provides a locale-aware, six-week month grid with previous/next month and Today controls. Native day buttons expose full dates, note counts and selected state; arrow keys move the selection by a day/week. Priority symbols and counts identify days with notes. Selecting an adjacent-month day navigates to its month.

The selected-day agenda includes hidden notes, sorts by deadline time, and supports opening notes and editing deadlines through the shared editor. Changing a deadline follows that note to its new day so the editor remains usable. New Note creates a note for the selected day at 5 PM. Empty days have a useful explanation. Day arithmetic uses Calendar and preserves local times across daylight-saving transitions; no external calendar service or permission is needed. Native system surfaces and typography match the manager; agenda rows retain the pastel note-color markers.

## Priority cues

`PriorityLabel.swift` owns the shared icon, label and appearance-aware text color; `NotePriority.symbolName` owns the SF Symbol mapping. High uses double exclamation marks (exclamationmark.2) in red, Medium a dash (minus) in amber, Low a down arrow (arrow.down) in blue, and None a neutral dashed circle. Light colors are #A3262E / #805600 / #185A9D; dark colors are #FF8A91 / #F6CF75 / #8ABEFF. Labels distinguish priorities without relying on color. These colors apply to priority cues; note backgrounds still use the user's pastel choice.

The note's priority control and choices, management rows and calendar agenda use the same labeled symbols. Native menu controls retain monochrome icons; management rows and calendar cues use the priority colors. The calendar header includes a compact key. A day cell shows one symbol per priority level present, in High/Medium/Low/None order, plus the total note count. Aggregation never hides high priority behind a marker limit; tooltips and accessibility labels report the number of notes at each level. Priority updates redraw the calendar immediately. Agenda ordering stays chronological. The meaning is urgency, with no automatic escalation or notification.
