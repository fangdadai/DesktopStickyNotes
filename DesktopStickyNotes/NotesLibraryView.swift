import SwiftUI

struct NotesLibraryView: View {
    @ObservedObject var store: NoteStore
    let manager: WindowManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Notes").font(.system(size: 20, weight: .semibold))
                    Text("\(store.notes.count) \(store.notes.count == 1 ? "note" : "notes") · \(store.notes.filter(\.isVisible).count) visible")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { manager.showCalendar() } label: { Label("Calendar", systemImage: "calendar") }
                    .help("Calendar (⇧⌘C)")
                Button { manager.newNote() } label: { Label("New Note", systemImage: "plus") }
                    .buttonStyle(.borderedProminent).controlSize(.regular)
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            Divider()
            let reviewCount = store.notes.filter(\.deadlineNeedsReview).count
            if reviewCount > 0 {
                Text("\(reviewCount) \(reviewCount == 1 ? "note needs" : "notes need") a deadline review. Open a note to choose its deadline.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 20).padding(.vertical, 10)
            }
            if store.notes.isEmpty {
                ContentUnavailableView {
                    Label("No notes yet", systemImage: "note.text")
                } description: {
                    Text("Create a note to jot down an idea or a reminder.")
                } actions: {
                    Button("New Note") { manager.newNote() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(store.notes) { note in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(note.color.swiftUIColor)
                            .frame(width: 20, height: 26)
                            .accessibilityLabel("\(note.color.name) note")
                        Button { manager.restore(note.id) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.displayTitle).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                                Text(note.content.isEmpty ? "Empty note" : note.content.replacingOccurrences(of: "\n", with: " "))
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                HStack(spacing: 10) {
                                    PriorityLabel(priority: note.priority).fixedSize()
                                    Label {
                                        Text(note.deadline, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    } icon: { Image(systemName: "calendar") }
                                    .lineLimit(1)
                                    .help(note.deadline.formatted(date: .abbreviated, time: .shortened))
                                    .accessibilityLabel("Deadline: " + note.deadline.formatted(date: .abbreviated, time: .shortened))
                                    if note.deadlineNeedsReview { Text("Review") }
                                }
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Open Note")
                        if note.isPinned {
                            Image(systemName: "pin.fill").foregroundStyle(.secondary)
                                .accessibilityLabel("Pinned")
                        }
                        Button(note.isVisible ? "Hide" : "Show") {
                            if note.isVisible { manager.hide(note.id) } else { manager.restore(note.id) }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .buttonStyle(.borderless).controlSize(.small)
                        .frame(width: 44)
                        .accessibilityLabel(note.isVisible ? "Hide \(note.displayTitle)" : "Show \(note.displayTitle)")
                        Menu {
                            Button("Open Note") { manager.restore(note.id) }
                            Button(note.isPinned ? "Unpin Note" : "Pin Note") {
                                store.update(note.id) { $0.isPinned.toggle() }
                            }
                            Picker("Note Color", selection: Binding(get: { store.note(note.id)?.color ?? .yellow }, set: { color in store.update(note.id) { $0.color = color } })) {
                                ForEach(NoteColor.allCases) { color in Text(color.name).tag(color) }
                            }
                            Divider()
                            Button("Delete Note…", role: .destructive) {
                                manager.confirmDelete(note.id, fromLibrary: true)
                            }
                        } label: { Image(systemName: "ellipsis").frame(width: 24, height: 24) }
                        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                        .accessibilityLabel("Actions for \(note.displayTitle)")
                    }
                    .padding(.vertical, 6).frame(minHeight: 52)
                }
                .listStyle(.inset)
            }
            if let error = store.errorMessage {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text(error).font(.caption).textSelection(.enabled)
                    Button("Retry Save") { store.flush() }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 420, minHeight: 280)
    }
}
