import Foundation
import Combine

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [StickyNote] = []
    @Published private(set) var errorMessage: String?
    private let storage: NoteStorage
    private var saveTask: Task<Void, Never>?
    private var loadFailed = false

    init(storage: NoteStorage? = nil) {
        let storage = storage ?? NoteStorage()
        self.storage = storage
        do {
            if let saved = try storage.load() {
                notes = saved
            } else {
                notes = [StickyNote()]
                flush()
            }
        } catch {
            loadFailed = true
            errorMessage = "Could not load notes at \(storage.url.path). The file has been kept intact. Quit the app and repair or move the file before reopening. \(error.localizedDescription)"
        }
    }

    func note(_ id: UUID) -> StickyNote? { notes.first { $0.id == id } }

    @discardableResult func createNote() -> StickyNote {
        let note = StickyNote()
        notes.append(note)
        scheduleSave()
        return note
    }

    func update(_ id: UUID, _ change: (inout StickyNote) -> Void) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        change(&notes[index])
        scheduleSave()
    }

    func delete(_ id: UUID) {
        notes.removeAll { $0.id == id }
        scheduleSave()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            self?.flush()
        }
    }

    func save() throws {
        guard !loadFailed else { throw CocoaError(.fileReadCorruptFile) }
        try storage.save(notes)
        errorMessage = nil
    }

    func flush() {
        saveTask?.cancel()
        do { try save() } catch {
            if !loadFailed {
                errorMessage = "Could not save notes. Your changes remain in memory; check disk space and permissions, then use Notes → Retry Save. \(error.localizedDescription)"
            }
        }
    }
}
