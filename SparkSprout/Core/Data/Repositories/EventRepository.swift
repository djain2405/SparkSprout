//
//  EventRepository.swift
//  SparkSprout
//
//  Repository protocol and implementation for Event data access
//  Provides async/await interface with proper separation of concerns
//

import Foundation
import SwiftData

// MARK: - Protocol

/// Repository protocol for Event data operations
protocol EventRepository {
    /// Fetch all events for a specific date
    func fetchEvents(for date: Date) async throws -> [Event]

    /// Fetch all events within a date range
    func fetchEvents(in dateRange: DateInterval) async throws -> [Event]

    /// Fetch all events
    func fetchAll() async throws -> [Event]

    /// Create a new event
    func create(_ event: Event) async throws

    /// Update an existing event
    func update(_ event: Event) async throws

    /// Delete an event
    func delete(_ event: Event) async throws
}

// MARK: - SwiftData Implementation

/// SwiftData-backed implementation of EventRepository
@MainActor
final class SwiftDataEventRepository: EventRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchEvents(for date: Date) async throws -> [Event] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date

        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { event in
                event.startDate >= dayStart && event.startDate < dayEnd
            },
            sortBy: [SortDescriptor(\.startDate)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchEvents(in dateRange: DateInterval) async throws -> [Event] {
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { event in
                event.startDate >= dateRange.start &&
                event.startDate <= dateRange.end
            },
            sortBy: [SortDescriptor(\.startDate)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchAll() async throws -> [Event] {
        let descriptor = FetchDescriptor<Event>(
            sortBy: [SortDescriptor(\.startDate)]
        )
        return try modelContext.fetch(descriptor)
    }

    func create(_ event: Event) async throws {
        modelContext.insert(event)
        try modelContext.save()
    }

    func update(_ event: Event) async throws {
        // Event is already in context, just save
        try modelContext.save()
    }

    func delete(_ event: Event) async throws {
        modelContext.delete(event)
        try modelContext.save()
    }
}
