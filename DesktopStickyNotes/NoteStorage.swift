import Foundation

struct NoteStorage {
    let url: URL

    init(url: URL? = nil) {
        self.url = url ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DesktopStickyNotes", isDirectory: true).appendingPathComponent("notes.json")
    }

    func load() throws -> [StickyNote]? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let notes = try JSONDecoder().decode([StickyNote].self, from: Data(contentsOf: url))
        guard Set(notes.map(\.id)).count == notes.count else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return notes
    }

    func save(_ notes: [StickyNote]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(notes).write(to: url, options: .atomic)
    }
}
