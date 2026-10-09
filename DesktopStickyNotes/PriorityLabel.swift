import SwiftUI

// One visual language for the note control, lists, calendar key and day markers.
struct PriorityLabel: View {
    let priority: NotePriority?
    var unassignedTitle = "None"
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Label(priority?.name ?? unassignedTitle, systemImage: priority?.symbolName ?? "circle.dashed")
            .foregroundStyle(tint)
            .accessibilityLabel("Priority: \(priority?.name ?? "None")")
    }

    private var tint: Color {
        guard let priority else { return .secondary }
        let hex: UInt32
        switch (priority, colorScheme) {
        case (.high, .dark): hex = 0xFF8A91
        case (.medium, .dark): hex = 0xF6CF75
        case (.low, .dark): hex = 0x8ABEFF
        case (.high, _): hex = 0xA3262E
        case (.medium, _): hex = 0x805600
        case (.low, _): hex = 0x185A9D
        }
        return Color(red: Double((hex >> 16) & 255) / 255,
                     green: Double((hex >> 8) & 255) / 255,
                     blue: Double(hex & 255) / 255)
    }
}
