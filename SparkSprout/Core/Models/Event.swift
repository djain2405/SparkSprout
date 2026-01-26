//
//  Event.swift
//  SparkSprout
//
//  SwiftData model for calendar events
//

import Foundation
import SwiftData

@Model
final class Event {
    // MARK: - Properties
    var id: UUID = UUID()
    var title: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()
    var location: String?
    var notes: String?
    var eventType: String?
    var isFlexible: Bool = false
    var isTentative: Bool = false

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \DayEntry.events)
    var dayEntry: DayEntry?

    // MARK: - Computed Properties
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var isAllDay: Bool {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)

        return startComponents.hour == 0 && startComponents.minute == 0 &&
               endComponents.hour == 23 && endComponents.minute == 59
    }

    // MARK: - Initialization
    init(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        notes: String? = nil,
        eventType: String? = nil,
        isFlexible: Bool = false,
        isTentative: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.eventType = eventType
        self.isFlexible = isFlexible
        self.isTentative = isTentative
    }

    // MARK: - Helper Methods
    func overlaps(with other: Event) -> Bool {
        return startDate < other.endDate && endDate > other.startDate
    }

    func isOnSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(startDate, inSameDayAs: date)
    }
}

// MARK: - Event Type Constants
extension Event {
    enum EventType {
        static let work = "work"
        static let personal = "personal"
        static let social = "social"
        static let soloDate = "solo_date"
        static let cleaning = "cleaning"
        static let admin = "admin"
        static let deepWork = "deep_work"
        static let health = "health"
    }
}
