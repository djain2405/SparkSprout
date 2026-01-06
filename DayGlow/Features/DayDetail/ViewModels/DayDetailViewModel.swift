//
//  DayDetailViewModel.swift
//  DayGlow
//
//  ViewModel for DayDetailView with async data loading
//  Uses repository pattern for data access
//

import Foundation
import Observation

@Observable
@MainActor
final class DayDetailViewModel {
    // MARK: - State
    var events: [Event] = []
    var dayEntry: DayEntry?
    var isLoading = false
    var error: Error?

    let date: Date

    // MARK: - Dependencies
    private let eventRepository: EventRepository
    private let dayEntryRepository: DayEntryRepository

    // MARK: - Initialization
    init(
        date: Date,
        eventRepository: EventRepository,
        dayEntryRepository: DayEntryRepository
    ) {
        self.date = date
        self.eventRepository = eventRepository
        self.dayEntryRepository = dayEntryRepository
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Load events and day entry in parallel
            async let eventsTask = eventRepository.fetchEvents(for: date)
            async let entryTask = dayEntryRepository.fetchDayEntry(for: date)

            let (loadedEvents, loadedEntry) = try await (eventsTask, entryTask)

            self.events = loadedEvents.sorted { $0.startDate < $1.startDate }
            self.dayEntry = loadedEntry

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - Actions
    func deleteEvent(_ event: Event) async throws {
        try await eventRepository.delete(event)
        await loadData() // Reload after deletion
    }

    func getOrCreateDayEntry() async throws -> DayEntry {
        if let existing = dayEntry {
            return existing
        }

        let newEntry = try await dayEntryRepository.getOrCreate(for: date)
        self.dayEntry = newEntry
        return newEntry
    }

    func updateDayEntry() async throws {
        guard let entry = dayEntry else { return }
        try await dayEntryRepository.update(entry)
    }
}
