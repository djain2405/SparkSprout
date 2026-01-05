//
//  CalendarViewModel.swift
//  DayGlow
//
//  ViewModel for managing calendar navigation state
//

import Foundation
import Observation

@Observable
final class CalendarViewModel {
    // MARK: - Properties
    var selectedDate: Date
    var currentMonth: Date
    var displayMode: CalendarDisplayMode = .month

    // MARK: - Display Mode
    enum CalendarDisplayMode {
        case month
        case week
        case day
    }

    // MARK: - Computed Properties
    var currentMonthFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    var isSelectedDateToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    // MARK: - Initialization
    init(selectedDate: Date = Date()) {
        self.selectedDate = selectedDate
        self.currentMonth = selectedDate
    }

    // MARK: - Navigation Methods
    func moveToNextMonth() {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else {
            return
        }
        currentMonth = nextMonth
    }

    func moveToPreviousMonth() {
        guard let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) else {
            return
        }
        currentMonth = previousMonth
    }

    func selectDate(_ date: Date) {
        selectedDate = date

        // Update current month if selected date is in a different month
        if !Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month) {
            currentMonth = date
        }
    }

    func selectToday() {
        let today = Date()
        selectedDate = today
        currentMonth = today
    }

    // MARK: - Helper Methods
    func daysInCurrentMonth() -> [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }

        let firstDay = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: currentMonth)
        )!

        return range.compactMap { day -> Date? in
            Calendar.current.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    func paddedDaysForGrid() -> [Date?] {
        let daysInMonth = daysInCurrentMonth()
        guard let firstDay = daysInMonth.first else { return [] }

        let firstWeekday = Calendar.current.component(.weekday, from: firstDay)
        let leadingEmptyDays = firstWeekday - 1 // Sunday = 1, so subtract 1

        var paddedDays: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        paddedDays.append(contentsOf: daysInMonth)

        // Pad trailing days to complete the grid (42 cells = 6 weeks)
        let totalCells = 42
        let trailingEmptyDays = totalCells - paddedDays.count
        if trailingEmptyDays > 0 {
            paddedDays.append(contentsOf: Array(repeating: nil, count: trailingEmptyDays))
        }

        return paddedDays
    }
}
