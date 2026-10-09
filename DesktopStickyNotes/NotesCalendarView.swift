import SwiftUI

struct NotesCalendarView: View {
    @ObservedObject var store: NoteStore
    let manager: WindowManager
    @State private var selectedDay = Date()
    @State private var month = Date()
    @FocusState private var calendarFocused: Bool
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Calendar").font(.system(size: 20, weight: .semibold))
                    HStack(spacing: 10) {
                        PriorityLabel(priority: .high)
                        PriorityLabel(priority: .medium)
                        PriorityLabel(priority: .low)
                        PriorityLabel(priority: nil)
                    }
                    .font(.system(size: 10, weight: .medium))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Priority key: High, Medium, Low, None")
                }
                Spacer()
                Button("Manage Notes") { manager.showLibrary() }
                Button { manager.newNote(deadline: StickyNote.defaultDeadline(on: selectedDay)) } label: {
                    Label("New Note", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .help("Create a note due on the selected day at 5 PM")
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            Divider()
            VStack(spacing: 10) {
                HStack {
                    Text(month, format: .dateTime.month(.wide).year()).font(.title3.weight(.semibold))
                    Spacer()
                    Button("Today") { selectedDay = Date(); month = selectedDay; calendarFocused = true }
                    Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Previous month").help("Previous month")
                    Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                        .accessibilityLabel("Next month").help("Next month")
                }
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(calendar.shortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + index) % 7])
                            .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(NoteCalendar.days(in: month), id: \.self) { day in dayCell(day) }
                }
                .focusable().focused($calendarFocused).focusEffectDisabled()
                .onMoveCommand { direction in
                    let offset: Int
                    switch direction {
                    case .left: offset = -1
                    case .right: offset = 1
                    case .up: offset = -7
                    case .down: offset = 7
                    @unknown default: return
                    }
                    if let day = calendar.date(byAdding: .day, value: offset, to: selectedDay) {
                        selectedDay = day
                        month = day
                    }
                }
            }
            .padding(20)
            Divider()
            HStack {
                Text(selectedDay, format: .dateTime.weekday(.wide).month(.abbreviated).day().year())
                    .font(.headline)
                Spacer()
                let count = dayNotes.count
                Text("\(count) \(count == 1 ? "note" : "notes")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            if dayNotes.isEmpty {
                VStack(spacing: 6) {
                    Text("Nothing due on this day").font(.headline)
                    Text("Choose another day or create a note here.").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(dayNotes) { note in
                    CalendarNoteRow(note: note, store: store, manager: manager) { deadline in
                        selectedDay = deadline
                        month = deadline
                    }
                }
                .listStyle(.inset)
            }
            if let error = store.errorMessage {
                Divider()
                HStack {
                    Text(error).font(.caption).textSelection(.enabled)
                    Button("Retry Save") { store.flush() }
                }.padding(12)
            }
        }
        .frame(minWidth: 600, minHeight: 590)
    }

    private var dayNotes: [StickyNote] {
        NoteCalendar.notes(on: selectedDay, in: store.notes)
    }

    private func changeMonth(_ offset: Int) {
        if let day = calendar.date(byAdding: .month, value: offset, to: selectedDay) {
            selectedDay = day
            month = day
            calendarFocused = true
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let notes = NoteCalendar.notes(on: day, in: store.notes)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isInMonth = calendar.isDate(day, equalTo: month, toGranularity: .month)
        let priorities = NoteCalendar.presentPriorities(in: notes)
        let summary = priorities.map { level in
            "\(notes.filter { $0.priority == level }.count) \(level?.name.lowercased() ?? "unassigned")"
        }.joined(separator: ", ")
        return Button {
            selectedDay = day
            month = day
            calendarFocused = true
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 13, weight: calendar.isDateInToday(day) ? .bold : .medium))
                    .foregroundStyle(isInMonth ? Color.primary : Color.secondary)
                    .frame(width: 24, height: 20)
                    .background(calendar.isDateInToday(day) ? Color.accentColor.opacity(0.16) : .clear, in: Circle())
                HStack(spacing: 3) {
                    ForEach(Array(priorities.enumerated()), id: \.offset) { _, priority in
                        PriorityLabel(priority: priority).labelStyle(.iconOnly)
                            .font(.system(size: 9, weight: .semibold))
                    }
                }
                .frame(height: 10).accessibilityHidden(true)
                Text(notes.isEmpty ? " " : "\(notes.count) \(notes.count == 1 ? "note" : "notes")")
                    .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(isSelected ? Color.accentColor.opacity(0.09) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
            .overlay { RoundedRectangle(cornerRadius: 7).strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.06), lineWidth: isSelected && calendarFocused ? 2 : 1) }
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .help(notes.isEmpty ? "No notes due" : "Priorities: " + summary)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted) + ", \(notes.count) \(notes.count == 1 ? "note" : "notes")" + (summary.isEmpty ? "" : ", priorities: " + summary))
        .accessibilityValue(isSelected ? "Selected" : "")
    }
}

private struct CalendarNoteRow: View {
    let note: StickyNote
    @ObservedObject var store: NoteStore
    let manager: WindowManager
    let onDeadlineChange: (Date) -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill(note.color.swiftUIColor).frame(width: 20, height: 28)
                .accessibilityLabel("\(note.color.name) note")
            Button { manager.restore(note.id) } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.displayTitle).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    Text(note.content.isEmpty ? "Empty note" : note.content.replacingOccurrences(of: "\n", with: " "))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    HStack(spacing: 8) {
                        PriorityLabel(priority: note.priority)
                        if !note.isVisible { Text("Hidden") }
                        if note.deadlineNeedsReview { Text("Review deadline") }
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.plain).help("Open Note")
            DeadlineButton(id: note.id, store: store, onChange: onDeadlineChange).font(.system(size: 12, weight: .medium))
                .frame(width: 135, alignment: .leading)
            Button("Open") { manager.restore(note.id) }
                .accessibilityLabel("Open \(note.displayTitle)")
        }
        .padding(.vertical, 6)
    }
}
