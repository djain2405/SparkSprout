//
//  CalendarViewModel.swift
//  SparkSprout
//
//  ViewModel for managing calendar navigation state
//
//  Performance optimized with cached day calculations
//

import Foundation
import Observation

// MARK: - Cached DateFormatter (Performance)
private extension DateFormatter {
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

@Observable
final class CalendarViewModel {
    // MARK: - Properties
    var selectedDate: Date
    var currentMonth: Date {
        didSet {
            // Invalidate cache when month changes
            _cachedDays = nil
            _cachedMonth = nil
        }
    }
    var displayMode: CalendarDisplayMode = .month

    // MARK: - Performance Cache
    private var _cachedDays: [Date]?
    private var _cachedMonth: Date?

    // MARK: - Display Mode
    enum CalendarDisplayMode {
        case month
        case week
        case day
    }

    // MARK: - Computed Properties (with caching)
    var currentMonthFormatted: String {
        // Use cached formatter
        DateFormatter.monthYearFormatter.string(from: currentMonth)
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

    // MARK: - Helper Methods (with caching for performance)
    func daysInCurrentMonth() -> [Date] {
        // Check cache validity
        if let cached = _cachedDays,
           let cachedMonth = _cachedMonth,
           Calendar.current.isDate(cachedMonth, equalTo: currentMonth, toGranularity: .month) {
            return cached
        }

        // Recompute and cache
        let days = computeDaysInCurrentMonth()
        _cachedDays = days
        _cachedMonth = currentMonth
        return days
    }

    private func computeDaysInCurrentMonth() -> [Date] {
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
