//
//  SearchViewModel.swift
//  SparkSprout
//
//  ViewModel for unified search across events and highlights
//

import Foundation
import Observation
import SwiftData

// MARK: - Search Result Types

enum SearchResultType: String, CaseIterable {
    case all = "All"
    case events = "Events"
    case highlights = "Highlights"
}

struct SearchResult: Identifiable {
    let id = UUID()
    let type: SearchResultItemType
    let title: String
    let subtitle: String
    let date: Date
    let icon: String
    let color: String

    enum SearchResultItemType {
        case event(Event)
        case highlight(DayEntry)
    }
}

// MARK: - Search Filter

enum SearchTimeFilter: String, CaseIterable {
    case all = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"

    var dateRange: DateInterval? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .all:
            return nil
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return DateInterval(start: start, end: end)
        case .thisWeek:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return nil }
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            return DateInterval(start: weekStart, end: weekEnd)
        case .thisMonth:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return nil }
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now
            return DateInterval(start: monthStart, end: monthEnd)
        case .lastMonth:
            guard let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) else { return nil }
            return DateInterval(start: lastMonthStart, end: thisMonthStart)
        }
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class SearchViewModel {
    // MARK: - State
    var searchText = ""
    var resultType: SearchResultType = .all
    var timeFilter: SearchTimeFilter = .all
    var results: [SearchResult] = []
    var isLoading = false
    var recentSearches: [String] = []

    // MARK: - Dependencies
    private let eventRepository: EventRepository
    private let dayEntryRepository: DayEntryRepository

    // MARK: - Private State
    private var allEvents: [Event] = []
    private var allHighlights: [DayEntry] = []

    // MARK: - Initialization
    init(eventRepository: EventRepository, dayEntryRepository: DayEntryRepository) {
        self.eventRepository = eventRepository
        self.dayEntryRepository = dayEntryRepository
        loadRecentSearches()
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        do {
            async let events = eventRepository.fetchAll()
            async let highlights = dayEntryRepository.fetchAllWithHighlights()

            allEvents = try await events
            allHighlights = try await highlights

            performSearch()
            isLoading = false
        } catch {
            print("Error loading search data: \(error)")
            isLoading = false
        }
    }

    // MARK: - Search

    func performSearch() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)

        var eventResults: [SearchResult] = []
        var highlightResults: [SearchResult] = []

        // Filter events
        if resultType == .all || resultType == .events {
            let filteredEvents = allEvents.filter { event in
                // Text filter
                let matchesText = query.isEmpty ||
                    event.title.lowercased().contains(query) ||
                    (event.location?.lowercased().contains(query) ?? false) ||
                    (event.notes?.lowercased().contains(query) ?? false)

                // Time filter
                let matchesTime = matchesTimeFilter(date: event.startDate)

                return matchesText && matchesTime
            }

            eventResults = filteredEvents.map { event in
                SearchResult(
                    type: .event(event),
                    title: event.title,
                    subtitle: "\(event.timeRangeFormatted) • \(formatDate(event.startDate))",
                    date: event.startDate,
                    icon: iconForEventType(event.eventType),
                    color: colorForEventType(event.eventType)
                )
            }
        }

        // Filter highlights
        if resultType == .all || resultType == .highlights {
            let filteredHighlights = allHighlights.filter { entry in
                // Text filter
                let matchesText = query.isEmpty ||
                    (entry.highlightText?.lowercased().contains(query) ?? false)

                // Time filter
                let matchesTime = matchesTimeFilter(date: entry.date)

                return matchesText && matchesTime
            }

            highlightResults = filteredHighlights.map { entry in
                SearchResult(
                    type: .highlight(entry),
                    title: entry.highlightText ?? "",
                    subtitle: formatDate(entry.date),
                    date: entry.date,
                    icon: entry.moodEmoji ?? "star.fill",
                    color: "yellow"
                )
            }
        }

        // Combine and sort by date (most recent first)
        results = (eventResults + highlightResults).sorted { $0.date > $1.date }
    }

    func saveRecentSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        // Remove if exists and add to front
        recentSearches.removeAll { $0.lowercased() == query.lowercased() }
        recentSearches.insert(query, at: 0)

        // Keep only last 5 searches
        if recentSearches.count > 5 {
            recentSearches = Array(recentSearches.prefix(5))
        }

        saveRecentSearchesToStorage()
    }

    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearchesToStorage()
    }

    func useRecentSearch(_ search: String) {
        searchText = search
        performSearch()
    }

    // MARK: - Computed Properties

    var showEmptyState: Bool {
        !isLoading && results.isEmpty && !searchText.isEmpty
    }

    var showRecentSearches: Bool {
        searchText.isEmpty && !recentSearches.isEmpty
    }

    var eventCount: Int {
        results.filter {
            if case .event = $0.type { return true }
            return false
        }.count
    }

    var highlightCount: Int {
        results.filter {
            if case .highlight = $0.type { return true }
            return false
        }.count
    }

    // MARK: - Private Helpers

    private func matchesTimeFilter(date: Date) -> Bool {
        guard let range = timeFilter.dateRange else { return true }
        return date >= range.start && date < range.end
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func iconForEventType(_ type: String?) -> String {
        guard let type = type else { return "calendar" }
        switch type {
        case Event.EventType.work: return "briefcase.fill"
        case Event.EventType.personal: return "person.fill"
        case Event.EventType.social: return "person.2.fill"
        case Event.EventType.health: return "figure.run"
        case Event.EventType.soloDate: return "heart.fill"
        case Event.EventType.cleaning: return "sparkles"
        case Event.EventType.admin: return "doc.text.fill"
        case Event.EventType.deepWork: return "brain.head.profile"
        default: return "calendar"
        }
    }

    private func colorForEventType(_ type: String?) -> String {
        guard let type = type else { return "gray" }
        switch type {
        case Event.EventType.work: return "blue"
        case Event.EventType.personal: return "purple"
        case Event.EventType.social: return "pink"
        case Event.EventType.health: return "green"
        case Event.EventType.soloDate: return "red"
        case Event.EventType.cleaning: return "teal"
        case Event.EventType.admin: return "purple"
        case Event.EventType.deepWork: return "orange"
        default: return "gray"
        }
    }

    // MARK: - Persistence

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    private func saveRecentSearchesToStorage() {
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
}
