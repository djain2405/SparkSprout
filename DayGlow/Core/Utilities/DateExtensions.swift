//
//  DateExtensions.swift
//  DayGlow
//
//  Date helper extensions and utilities
//
//  Performance optimized with cached DateFormatters
//

import Foundation

// MARK: - Cached DateFormatters (Performance Optimization)
private extension DateFormatter {
    /// Cached time formatter (e.g., "2:30 PM")
    static let cachedTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Cached date formatter (e.g., "Jan 15, 2026")
    static let cachedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    /// Cached date-time formatter
    static let cachedDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension Date {
    /// Returns the start of the day (midnight) for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns the end of the day (11:59:59 PM) for this date
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Returns the start of the month for this date
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Returns the end of the month for this date
    var endOfMonth: Date {
        guard let nextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: startOfMonth) else {
            return self
        }
        return Calendar.current.date(byAdding: DateComponents(second: -1), to: nextMonth) ?? self
    }

    /// Check if this date is in the same day as another date
    func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: otherDate)
    }

    /// Check if this date is in the same month as another date
    func isSameMonth(as otherDate: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: otherDate, toGranularity: .month)
    }

    /// Check if this date is in the same year as another date
    func isSameYear(as otherDate: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: otherDate, toGranularity: .year)
    }

    /// Returns the number of days between this date and another date
    func daysBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startOfDay, to: otherDate.startOfDay)
        return abs(components.day ?? 0)
    }

    /// Adds a number of days to this date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Adds a number of months to this date
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Adds a number of hours to this date
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Returns a formatted string for time (e.g., "2:30 PM")
    /// Uses cached DateFormatter for performance
    var timeString: String {
        DateFormatter.cachedTimeFormatter.string(from: self)
    }

    /// Returns a formatted string for date (e.g., "Jan 15, 2026")
    /// Uses cached DateFormatter for performance
    var dateString: String {
        DateFormatter.cachedDateFormatter.string(from: self)
    }

    /// Returns a formatted string for date and time
    /// Uses cached DateFormatter for performance
    var dateTimeString: String {
        DateFormatter.cachedDateTimeFormatter.string(from: self)
    }

    /// Returns a relative time string (e.g., "Today", "Yesterday", "2 days ago")
    var relativeString: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow"
        } else {
            let days = daysBetween(now)
            if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
            } else {
                return dateString
            }
        }
    }
}

extension Calendar {
    /// Returns an array of dates for each day in the given month
    func daysInMonth(for date: Date) -> [Date] {
        guard let range = range(of: .day, in: .month, for: date) else {
            return []
        }

        let firstDay = date.startOfMonth

        return range.compactMap { day -> Date? in
            self.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    /// Returns the weekday index (1-7, where 1 = Sunday)
    func weekday(for date: Date) -> Int {
        component(.weekday, from: date)
    }
}
