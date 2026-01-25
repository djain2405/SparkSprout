//
//  MonthGridView.swift
//  SparkSprout
//
//  Month calendar grid with 7-column layout
//
//  Refactored with ViewModel + Repository pattern for clean architecture
//

import SwiftUI

struct MonthGridView: View {
    let paddedDays: [Date?]
    let selectedDate: Date
    let month: Date
    let onDateSelected: (Date) -> Void
    var refreshTrigger: UUID = UUID()

    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: MonthGridViewModel?

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
                        hasHighlight: viewModel?.dayEntry(for: date)?.hasHighlight ?? false,
                        moodEmoji: viewModel?.dayEntry(for: date)?.moodEmoji,
                        eventCount: viewModel?.eventCount(for: date) ?? 0
                    )
                    .onTapGesture {
                        // Haptic feedback on tap
                        Theme.Haptics.light()
                        onDateSelected(date)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(
                        Theme.Animation.staggered(index: index, total: paddedDays.count),
                        value: viewModel?.isLoading
                    )
                } else {
                    // Empty cell for padding
                    Color.clear
                        .frame(height: 60)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .task(id: "\(month.timeIntervalSince1970)-\(refreshTrigger)") {
            if viewModel == nil {
                viewModel = dependencies.makeMonthGridViewModel()
            }
            await viewModel?.loadData(for: month)
        }
        .overlay {
            if viewModel?.isLoading == true {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
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

    MonthGridView(
        paddedDays: paddedDays,
        selectedDate: today,
        month: today,
        onDateSelected: { date in
            print("Selected: \(date)")
        }
    )
    .padding()
}
