//
//  DayEntryRepository.swift
//  SparkSprout
//
//  Repository protocol and implementation for DayEntry data access
//  Provides async/await interface with proper separation of concerns
//

import Foundation
import SwiftData

// MARK: - Protocol

/// Repository protocol for DayEntry data operations
protocol DayEntryRepository {
    /// Fetch the day entry for a specific date
    func fetchDayEntry(for date: Date) async throws -> DayEntry?

    /// Fetch day entries within a date range
    func fetchDayEntries(in dateRange: DateInterval) async throws -> [DayEntry]

    /// Fetch all day entries with highlights
    func fetchAllWithHighlights() async throws -> [DayEntry]

    /// Fetch all day entries
    func fetchAll() async throws -> [DayEntry]

    /// Create or get existing day entry for a date
    func getOrCreate(for date: Date) async throws -> DayEntry

    /// Update an existing day entry
    func update(_ dayEntry: DayEntry) async throws

    /// Delete a day entry
    func delete(_ dayEntry: DayEntry) async throws
}

// MARK: - SwiftData Implementation

/// SwiftData-backed implementation of DayEntryRepository
@MainActor
final class SwiftDataDayEntryRepository: DayEntryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchDayEntry(for date: Date) async throws -> DayEntry? {
        let dayStart = Calendar.current.startOfDay(for: date)

        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { entry in
                entry.date == dayStart
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    func fetchDayEntries(in dateRange: DateInterval) async throws -> [DayEntry] {
        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { entry in
                entry.date >= dateRange.start &&
                entry.date <= dateRange.end
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchAllWithHighlights() async throws -> [DayEntry] {
        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { entry in
                entry.highlightText != nil
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchAll() async throws -> [DayEntry] {
        let descriptor = FetchDescriptor<DayEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getOrCreate(for date: Date) async throws -> DayEntry {
        // Try to fetch existing entry
        if let existing = try await fetchDayEntry(for: date) {
            return existing
        }

        // Create new entry if doesn't exist
        let dayStart = Calendar.current.startOfDay(for: date)
        let newEntry = DayEntry(date: dayStart)
        modelContext.insert(newEntry)
        try modelContext.save()
        return newEntry
    }

    func update(_ dayEntry: DayEntry) async throws {
        // Entry is already in context, just save
        try modelContext.save()
    }

    func delete(_ dayEntry: DayEntry) async throws {
        modelContext.delete(dayEntry)
        try modelContext.save()
    }
}
