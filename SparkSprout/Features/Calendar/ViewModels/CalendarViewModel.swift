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

    static let weekRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
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
    var currentWeekStart: Date
    var viewMode: CalendarViewMode = .month

    // MARK: - Performance Cache
    private var _cachedDays: [Date]?
    private var _cachedMonth: Date?
    private var _cachedWeekDays: [Date]?
    private var _cachedWeekStart: Date?

    // MARK: - Computed Properties (with caching)
    var currentMonthFormatted: String {
        // Use cached formatter
        DateFormatter.monthYearFormatter.string(from: currentMonth)
    }

    var currentWeekFormatted: String {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart) else {
            return DateFormatter.weekRangeFormatter.string(from: currentWeekStart)
        }

        let startStr = DateFormatter.weekRangeFormatter.string(from: currentWeekStart)
        let endStr = DateFormatter.weekRangeFormatter.string(from: weekEnd)

        // Check if same month
        if calendar.isDate(currentWeekStart, equalTo: weekEnd, toGranularity: .month) {
            // Same month: "Jan 20-26, 2026"
            let dayEnd = calendar.component(.day, from: weekEnd)
            let year = calendar.component(.year, from: weekEnd)
            return "\(startStr)-\(dayEnd), \(year)"
        } else {
            // Different months: "Jan 27 - Feb 2, 2026"
            let year = calendar.component(.year, from: weekEnd)
            return "\(startStr) - \(endStr), \(year)"
        }
    }

    var headerTitle: String {
        switch viewMode {
        case .month:
            return currentMonthFormatted
        case .week:
            return currentWeekFormatted
        }
    }

    var isSelectedDateToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    // MARK: - Initialization
    init(selectedDate: Date = Date()) {
        self.selectedDate = selectedDate
        self.currentMonth = selectedDate

        // Calculate week start (Sunday)
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate
        self.currentWeekStart = weekStart
    }

    // MARK: - Navigation Methods

    func moveToNext() {
        switch viewMode {
        case .month:
            moveToNextMonth()
        case .week:
            moveToNextWeek()
        }
    }

    func moveToPrevious() {
        switch viewMode {
        case .month:
            moveToPreviousMonth()
        case .week:
            moveToPreviousWeek()
        }
    }

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

    func moveToNextWeek() {
        guard let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
            return
        }
        currentWeekStart = nextWeek
        _cachedWeekDays = nil
        _cachedWeekStart = nil
    }

    func moveToPreviousWeek() {
        guard let previousWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else {
            return
        }
        currentWeekStart = previousWeek
        _cachedWeekDays = nil
        _cachedWeekStart = nil
    }

    func selectDate(_ date: Date) {
        selectedDate = date

        // Update current month if selected date is in a different month
        if !Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month) {
            currentMonth = date
        }

        // Update current week if selected date is in a different week
        if !Calendar.current.isDate(date, equalTo: currentWeekStart, toGranularity: .weekOfYear) {
            let calendar = Calendar.current
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
            currentWeekStart = weekStart
            _cachedWeekDays = nil
            _cachedWeekStart = nil
        }
    }

    func selectToday() {
        let today = Date()
        selectedDate = today
        currentMonth = today

        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        currentWeekStart = weekStart
        _cachedWeekDays = nil
        _cachedWeekStart = nil
    }

    func setViewMode(_ mode: CalendarViewMode) {
        viewMode = mode

        // Sync week start with selected date when switching to week view
        if mode == .week {
            let calendar = Calendar.current
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate
            currentWeekStart = weekStart
            _cachedWeekDays = nil
            _cachedWeekStart = nil
        }
    }

    // MARK: - Month View Helper Methods (with caching for performance)

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

    // MARK: - Week View Helper Methods

    func daysInCurrentWeek() -> [Date] {
        // Check cache validity
        if let cached = _cachedWeekDays,
           let cachedWeek = _cachedWeekStart,
           Calendar.current.isDate(cachedWeek, inSameDayAs: currentWeekStart) {
            return cached
        }

        // Recompute and cache
        let days = computeDaysInCurrentWeek()
        _cachedWeekDays = days
        _cachedWeekStart = currentWeekStart
        return days
    }

    private func computeDaysInCurrentWeek() -> [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
        }
    }
}
