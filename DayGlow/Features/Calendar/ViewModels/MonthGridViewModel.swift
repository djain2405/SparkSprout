//
//  MonthGridViewModel.swift
//  DayGlow
//
//  ViewModel for MonthGridView with async data loading
//  Uses repository pattern for data access
//

import Foundation
import Observation

@Observable
@MainActor
final class MonthGridViewModel {
    // MARK: - State
    var dayEntries: [DayEntry] = []
    var events: [Event] = []
    var isLoading = false
    var error: Error?

    // MARK: - Performance Cache (O(1) lookups)
    private var dayEntryMap: [Date: DayEntry] = [:]
    private var eventCountMap: [Date: Int] = [:]

    // MARK: - Dependencies
    private let eventRepository: EventRepository
    private let dayEntryRepository: DayEntryRepository

    // MARK: - Initialization
    init(
        eventRepository: EventRepository,
        dayEntryRepository: DayEntryRepository
    ) {
        self.eventRepository = eventRepository
        self.dayEntryRepository = dayEntryRepository
    }

    // MARK: - Data Loading
    func loadData(for month: Date) async {
        isLoading = true
        error = nil

        do {
            let calendar = Calendar.current
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                isLoading = false
                return
            }

            let range = DateInterval(
                start: startOfMonth,
                end: calendar.startOfDay(for: endOfMonth).addingTimeInterval(86400 - 1)
            )

            // Load events and entries in parallel
            async let eventsTask = eventRepository.fetchEvents(in: range)
            async let entriesTask = dayEntryRepository.fetchDayEntries(in: range)

            let (loadedEvents, loadedEntries) = try await (eventsTask, entriesTask)

            self.events = loadedEvents
            self.dayEntries = loadedEntries

            // Build lookup caches for O(1) access
            buildCaches()

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - Cache Building
    private func buildCaches() {
        // Build day entry map (keeping most recent entry if duplicates exist)
        dayEntryMap = Dictionary(
            dayEntries.map { ($0.normalizedDate, $0) },
            uniquingKeysWith: { existing, new in
                // If duplicates exist for a date, keep the one with a highlight or the newer one
                if new.hasHighlight && !existing.hasHighlight {
                    return new
                }
                return existing
            }
        )

        // Build event count map
        eventCountMap = events
            .map { Calendar.current.startOfDay(for: $0.startDate) }
            .reduce(into: [:]) { counts, date in
                counts[date, default: 0] += 1
            }
    }

    // MARK: - Lookup Methods (O(1))
    func dayEntry(for date: Date) -> DayEntry? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return dayEntryMap[normalizedDate]
    }

    func eventCount(for date: Date) -> Int {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return eventCountMap[normalizedDate] ?? 0
    }
}
