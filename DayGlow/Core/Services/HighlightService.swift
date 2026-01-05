//
//  HighlightService.swift
//  DayGlow
//
//  Service for calculating highlight streaks and statistics
//

import Foundation

struct HighlightService {

    // MARK: - Streak Calculations

    /// Calculates the current streak of consecutive days with highlights
    static func calculateCurrentStreak(from dayEntries: [DayEntry]) -> Int {
        let today = Date()
        let calendar = Calendar.current

        // Filter entries with highlights and sort by date descending
        let entriesWithHighlights = dayEntries
            .filter { $0.hasHighlight }
            .sorted { $0.date > $1.date }

        guard !entriesWithHighlights.isEmpty else { return 0 }

        // Get the most recent highlight
        let mostRecentHighlight = entriesWithHighlights[0]
        let mostRecentDate = calendar.startOfDay(for: mostRecentHighlight.date)
        let todayStart = calendar.startOfDay(for: today)

        // Calculate days between most recent highlight and today
        let daysSinceLastHighlight = calendar.dateComponents([.day], from: mostRecentDate, to: todayStart).day ?? 0

        // If the most recent highlight is more than 1 day ago, streak is broken
        if daysSinceLastHighlight > 1 {
            return 0
        }

        // Count consecutive days starting from the most recent highlight
        var streak = 1
        var expectedDate = calendar.date(byAdding: .day, value: -1, to: mostRecentDate) ?? mostRecentDate

        for i in 1..<entriesWithHighlights.count {
            let entry = entriesWithHighlights[i]
            let entryDate = calendar.startOfDay(for: entry.date)

            if calendar.isDate(entryDate, inSameDayAs: expectedDate) {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else {
                // Streak broken
                break
            }
        }

        return streak
    }

    /// Calculates the longest streak ever achieved
    static func calculateLongestStreak(from dayEntries: [DayEntry]) -> Int {
        let calendar = Calendar.current

        // Filter and sort entries with highlights
        let entriesWithHighlights = dayEntries
            .filter { $0.hasHighlight }
            .sorted { $0.date < $1.date }

        guard !entriesWithHighlights.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<entriesWithHighlights.count {
            let previousDate = calendar.startOfDay(for: entriesWithHighlights[i - 1].date)
            let currentDate = calendar.startOfDay(for: entriesWithHighlights[i].date)

            // Check if dates are consecutive (1 day apart)
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(nextDay, inSameDayAs: currentDate) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }

    /// Returns the total number of days with highlights
    static func totalHighlightDays(from dayEntries: [DayEntry]) -> Int {
        dayEntries.filter { $0.hasHighlight }.count
    }

    /// Returns highlights for a specific month
    static func highlightsForMonth(_ date: Date, from dayEntries: [DayEntry]) -> [DayEntry] {
        let calendar = Calendar.current

        return dayEntries.filter { entry in
            calendar.isDate(entry.date, equalTo: date, toGranularity: .month) && entry.hasHighlight
        }.sorted { $0.date > $1.date }
    }

    /// Returns highlights for a specific week
    static func highlightsForWeek(_ date: Date, from dayEntries: [DayEntry]) -> [DayEntry] {
        let calendar = Calendar.current

        return dayEntries.filter { entry in
            calendar.isDate(entry.date, equalTo: date, toGranularity: .weekOfYear) && entry.hasHighlight
        }.sorted { $0.date > $1.date }
    }

    /// Returns recent highlights (last N days)
    static func recentHighlights(count: Int, from dayEntries: [DayEntry]) -> [DayEntry] {
        dayEntries
            .filter { $0.hasHighlight }
            .sorted { $0.date > $1.date }
            .prefix(count)
            .map { $0 }
    }

    // MARK: - Prompts

    /// Returns a random prompt to encourage highlight entry
    static func randomPrompt() -> String {
        let prompts = [
            "What made you smile today?",
            "What's your best moment?",
            "What are you proud of?",
            "What brought you joy?",
            "What's one good thing that happened?",
            "What made today special?",
            "What are you grateful for?",
            "What's your win for today?",
            "What moment do you want to remember?",
            "What surprised you today?"
        ]

        return prompts.randomElement() ?? "What's your highlight for today?"
    }

    // MARK: - Statistics

    struct HighlightStats {
        let currentStreak: Int
        let longestStreak: Int
        let totalDays: Int
        let thisWeekCount: Int
        let thisMonthCount: Int

        var streakEmoji: String {
            if currentStreak >= 30 {
                return "🔥🔥🔥"
            } else if currentStreak >= 14 {
                return "🔥🔥"
            } else if currentStreak >= 7 {
                return "🔥"
            } else if currentStreak >= 3 {
                return "⭐️"
            } else {
                return "✨"
            }
        }

        var encouragementMessage: String {
            if currentStreak == 0 {
                return "Start your streak today!"
            } else if currentStreak == 1 {
                return "Great start! Keep it going!"
            } else if currentStreak < 7 {
                return "You're on a roll! \(7 - currentStreak) more days to a week!"
            } else if currentStreak < 30 {
                return "Amazing streak! \(30 - currentStreak) more to hit 30 days!"
            } else {
                return "Incredible! You're a highlight champion! 🏆"
            }
        }
    }

    /// Calculates comprehensive highlight statistics
    static func calculateStats(from dayEntries: [DayEntry]) -> HighlightStats {
        let today = Date()

        return HighlightStats(
            currentStreak: calculateCurrentStreak(from: dayEntries),
            longestStreak: calculateLongestStreak(from: dayEntries),
            totalDays: totalHighlightDays(from: dayEntries),
            thisWeekCount: highlightsForWeek(today, from: dayEntries).count,
            thisMonthCount: highlightsForMonth(today, from: dayEntries).count
        )
    }
}
