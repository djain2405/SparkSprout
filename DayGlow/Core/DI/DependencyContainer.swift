//
//  DependencyContainer.swift
//  DayGlow
//
//  Dependency Injection container for managing app-wide dependencies
//  Provides centralized access to repositories and services
//

import SwiftUI
import SwiftData

// MARK: - Dependency Container

/// Central dependency injection container
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()

    // MARK: - Repositories
    private(set) var eventRepository: EventRepository!
    private(set) var dayEntryRepository: DayEntryRepository!

    private init() {}

    /// Configure the container with the model context
    /// Must be called on app launch before any views are created
    func configure(modelContext: ModelContext) {
        // Initialize repositories
        eventRepository = SwiftDataEventRepository(modelContext: modelContext)
        dayEntryRepository = SwiftDataDayEntryRepository(modelContext: modelContext)
    }

    /// Create a MonthGridViewModel with injected dependencies
    func makeMonthGridViewModel() -> MonthGridViewModel {
        MonthGridViewModel(
            eventRepository: eventRepository,
            dayEntryRepository: dayEntryRepository
        )
    }

    /// Create a DayDetailViewModel with injected dependencies
    func makeDayDetailViewModel(for date: Date) -> DayDetailViewModel {
        DayDetailViewModel(
            date: date,
            eventRepository: eventRepository,
            dayEntryRepository: dayEntryRepository
        )
    }

    /// Create a RecapViewModel with injected dependencies
    func makeRecapViewModel() -> RecapViewModel {
        RecapViewModel(
            dayEntryRepository: dayEntryRepository
        )
    }

    /// Create an EventFormViewModel with injected dependencies
    func makeEventFormViewModel(event: Event? = nil, defaultStartDate: Date = Date()) -> EventFormViewModel {
        EventFormViewModel(
            event: event,
            defaultStartDate: defaultStartDate,
            eventRepository: eventRepository
        )
    }
}

// MARK: - Environment Key

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}
