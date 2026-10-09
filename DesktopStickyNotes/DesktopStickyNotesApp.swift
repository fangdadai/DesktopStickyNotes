import AppKit
import SwiftUI

@main
struct DesktopStickyNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings { Text("Notes save automatically on this Mac.").padding() }
            .commands {
                CommandGroup(replacing: .newItem) {
                    Button("New Note") { delegate.manager.newNote() }.keyboardShortcut("n")
                }
                NoteCommands(store: delegate.store, manager: delegate.manager)
            }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = NoteStore()
    lazy var manager = WindowManager(store: store)

    func applicationDidFinishLaunching(_ notification: Notification) {
        manager.restoreAtStartup()
        manager.showLibrary()
        if let error = store.errorMessage {
            let alert = NSAlert()
            alert.messageText = "Notes could not be loaded"
            alert.informativeText = error
            alert.runModal()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        manager.showLibrary()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        store.flush()
        guard let error = store.errorMessage else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Notes could not be saved"
        alert.informativeText = error
        alert.addButton(withTitle: "Keep Open")
        alert.addButton(withTitle: "Quit Anyway")
        return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
    }
}

struct NoteCommands: Commands {
    @ObservedObject var store: NoteStore
    let manager: WindowManager

    var body: some Commands {
        CommandMenu("Notes") {
            Button("Manage Notes") { manager.showLibrary() }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            Divider()
            Button("Show All Notes") {
                for note in store.notes { manager.restore(note.id) }
            }.disabled(store.notes.isEmpty)
            Button("Hide All Notes") {
                for note in store.notes { manager.hide(note.id) }
            }.disabled(store.notes.isEmpty)
            Divider()
            ForEach(store.notes) { note in
                Button((note.isVisible ? "" : "Show: ") + note.displayTitle) { manager.restore(note.id) }
            }
            if store.notes.isEmpty { Text("No Notes — use ⌘N to create one") }
            Divider()
            Button("Retry Save") { store.flush() }.disabled(store.errorMessage == nil)
        }
    }
}
