import AppKit

@main
struct CoreTests {
    @MainActor static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = NoteStorage(url: directory.appendingPathComponent("notes.json"))
        let store = NoteStore(storage: storage)
        assert(store.notes.count == 1 && store.notes[0].color == .yellow)
        let initialJSON = try JSONSerialization.jsonObject(with: Data(contentsOf: storage.url)) as! [[String: Any]]
        assert(initialJSON[0]["deadline"] != nil, "Every newly created note must save a deadline")
        assert(store.notes[0].priority == nil)
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
        assert(Calendar.current.isDateInToday(second.deadline))
        assert(Calendar.current.component(.hour, from: second.deadline) == 17)
        assert(!second.deadlineNeedsReview)
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
        titleOnly[1]["deadline"] = NSNull()
        try JSONSerialization.data(withJSONObject: titleOnly).write(to: titleOnlyStorage.url)
        let titleOnlyStore = NoteStore(storage: titleOnlyStorage)
        assert(titleOnlyStore.errorMessage == nil)
        assert(titleOnlyStore.note(first)?.title == "Project ideas 📝")
        assert(titleOnlyStore.notes.allSatisfy { $0.deadlineNeedsReview && Calendar.current.isDateInToday($0.deadline) })
        assert(titleOnlyStore.note(first)?.priority == nil)
        try titleOnlyStore.save()
        assert(NoteStore(storage: titleOnlyStorage).notes == titleOnlyStore.notes, "Migrated deadlines and review flags must survive relaunch")
        titleOnlyStore.setDeadline(first, to: titleOnlyStore.notes[0].deadline)
        assert(titleOnlyStore.note(first)?.deadlineNeedsReview == false, "Confirming a deadline clears its review flag")
        let changedDeadline = Date(timeIntervalSince1970: 1_900_000_000)
        restored.setDeadline(first, to: changedDeadline)
        restored.update(first) { $0.priority = nil }
        try restored.save()
        let cleared = NoteStore(storage: storage)
        assert(cleared.note(first)?.deadline == changedDeadline && cleared.note(first)?.priority == nil, "Deadline edits and cleared priority must persist")
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
        testCalendar()
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
        print("PASS: required deadlines, legacy migration and review flags, calendar boundaries/DST/day grouping/priority markers, independent notes, autosave, JSON round trip, empty library, screen bounds, corrupt-file protection, duplicate IDs, write errors")
    }

    static func testCalendar() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.firstWeekday = 2
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
        }
        let february = NoteCalendar.days(in: date(2024, 2, 15), calendar: calendar)
        assert(february.count == 42 && february.first == date(2024, 1, 29))
        assert(february.filter { calendar.component(.month, from: $0) == 2 }.count == 29, "Leap day must appear")
        calendar.firstWeekday = 1
        assert(NoteCalendar.days(in: date(2024, 2, 15), calendar: calendar).first == date(2024, 1, 28), "Respect locale week start")
        let december = NoteCalendar.days(in: date(2024, 12, 15), calendar: calendar)
        assert(december.last == date(2025, 1, 11), "Month grids must cross year boundaries")
        let march = NoteCalendar.days(in: date(2024, 3, 10), calendar: calendar)
        for (first, second) in zip(march, march.dropFirst()) {
            assert(calendar.dateComponents([.day], from: first, to: second).day == 1, "DST must not skip or duplicate dates")
        }
        var early = StickyNote(), late = StickyNote(), nextDay = StickyNote()
        early.deadline = date(2024, 3, 10, 8)
        early.isVisible = false
        late.deadline = date(2024, 3, 10, 23, 59)
        nextDay.deadline = date(2024, 3, 11)
        assert(NoteCalendar.notes(on: date(2024, 3, 10), in: [nextDay, late, early], calendar: calendar) == [early, late], "Include hidden notes, exclude next day, sort by time")
        assert(NoteCalendar.notes(on: date(2024, 3, 12), in: [early, late], calendar: calendar).isEmpty)
        early.priority = .low
        late.priority = .high
        var medium = early, unassigned = early
        medium.id = UUID(); medium.priority = .medium
        unassigned.id = UUID(); unassigned.priority = nil
        let crowdedDay = [early, early, early, unassigned, medium, late]
        assert(NoteCalendar.presentPriorities(in: crowdedDay) == [.high, .medium, .low, nil], "Calendar markers must retain high priority on crowded days and distinguish unassigned notes")
        assert(NoteCalendar.presentPriorities(in: []).isEmpty, "Empty days must not show priority markers")
        let changed = NoteCalendar.settingDay(date(2024, 3, 10), of: date(2024, 3, 9, 17, 45), calendar: calendar)
        assert(changed == date(2024, 3, 10, 17, 45), "Date shortcuts must preserve the local time across DST")
        assert(StickyNote.defaultDeadline(on: date(2024, 3, 10), calendar: calendar) == date(2024, 3, 10, 17))
    }
}
