//
//  ConflictDetector.swift
//  SparkSprout
//
//  Service for detecting event scheduling conflicts
//

import Foundation

struct ConflictDetector {

    // MARK: - Conflict Types

    enum ConflictSeverity {
        case hard      // Complete overlap (>50%)
        case soft      // Partial overlap
        case adjacent  // Back-to-back with no buffer
    }

    struct Conflict {
        let event: Event
        let severity: ConflictSeverity

        var description: String {
            switch severity {
            case .hard:
                return "You're double-booked with '\(event.title)'"
            case .soft:
                return "You're tight here with '\(event.title)'"
            case .adjacent:
                return "Back-to-back with '\(event.title)'"
            }
        }

        var color: String {
            switch severity {
            case .hard: return "red"
            case .soft: return "orange"
            case .adjacent: return "blue"
            }
        }
    }

    // MARK: - Detection Methods

    /// Detects conflicts between a new event and existing events
    /// - Parameters:
    ///   - newEvent: The event being created or edited
    ///   - existingEvents: All existing events to check against
    ///   - excludingEventId: Optional event ID to exclude (when editing an existing event)
    ///   - bufferMinutes: Minimum buffer time between events (default: 15 minutes)
    /// - Returns: Array of conflicts sorted by severity
    static func detectConflicts(
        for newEvent: Event,
        in existingEvents: [Event],
        excludingEventId: UUID? = nil,
        bufferMinutes: Int = 15
    ) -> [Conflict] {
        let buffer = TimeInterval(bufferMinutes * 60)

        let conflicts = existingEvents.compactMap { existing -> Conflict? in
            // Skip the event being edited
            if let excludingId = excludingEventId, existing.id == excludingId {
                return nil
            }

            // Skip flexible events (they have lower priority)
            if existing.isFlexible {
                return nil
            }

            let newStart = newEvent.startDate
            let newEnd = newEvent.endDate
            let existingStart = existing.startDate
            let existingEnd = existing.endDate

            // Check for overlap
            if newStart < existingEnd && newEnd > existingStart {
                // Calculate overlap percentage
                let overlapStart = max(newStart, existingStart)
                let overlapEnd = min(newEnd, existingEnd)
                let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)

                let newEventDuration = newEnd.timeIntervalSince(newStart)
                let existingEventDuration = existingEnd.timeIntervalSince(existingStart)
                let shorterDuration = min(newEventDuration, existingEventDuration)

                let overlapPercentage = overlapDuration / shorterDuration

                // Determine severity based on overlap percentage
                if overlapPercentage > 0.5 {
                    return Conflict(event: existing, severity: .hard)
                } else {
                    return Conflict(event: existing, severity: .soft)
                }
            }

            // Check for adjacent events (within buffer time)
            let timeBetweenEvents = min(
                abs(newStart.timeIntervalSince(existingEnd)),
                abs(existingStart.timeIntervalSince(newEnd))
            )

            if timeBetweenEvents > 0 && timeBetweenEvents < buffer {
                return Conflict(event: existing, severity: .adjacent)
            }

            return nil
        }

