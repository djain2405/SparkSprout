//
//  ConflictDetector.swift
//  DayGlow
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

        // Try hourly slots throughout the day
        for hour in preferredStartHour...preferredEndHour {
            guard let startDate = calendar.date(
                bySettingHour: hour,
                minute: 0,
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
}
