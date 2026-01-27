//
//  EventFormViewModel.swift
//  SparkSprout
//
//  ViewModel for event creation/editing form with validation and conflict detection
//

import Foundation
import Observation

@Observable
final class EventFormViewModel {
    // MARK: - Form Fields
    var title: String = ""
    var startDate: Date
    var endDate: Date
    var location: String = ""
    var notes: String = ""
    var eventType: String = Event.EventType.personal
    var isFlexible: Bool = false
    var isTentative: Bool = false

    // MARK: - State
    var conflicts: [ConflictDetector.Conflict] = []
    var showConflictWarning: Bool = false
    var isValidating: Bool = false

    // MARK: - Dependencies (optional for backward compatibility)
    private let eventRepository: EventRepository?

    // MARK: - Computed Properties
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        endDate > startDate
    }

    var hasConflicts: Bool {
        !conflicts.isEmpty
    }

    var hasHardConflicts: Bool {
        conflicts.contains { $0.severity == .hard }
    }

    var durationFormatted: String {
        let duration = endDate.timeIntervalSince(startDate)
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

    // MARK: - Initialization
    init(event: Event? = nil, defaultStartDate: Date = Date(), eventRepository: EventRepository? = nil) {
        self.eventRepository = eventRepository

        if let event = event {
            // Editing existing event
            self.title = event.title
            self.startDate = event.startDate
            self.endDate = event.endDate
            self.location = event.location ?? ""
            self.notes = event.notes ?? ""
            self.eventType = event.eventType ?? Event.EventType.personal
            self.isFlexible = event.isFlexible
            self.isTentative = event.isTentative
        } else {
            // Creating new event
            // Round to next hour
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: defaultStartDate)
            let calculatedStartDate = calendar.date(from: components)?.addingTimeInterval(3600) ?? defaultStartDate
            self.startDate = calculatedStartDate
            self.endDate = calculatedStartDate.addingTimeInterval(3600) // 1 hour default duration
        }
    }

    /// Initializer for creating a new event with pre-filled values (e.g., from Quick Add)
    init(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        eventType: String? = nil,
        eventRepository: EventRepository? = nil
    ) {
        self.eventRepository = eventRepository
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location ?? ""
        self.notes = ""
        self.eventType = eventType ?? Event.EventType.personal
        self.isFlexible = false
        self.isTentative = false
    }

    // MARK: - Validation Methods

    /// Detect conflicts using provided events array (backward compatible)
    func detectConflicts(in events: [Event], excludingEventId: UUID? = nil) {
        isValidating = true

        let tempEvent = Event(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            eventType: eventType,
            isFlexible: isFlexible
        )

        conflicts = ConflictDetector.detectConflicts(
            for: tempEvent,
            in: events,
            excludingEventId: excludingEventId
        )

        isValidating = false

        // Show warning if there are conflicts
        if hasConflicts {
            showConflictWarning = true
        }
    }

    /// Detect conflicts using repository (async, DI-based approach)
    @MainActor
    func detectConflictsAsync(excludingEventId: UUID? = nil) async {
        guard let repository = eventRepository else {
            print("Warning: EventRepository not injected, cannot detect conflicts asynchronously")
            return
        }

        isValidating = true

        do {
            // Fetch events in the time range that could conflict
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: startDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? endDate
            let range = DateInterval(start: dayStart, end: dayEnd)

            let events = try await repository.fetchEvents(in: range)

            let tempEvent = Event(
                title: title,
                startDate: startDate,
                endDate: endDate,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes,
                eventType: eventType,
                isFlexible: isFlexible
            )

            conflicts = ConflictDetector.detectConflicts(
                for: tempEvent,
                in: events,
                excludingEventId: excludingEventId
            )

            // Show warning if there are conflicts
            if hasConflicts {
                showConflictWarning = true
            }
        } catch {
            print("Error detecting conflicts: \(error)")
        }

        isValidating = false
    }

    func clearConflicts() {
        conflicts = []
        showConflictWarning = false
    }

    // MARK: - Form Actions
    func adjustEndTime(to newEndDate: Date) {
        if newEndDate > startDate {
            endDate = newEndDate
        }
    }

    func setDuration(hours: Int, minutes: Int = 0) {
        let duration = TimeInterval(hours * 3600 + minutes * 60)
        endDate = startDate.addingTimeInterval(duration)
    }

    func shiftTimeBy(hours: Int) {
        startDate = startDate.addingTimeInterval(TimeInterval(hours * 3600))
        endDate = endDate.addingTimeInterval(TimeInterval(hours * 3600))
    }

    func markAsFlexible() {
        isFlexible = true
    }

    func markAsTentative() {
        isTentative = true
    }

    /// Apply a suggested time slot to the event
    func applyTimeSlot(_ newStartDate: Date) {
        let duration = endDate.timeIntervalSince(startDate)
        startDate = newStartDate
        endDate = newStartDate.addingTimeInterval(duration)
    }

    /// Find and apply the next available time slot for this event
    /// Returns true if a slot was found and applied, false otherwise
    @MainActor
    func findAndApplyNextAvailableSlot(in events: [Event]) -> Bool {
        let duration = endDate.timeIntervalSince(startDate)

        if let nextSlot = ConflictDetector.findNextAvailableSlot(
            duration: duration,
            startingFrom: startDate,
            in: events
        ) {
            applyTimeSlot(nextSlot)
            return true
        }

        return false
    }

    // MARK: - Quick Time Presets
    func applyQuickDuration(_ preset: QuickDuration) {
        switch preset {
        case .thirtyMinutes:
            setDuration(hours: 0, minutes: 30)
        case .oneHour:
            setDuration(hours: 1)
        case .ninetyMinutes:
            setDuration(hours: 1, minutes: 30)
        case .twoHours:
            setDuration(hours: 2)
        case .halfDay:
            setDuration(hours: 4)
        case .fullDay:
            setDuration(hours: 8)
        }
    }

    enum QuickDuration {
        case thirtyMinutes
        case oneHour
        case ninetyMinutes
        case twoHours
        case halfDay
        case fullDay

        var label: String {
            switch self {
            case .thirtyMinutes: return "30 min"
            case .oneHour: return "1 hour"
            case .ninetyMinutes: return "1.5 hours"
            case .twoHours: return "2 hours"
            case .halfDay: return "Half day"
            case .fullDay: return "Full day"
            }
        }
    }
}