        // Sort by severity: hard > soft > adjacent
        return conflicts.sorted { conflict1, conflict2 in
            let severityOrder: [ConflictSeverity: Int] = [.hard: 3, .soft: 2, .adjacent: 1]
            return severityOrder[conflict1.severity]! > severityOrder[conflict2.severity]!
        }
    }

    /// Quick check if an event has any conflicts
    static func hasConflicts(
        for newEvent: Event,
        in existingEvents: [Event],
        excludingEventId: UUID? = nil
    ) -> Bool {
        return !detectConflicts(
            for: newEvent,
            in: existingEvents,
            excludingEventId: excludingEventId
        ).isEmpty
    }

    /// Get the most severe conflict
    static func mostSevereConflict(
        for newEvent: Event,
        in existingEvents: [Event],
        excludingEventId: UUID? = nil
    ) -> Conflict? {
        return detectConflicts(
            for: newEvent,
            in: existingEvents,
            excludingEventId: excludingEventId
        ).first
    }

    /// Check if a time slot is available
    static func isTimeSlotAvailable(
        startDate: Date,
        endDate: Date,
        in existingEvents: [Event],
        bufferMinutes: Int = 15
    ) -> Bool {
        let tempEvent = Event(
            title: "Temp",
            startDate: startDate,
            endDate: endDate
        )

        return !hasConflicts(for: tempEvent, in: existingEvents)
    }

    /// Suggest alternative time slots
    static func suggestAlternativeTimeSlots(
        duration: TimeInterval,
        on date: Date,
        in existingEvents: [Event],
        preferredStartHour: Int = 9,
        preferredEndHour: Int = 17
    ) -> [Date] {
        var suggestions: [Date] = []
        let calendar = Calendar.current

        // Try 15-minute increments throughout the day for better slot detection
        let incrementMinutes = 15
        let startMinute = preferredStartHour * 60
        let endMinute = preferredEndHour * 60

        for minute in stride(from: startMinute, to: endMinute, by: incrementMinutes) {
            let hour = minute / 60
            let min = minute % 60

            guard let startDate = calendar.date(
                bySettingHour: hour,
                minute: min,
                second: 0,
                of: date
            ) else { continue }

            let endDate = startDate.addingTimeInterval(duration)

            if isTimeSlotAvailable(startDate: startDate, endDate: endDate, in: existingEvents) {
                suggestions.append(startDate)
            }

            // Stop after finding 3 suggestions
            if suggestions.count >= 3 {
                break
            }
        }

        return suggestions
    }

    /// Find the next available time slot that can fit the event duration
    /// - Parameters:
    ///   - duration: Duration of the event in seconds
    ///   - startingFrom: The date to start searching from
    ///   - existingEvents: All existing events to check against
    ///   - searchDays: Number of days to search forward (default: 7)
    ///   - preferredStartHour: Preferred earliest hour (default: 8 AM)
    ///   - preferredEndHour: Preferred latest hour (default: 20 PM / 8 PM)
    /// - Returns: The start date of the next available slot, or nil if none found
    static func findNextAvailableSlot(
        duration: TimeInterval,
        startingFrom: Date,
        in existingEvents: [Event],
        searchDays: Int = 7,
        preferredStartHour: Int = 8,
        preferredEndHour: Int = 20
    ) -> Date? {
        let calendar = Calendar.current
        let incrementMinutes = 15

        // Search across multiple days
        for dayOffset in 0..<searchDays {
            guard let searchDay = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: startingFrom)) else {
                continue
            }

            // For the first day, start from current time; for other days, start from preferred hour
            let actualStartHour = dayOffset == 0 ? calendar.component(.hour, from: startingFrom) : preferredStartHour
            let actualStartMinute = dayOffset == 0 ? calendar.component(.minute, from: startingFrom) : 0

            let startMinute = actualStartHour * 60 + actualStartMinute
            let endMinute = preferredEndHour * 60

            // Try 15-minute increments
            for minute in stride(from: startMinute, to: endMinute, by: incrementMinutes) {
                let hour = minute / 60
                let min = minute % 60

                guard let candidateStart = calendar.date(
                    bySettingHour: hour,
                    minute: min,
                    second: 0,
                    of: searchDay
                ) else { continue }

                let candidateEnd = candidateStart.addingTimeInterval(duration)

                // Check if this slot is available
                if isTimeSlotAvailable(startDate: candidateStart, endDate: candidateEnd, in: existingEvents) {
                    return candidateStart
                }
            }
        }

        return nil
    }

    /// Get formatted time slot suggestions with duration
    struct TimeSlotSuggestion {
        let startDate: Date
        let endDate: Date

        var formattedTimeRange: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }

        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: startDate)
        }

        var isToday: Bool {
            Calendar.current.isDateInToday(startDate)
        }

        var isTomorrow: Bool {
            Calendar.current.isDateInTomorrow(startDate)
        }

        var displayDate: String {
            if isToday {
                return "Today"
            } else if isTomorrow {
                return "Tomorrow"
            } else {
                return formattedDate
            }
        }
    }

    /// Get formatted suggestions for alternative time slots
    static func getFormattedSuggestions(
        duration: TimeInterval,
        on date: Date,
        in existingEvents: [Event],
        count: Int = 3
    ) -> [TimeSlotSuggestion] {
        let startDates = suggestAlternativeTimeSlots(
            duration: duration,
            on: date,
            in: existingEvents
        )

        return startDates.prefix(count).map { startDate in
            TimeSlotSuggestion(
                startDate: startDate,
                endDate: startDate.addingTimeInterval(duration)
            )
        }
    }
}
