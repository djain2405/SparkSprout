//
//  RecapViewModel.swift
//  SparkSprout
//
//  ViewModel for RecapView with async data loading and stats calculation
//  Uses repository pattern for data access
//

import Foundation
import Observation

@Observable
@MainActor
final class RecapViewModel {
    // MARK: - State
    var highlightEntries: [DayEntry] = []
    var stats: HighlightService.HighlightStats?
    var isLoading = false
    var error: Error?

    // MARK: - Dependencies
    private let dayEntryRepository: DayEntryRepository

    // MARK: - Initialization
    init(dayEntryRepository: DayEntryRepository) {
        self.dayEntryRepository = dayEntryRepository
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Fetch all day entries with highlights
            let entries = try await dayEntryRepository.fetchAllWithHighlights()
            self.highlightEntries = entries

            // Calculate stats in background to avoid blocking UI
            let calculatedStats = await Task.detached(priority: .userInitiated) {
                HighlightService.calculateStats(from: entries)
            }.value

            self.stats = calculatedStats
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - Refresh
    func refresh() async {
        await loadData()
    }
}
