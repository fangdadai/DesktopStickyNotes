import AppKit
import SwiftUI

enum NoteColor: String, Codable, CaseIterable, Identifiable {
    case yellow, pink, blue, green, lavender
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
    var nsColor: NSColor {
        switch self {
        case .yellow: NSColor(red: 1, green: 0.94, blue: 0.66, alpha: 1)
        case .pink: NSColor(red: 1, green: 0.81, blue: 0.85, alpha: 1)
        case .blue: NSColor(red: 0.78, green: 0.89, blue: 1, alpha: 1)
        case .green: NSColor(red: 0.82, green: 0.93, blue: 0.77, alpha: 1)
        case .lavender: NSColor(red: 0.89, green: 0.83, blue: 0.98, alpha: 1)
        }
    }
    var swiftUIColor: Color { Color(nsColor: nsColor) }
}

enum NotePriority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
    var symbolName: String {
        switch self {
        case .low: "arrow.down"
        case .medium: "minus"
        case .high: "exclamationmark.2"
        }
    }
}

struct StickyNote: Identifiable, Codable, Equatable {
    static let minimumSize = CGSize(width: 260, height: 260)
    var id = UUID()
    var deadline = defaultDeadline()
    var deadlineNeedsReview = false
    var priority: NotePriority?
    var title = ""
    var content = ""
    var color: NoteColor = .yellow
    var frame = CGRect(x: 160, y: 240, width: 300, height: 320)
    var isVisible = true
    var isPinned = false

    static func defaultDeadline(on day: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: 17, minute: 0, second: 0, of: day) ?? day
    }

    var displayTitle: String {
        let enteredTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !enteredTitle.isEmpty { return enteredTitle }
        let line = content.split(whereSeparator: \.isNewline).first.map(String.init) ?? "New Note"
        return String(line.prefix(50))
    }

    static func constrainedFrame(_ frame: CGRect, screens: [CGRect]) -> CGRect {
        guard let fallback = screens.first else { return frame }
        let valid = frame.origin.x.isFinite && frame.origin.y.isFinite && frame.width.isFinite && frame.height.isFinite
        let source = valid ? frame : CGRect(x: fallback.midX - 150, y: fallback.midY - 160, width: 300, height: 320)
        let screen = screens.max { a, b in
            let ia = a.intersection(source), ib = b.intersection(source)
            return (ia.isNull ? 0 : ia.width * ia.height) < (ib.isNull ? 0 : ib.width * ib.height)
        } ?? fallback
        let width = min(max(source.width, minimumSize.width), screen.width)
        let height = min(max(source.height, minimumSize.height), screen.height)
        return CGRect(x: min(max(source.minX, screen.minX), screen.maxX - width),
                      y: min(max(source.minY, screen.minY), screen.maxY - height), width: width, height: height)
    }
}

// Notes saved before titles, deadlines and priorities remain readable.
extension StickyNote {
    private enum CodingKeys: String, CodingKey {
        case id, title, deadline, deadlineNeedsReview, priority, content, color, frame, isVisible, isPinned
    }

    init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
        let savedDeadline = try values.decodeIfPresent(Date.self, forKey: .deadline)
        deadline = savedDeadline ?? Self.defaultDeadline()
        let savedReview = try values.decodeIfPresent(Bool.self, forKey: .deadlineNeedsReview) ?? false
        deadlineNeedsReview = savedDeadline == nil || savedReview
        priority = try values.decodeIfPresent(NotePriority.self, forKey: .priority)
        content = try values.decode(String.self, forKey: .content)
        color = try values.decode(NoteColor.self, forKey: .color)
        frame = try values.decode(CGRect.self, forKey: .frame)
        isVisible = try values.decode(Bool.self, forKey: .isVisible)
        isPinned = try values.decode(Bool.self, forKey: .isPinned)
    }
}

enum NoteCalendar {
    static func presentPriorities(in notes: [StickyNote]) -> [NotePriority?] {
        let levels: [NotePriority?] = [.high, .medium, .low, nil]
        return levels.filter { level in notes.contains { $0.priority == level } }
    }

    static func days(in month: Date, calendar: Calendar = .current) -> [Date] {
        guard let start = calendar.dateInterval(of: .month, for: month)?.start else { return [] }
        let offset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        guard let first = calendar.date(byAdding: .day, value: -offset, to: start) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
    }

    static func notes(on day: Date, in notes: [StickyNote], calendar: Calendar = .current) -> [StickyNote] {
        notes.filter { calendar.isDate($0.deadline, inSameDayAs: day) }.sorted {
            if $0.deadline != $1.deadline { return $0.deadline < $1.deadline }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    static func settingDay(_ day: Date, of deadline: Date, calendar: Calendar = .current) -> Date {
        let time = calendar.dateComponents([.hour, .minute], from: deadline)
        return calendar.date(bySettingHour: time.hour ?? 17, minute: time.minute ?? 0, second: 0, of: day) ?? day
    }
}
