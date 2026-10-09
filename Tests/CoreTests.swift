import AppKit

@main
struct CoreTests {
    @MainActor static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = NoteStorage(url: directory.appendingPathComponent("notes.json"))
        let store = NoteStore(storage: storage)
        assert(store.notes.count == 1 && store.notes[0].color == .yellow)
        assert(store.notes[0].deadline == nil && store.notes[0].priority == nil)
        let first = store.notes[0].id
        store.update(first) {
            $0.deadline = Date(timeIntervalSince1970: 1_800_000_000)
            $0.priority = .high
            $0.title = "Project ideas 📝"
            $0.content = "First line\n日本語 📝\nLast line"
            $0.color = .lavender
            $0.isPinned = true
            $0.isVisible = false
            $0.frame = CGRect(x: -5000, y: 8000, width: 420, height: 360)
        }
        let second = store.createNote()
        assert(second.id != first)
        try await Task.sleep(for: .milliseconds(650))
        let autosaved = try storage.load()
        assert(autosaved == store.notes, "Edits must autosave without an explicit save call")
        try store.save()
        let restored = NoteStore(storage: storage)
        assert(restored.notes == store.notes, "JSON must preserve every note field")
        assert(restored.note(first)?.displayTitle == "Project ideas 📝", "Explicit titles must override the body preview")
        assert(restored.note(first)?.deadline == Date(timeIntervalSince1970: 1_800_000_000))
        assert(restored.note(first)?.priority == .high)
        let titleOnlyStorage = NoteStorage(url: directory.appendingPathComponent("title-only.json"))
        var titleOnly = try JSONSerialization.jsonObject(with: Data(contentsOf: storage.url)) as! [[String: Any]]
        for index in titleOnly.indices {
            titleOnly[index].removeValue(forKey: "deadline")
            titleOnly[index].removeValue(forKey: "priority")
        }
        try JSONSerialization.data(withJSONObject: titleOnly).write(to: titleOnlyStorage.url)
        let titleOnlyStore = NoteStore(storage: titleOnlyStorage)
        assert(titleOnlyStore.errorMessage == nil)
        assert(titleOnlyStore.note(first)?.title == "Project ideas 📝")
        assert(titleOnlyStore.note(first)?.deadline == nil && titleOnlyStore.note(first)?.priority == nil)
        restored.update(first) { $0.deadline = nil; $0.priority = nil }
        try restored.save()
        let cleared = NoteStore(storage: storage)
        assert(cleared.note(first)?.deadline == nil && cleared.note(first)?.priority == nil, "Clearing optional metadata must persist")
        let legacyStorage = NoteStorage(url: directory.appendingPathComponent("legacy.json"))
        var legacy = try JSONSerialization.jsonObject(with: Data(contentsOf: storage.url)) as! [[String: Any]]
        for index in legacy.indices {
            for key in ["title", "deadline", "priority"] { legacy[index].removeValue(forKey: key) }
        }
        try JSONSerialization.data(withJSONObject: legacy).write(to: legacyStorage.url)
        let legacyStore = NoteStore(storage: legacyStorage)
        assert(legacyStore.errorMessage == nil, "Existing JSON without title must still load")
        assert(legacyStore.note(first)?.title == "")
        assert(legacyStore.note(first)?.displayTitle == "First line")
        legacyStore.update(first) { $0.title = "   " }
        assert(legacyStore.note(first)?.displayTitle == "First line", "Blank titles must fall back to the body")
        assert(legacyStore.note(second.id)?.displayTitle == "New Note")
        restored.delete(first)
        restored.delete(second.id)
        try restored.save()
        assert(NoteStore(storage: storage).notes.isEmpty, "Deleting all notes must not reset first launch")
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let clamped = StickyNote.constrainedFrame(CGRect(x: -5000, y: 8000, width: 3000, height: 2000), screens: [screen])
        assert(screen.contains(clamped), "Restored frame must fit the visible display")
        let leftScreen = CGRect(x: -1200, y: 0, width: 1200, height: 800)
        let onLeft = CGRect(x: -1000, y: 100, width: 300, height: 300)
        assert(StickyNote.constrainedFrame(onLeft, screens: [leftScreen, screen]) == onLeft)
        try Data("broken JSON".utf8).write(to: storage.url)
        let corrupt = NoteStore(storage: storage)
        assert(corrupt.errorMessage != nil)
        do {
            try corrupt.save()
            assertionFailure("Corrupt storage must not be overwritten")
        } catch {}
        let preserved = try String(contentsOf: storage.url, encoding: .utf8)
        assert(preserved == "broken JSON")
        let duplicate = [second, second]
        try storage.save(duplicate)
        do {
            _ = try storage.load()
            assertionFailure("Duplicate note IDs must be rejected")
        } catch {}
        let blockedURL = directory.appendingPathComponent("blocked")
        try Data().write(to: blockedURL)
        let blocked = NoteStore(storage: NoteStorage(url: blockedURL.appendingPathComponent("notes.json")))
        blocked.flush()
        assert(blocked.errorMessage != nil, "Write failures must be surfaced")
        try FileManager.default.removeItem(at: blockedURL)
        blocked.flush()
        assert(blocked.errorMessage == nil, "Retry Save must recover after a write failure")
        print("PASS: first launch, independent notes, debounced autosave, title/deadline/priority persistence and legacy migration, JSON round trip, empty library, screen bounds, corrupt-file protection, duplicate IDs, write errors")
    }
}
