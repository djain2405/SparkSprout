//
//  WeekCalendarViewModel.swift
//  SparkSprout
//
//  ViewModel for WeekCalendarView with async data loading
//  Uses repository pattern for data access
//

import Foundation
import Observation

@Observable
@MainActor
final class WeekCalendarViewModel {
    // MARK: - State
    var dayEntries: [DayEntry] = []
    var events: [Event] = []
    var isLoading = false
    var error: Error?

    // MARK: - Performance Cache (O(1) lookups)
    private var dayEntryMap: [Date: DayEntry] = [:]
    private var eventsByDateMap: [Date: [Event]] = [:]

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
    func loadData(for weekStart: Date) async {
        isLoading = true
        error = nil

        do {
            let calendar = Calendar.current
            let startOfWeek = calendar.startOfDay(for: weekStart)
            guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
                isLoading = false
                return
            }

            let range = DateInterval(
                start: startOfWeek,
                end: endOfWeek.addingTimeInterval(-1)
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
        // Build day entry map
        dayEntryMap = Dictionary(
            dayEntries.map { ($0.normalizedDate, $0) },
            uniquingKeysWith: { existing, new in
                if new.hasHighlight && !existing.hasHighlight {
                    return new
                }
                return existing
            }
        )

        // Build events by date map (full events, not just counts)
        eventsByDateMap = [:]
        for event in events {
            let normalizedDate = Calendar.current.startOfDay(for: event.startDate)
            eventsByDateMap[normalizedDate, default: []].append(event)
        }

        // Sort events by start time within each day
        for (date, dayEvents) in eventsByDateMap {
            eventsByDateMap[date] = dayEvents.sorted { $0.startDate < $1.startDate }
        }
    }

    // MARK: - Lookup Methods (O(1))
    func dayEntry(for date: Date) -> DayEntry? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return dayEntryMap[normalizedDate]
    }

    func events(for date: Date) -> [Event] {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return eventsByDateMap[normalizedDate] ?? []
    }

    func eventCount(for date: Date) -> Int {
        events(for: date).count
    }
}
