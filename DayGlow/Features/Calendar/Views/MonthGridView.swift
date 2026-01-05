//
//  MonthGridView.swift
//  DayGlow
//
//  Month calendar grid with 7-column layout
//

import SwiftUI
import SwiftData

struct MonthGridView: View {
    let paddedDays: [Date?]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void

    @Query private var dayEntries: [DayEntry]
    @Query private var events: [Event]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Weekday headers
            ForEach(weekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(height: 20)
            }

            // Days
            ForEach(0..<paddedDays.count, id: \.self) { index in
                if let date = paddedDays[index] {
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        hasHighlight: dayEntry(for: date)?.hasHighlight ?? false,
                        moodEmoji: dayEntry(for: date)?.moodEmoji,
                        eventCount: eventCount(for: date)
                    )
                    .onTapGesture {
                        onDateSelected(date)
                    }
                } else {
                    // Empty cell for padding
                    Color.clear
                        .frame(height: 60)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Helper Methods
    private func dayEntry(for date: Date) -> DayEntry? {
        dayEntries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func eventCount(for date: Date) -> Int {
        events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }.count
    }
}

// MARK: - Preview
#Preview {
    let calendar = Calendar.current
    let today = Date()

    // Generate days for current month
    let paddedDays: [Date?] = {
        guard let range = calendar.range(of: .day, in: .month, for: today),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return []
        }

        let days = range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyDays = firstWeekday - 1

        var paddedDays: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        paddedDays.append(contentsOf: days)

        let totalCells = 42
        let trailingEmptyDays = totalCells - paddedDays.count
        if trailingEmptyDays > 0 {
            paddedDays.append(contentsOf: Array(repeating: nil, count: trailingEmptyDays))
        }

        return paddedDays
    }()

    return MonthGridView(
        paddedDays: paddedDays,
        selectedDate: today,
        onDateSelected: { date in
            print("Selected: \(date)")
        }
    )
    .modelContainer(ModelContainer.preview)
    .padding()
}
