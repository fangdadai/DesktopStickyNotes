import SwiftUI

struct NoteView: View {
    let id: UUID
    @ObservedObject var store: NoteStore
    let manager: WindowManager
    @State private var showsDeadline = false
    private let ink = Color(red: 0.20, green: 0.18, blue: 0.15)

    var body: some View {
        if let note = store.note(id) {
            VStack(spacing: 0) {
                // Keep a native title bar for dragging; this strip holds only quick actions.
                HStack(spacing: 8) {
                    Button { manager.newNote() } label: {
                        Image(systemName: "plus").frame(width: 24, height: 24)
                    }
                    .help("New Note (⌘N)").accessibilityLabel("New Note")
                    Spacer()
                    Button { store.update(id) { $0.isPinned.toggle() } } label: {
                        Image(systemName: note.isPinned ? "pin.fill" : "pin").frame(width: 24, height: 24)
                    }
                    .help(note.isPinned ? "Unpin Note" : "Pin Note")
                    .accessibilityLabel(note.isPinned ? "Unpin Note" : "Pin Note")
                    .accessibilityValue(note.isPinned ? "Pinned" : "Unpinned")
                    Menu {
                        Picker("Note Color", selection: Binding(get: { store.note(id)?.color ?? .yellow }, set: { color in store.update(id) { $0.color = color } })) {
                            ForEach(NoteColor.allCases) { color in Text(color.name).tag(color) }
                        }
                        Divider()
                        Button("Manage Notes") { manager.showLibrary() }
                        Button("Hide Note") { manager.hide(id) }
                        Button("Delete Note…", role: .destructive) { manager.confirmDelete(id) }
                    } label: { Image(systemName: "ellipsis").frame(width: 24, height: 24) }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                    .help("Note actions").accessibilityLabel("Note actions")
                }
                .font(.system(size: 13, weight: .medium))
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(ink.opacity(0.035))

                TextField("Title", text: Binding(get: { store.note(id)?.title ?? "" }, set: { title in store.update(id) { $0.title = title } }))
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .semibold))
                    .accessibilityLabel("Note title")
                    .padding(.horizontal, 17).padding(.top, 14)
                ZStack(alignment: .topLeading) {
                    if note.content.isEmpty {
                        Text("Write something…").foregroundStyle(ink.opacity(0.65))
                            .padding(.horizontal, 5)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                    TextEditor(text: Binding(get: { store.note(id)?.content ?? "" }, set: { text in store.update(id) { $0.content = text } }))
                        .scrollContentBackground(.hidden)
                        .accessibilityLabel("Note text")
                }
                .font(.system(size: 16))
                .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 10)

                HStack(spacing: 12) {
                    Button { showsDeadline.toggle() } label: {
                        Label {
                            if let deadline = note.deadline {
                                Text(deadline, format: .dateTime.month(.abbreviated).day())
                            } else {
                                Text("Add deadline")
                            }
                        } icon: { Image(systemName: "calendar") }
                        .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .help(note.deadline?.formatted(date: .abbreviated, time: .shortened) ?? "Add deadline")
                    .accessibilityLabel(note.deadline.map { "Deadline: " + $0.formatted(date: .abbreviated, time: .shortened) } ?? "Add deadline")
                    .popover(isPresented: $showsDeadline, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Deadline").font(.headline)
                            Toggle("Set a deadline", isOn: Binding(get: { store.note(id)?.deadline != nil }, set: { enabled in
                                store.update(id) { $0.deadline = enabled ? Date() : nil }
                            }))
                            .toggleStyle(.checkbox)
                            if store.note(id)?.deadline != nil {
                                DatePicker("Deadline date and time", selection: Binding(get: { store.note(id)?.deadline ?? Date() }, set: { value in
                                    store.update(id) { $0.deadline = value }
                                }), displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.field).labelsHidden()
                                .accessibilityLabel("Deadline date and time")
                            }
                        }
                        .padding(16).frame(width: 260, alignment: .leading)
                    }
                    Spacer(minLength: 0)
                    Menu {
                        Picker("Priority", selection: Binding<NotePriority?>(get: { store.note(id)?.priority }, set: { priority in
                            store.update(id) { $0.priority = priority }
                        })) {
                            Text("None").tag(Optional<NotePriority>.none)
                            ForEach(NotePriority.allCases) { priority in
                                Text(priority.name).tag(Optional(priority))
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Label(note.priority?.name ?? "Priority", systemImage: note.priority == nil ? "flag" : "flag.fill")
                    }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                    .help("Set priority")
                    .accessibilityLabel("Priority: \(note.priority?.name ?? "None")")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ink.opacity(0.8))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .overlay(alignment: .top) { ink.opacity(0.08).frame(height: 1) }
                if let error = store.errorMessage {
                    Text(error).font(.caption).padding(8).textSelection(.enabled)
                }
            }
            .foregroundStyle(ink)
            .background(note.color.swiftUIColor)
            .preferredColorScheme(.light)
        }
    }
}
