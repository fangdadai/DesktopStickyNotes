import SwiftUI

struct DeadlineButton: View {
    let id: UUID
    @ObservedObject var store: NoteStore
    var onChange: (Date) -> Void = { _ in }
    @State private var showsEditor = false

    var body: some View {
        if let note = store.note(id) {
            Button { showsEditor.toggle() } label: {
                HStack(spacing: 7) {
                    Image(systemName: note.deadlineNeedsReview ? "exclamationmark.calendar" : "calendar")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.deadlineNeedsReview ? "Review deadline" : dayLabel(note.deadline))
                            .lineLimit(1)
                        Text(note.deadline, format: .dateTime.hour().minute())
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Change deadline: " + note.deadline.formatted(date: .abbreviated, time: .shortened))
            .accessibilityLabel("Change deadline: " + note.deadline.formatted(date: .abbreviated, time: .shortened))
            .popover(isPresented: $showsEditor) {
                DeadlineEditor(deadline: Binding(get: { store.note(id)?.deadline ?? note.deadline }, set: {
                    store.setDeadline(id, to: $0)
                    onChange($0)
                }), done: {
                    store.setDeadline(id, to: store.note(id)?.deadline ?? note.deadline)
                    showsEditor = false
                })
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

struct DeadlineEditor: View {
    @Binding var deadline: Date
    let done: () -> Void
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Deadline").font(.headline)
                Spacer()
                Button("Done", action: done).buttonStyle(.borderedProminent)
            }
            Text(deadline, format: .dateTime.weekday(.wide).month(.abbreviated).day().hour().minute())
                .font(.subheadline).foregroundStyle(.secondary)
            HStack {
                quickDate("Today", offset: 0)
                quickDate("Tomorrow", offset: 1)
                quickDate("Next Week", offset: 7)
            }
            .controlSize(.small)
            DatePicker("Deadline date", selection: Binding(get: { deadline }, set: {
                deadline = NoteCalendar.settingDay($0, of: deadline)
            }), displayedComponents: .date)
                .datePickerStyle(.graphical).labelsHidden()
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Deadline date")
            Divider()
            DatePicker("Time", selection: $deadline, displayedComponents: .hourAndMinute)
                .datePickerStyle(.field)
                .accessibilityLabel("Deadline time")
            Text("Changes save automatically.").font(.caption).foregroundStyle(.secondary)
        }
        .padding(18).frame(width: 300)
    }

    private func quickDate(_ title: String, offset: Int) -> some View {
        Button(title) {
            if let day = calendar.date(byAdding: .day, value: offset, to: Date()) {
                deadline = NoteCalendar.settingDay(day, of: deadline)
            }
        }
    }
}
