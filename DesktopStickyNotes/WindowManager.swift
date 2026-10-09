import AppKit
import SwiftUI
import Combine

@MainActor
final class WindowManager: NSObject, NSWindowDelegate {
    let store: NoteStore
    private var windows: [UUID: NSWindow] = [:]
    private var subscription: AnyCancellable?
    private var libraryWindow: NSWindow?
    private var calendarWindow: NSWindow?

    init(store: NoteStore) {
        self.store = store
        super.init()
        subscription = store.$notes.receive(on: RunLoop.main).sink { [weak self] _ in self?.synchronize() }
    }

    func showLibrary() {
        if libraryWindow == nil {
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 560, height: 500),
                                  styleMask: [.titled, .closable, .resizable, .miniaturizable],
                                  backing: .buffered, defer: false)
            window.title = "DesktopStickyNotes"
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 420, height: 300)
            window.contentView = NSHostingView(rootView: NotesLibraryView(store: store, manager: self))
            window.center()
            libraryWindow = window
        }
        if let window = libraryWindow {
            window.setFrame(StickyNote.constrainedFrame(window.frame, screens: NSScreen.screens.map(\.visibleFrame)), display: true)
            window.deminiaturize(nil)
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func restoreAtStartup() {
        for note in store.notes {
            store.update(note.id) { $0.frame = StickyNote.constrainedFrame($0.frame, screens: NSScreen.screens.map(\.visibleFrame)) }
        }
        synchronize()
    }

    func showCalendar() {
        if calendarWindow == nil {
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 760, height: 700),
                                  styleMask: [.titled, .closable, .resizable, .miniaturizable],
                                  backing: .buffered, defer: false)
            window.title = "Calendar — DesktopStickyNotes"
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 620, height: 620)
            window.contentView = NSHostingView(rootView: NotesCalendarView(store: store, manager: self))
            window.center()
            calendarWindow = window
        }
        calendarWindow?.deminiaturize(nil)
        if let window = calendarWindow {
            window.setFrame(StickyNote.constrainedFrame(window.frame, screens: NSScreen.screens.map(\.visibleFrame)), display: true)
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func synchronize() {
        for id in Array(windows.keys) where store.note(id) == nil {
            windows.removeValue(forKey: id)?.close()
        }
        for note in store.notes {
            if !note.isVisible {
                windows[note.id]?.orderOut(nil)
                continue
            }
            let window = windows[note.id] ?? makeWindow(for: note)
            window.level = note.isPinned ? .floating : .normal
            window.backgroundColor = note.color.nsColor
            window.title = note.displayTitle
            if !window.isVisible { window.orderFront(nil) }
        }
    }

    private func makeWindow(for note: StickyNote) -> NSWindow {
        let window = NSWindow(contentRect: note.frame, styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = StickyNote.minimumSize
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.fullScreenAuxiliary]
        window.delegate = self
        window.contentView = NSHostingView(rootView: NoteView(id: note.id, store: store, manager: self))
        window.setFrame(note.frame, display: false)
        windows[note.id] = window
        return window
    }

    func newNote(deadline: Date? = nil) {
        let note = store.createNote(deadline: deadline)
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let offset = CGFloat((store.notes.count - 1) % 8) * 24
        store.update(note.id) {
            $0.frame = StickyNote.constrainedFrame(CGRect(x: screen.midX - 150 + offset, y: screen.midY - 160 - offset, width: 300, height: 320), screens: [screen])
        }
        restore(note.id)
    }

    func restore(_ id: UUID) {
        store.update(id) {
            $0.isVisible = true
            $0.frame = StickyNote.constrainedFrame($0.frame, screens: NSScreen.screens.map(\.visibleFrame))
        }
        if let note = store.note(id), let window = windows[id] { window.setFrame(note.frame, display: true) }
        synchronize()
        windows[id]?.deminiaturize(nil)
        windows[id]?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide(_ id: UUID) {
        store.update(id) { $0.isVisible = false }
        windows[id]?.orderOut(nil)
        store.flush()
    }

    func confirmDelete(_ id: UUID, fromLibrary: Bool = false) {
        guard let note = store.note(id) else { return }
        let parent = fromLibrary ? libraryWindow : windows[id]
        guard let window = parent, window.attachedSheet == nil else { return }
        let alert = NSAlert()
        alert.messageText = "Delete this note?"
        alert.informativeText = "“\(note.displayTitle)” will be permanently deleted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Delete")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertSecondButtonReturn else { return }
            self?.store.delete(id)
            self?.store.flush()
            self?.synchronize()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let id = windows.first(where: { $0.value === sender })?.key { hide(id) }
        return false
    }

    func windowDidMove(_ notification: Notification) { saveFrame(notification) }
    func windowDidResize(_ notification: Notification) { saveFrame(notification) }

    private func saveFrame(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let id = windows.first(where: { $0.value === window })?.key,
              store.note(id)?.frame != window.frame else { return }
        store.update(id) { $0.frame = window.frame }
    }
}
