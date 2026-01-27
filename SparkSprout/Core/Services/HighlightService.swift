//
//  HighlightService.swift
//  SparkSprout
//
//  Service for calculating highlight streaks, statistics, and generating prompts
//  Enhanced with event-aware and weekly reflection prompts
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

    /// Returns a contextual prompt based on day of week, streak, and season
    static func contextualPrompt(for date: Date = Date(), currentStreak: Int = 0) -> String {
        // Prioritize streak-based prompts for milestones
        if let streakPrompt = streakBasedPrompt(currentStreak) {
            return streakPrompt
        }

        // Use day of week rotation as default
        return dayOfWeekPrompt(for: date)
    }

    /// Returns an event-aware prompt based on the day's events
    /// Prioritizes: event-based > streak milestone > day of week
    static func eventAwarePrompt(for date: Date = Date(), events: [Event], currentStreak: Int = 0) -> String {
        // First, try to generate an event-based prompt
        if let eventPrompt = eventBasedPrompt(from: events) {
            return eventPrompt
        }

        // Fall back to standard contextual prompt
        return contextualPrompt(for: date, currentStreak: currentStreak)
    }

    /// Generates a prompt based on the day's events
    private static func eventBasedPrompt(from events: [Event]) -> String? {
        guard !events.isEmpty else { return nil }

        // Find completed events (events that have ended)
        let now = Date()
        let completedEvents = events.filter { $0.endDate < now }

        // Prioritize certain event types for prompts
        if let socialEvent = completedEvents.first(where: { $0.eventType == Event.EventType.social }) {
            return eventPromptForType(.social, eventTitle: socialEvent.title)
        }

        if let workEvent = completedEvents.first(where: { $0.eventType == Event.EventType.work }) {
            return eventPromptForType(.work, eventTitle: workEvent.title)
        }

        if let soloDateEvent = completedEvents.first(where: { $0.eventType == Event.EventType.soloDate }) {
            return eventPromptForType(.soloDate, eventTitle: soloDateEvent.title)
        }

        if let healthEvent = completedEvents.first(where: { $0.eventType == Event.EventType.health }) {
            return eventPromptForType(.health, eventTitle: healthEvent.title)
        }

        if let deepWorkEvent = completedEvents.first(where: { $0.eventType == Event.EventType.deepWork }) {
            return eventPromptForType(.deepWork, eventTitle: deepWorkEvent.title)
        }

        // For any other completed event, use a generic event prompt
        if let firstCompleted = completedEvents.first {
            return "How did \"\(firstCompleted.title)\" go today?"
        }

        // If no completed events, check for upcoming events
        let upcomingEvents = events.filter { $0.startDate > now }
        if !upcomingEvents.isEmpty {
            return "What are you looking forward to today?"
        }

        return nil
    }

    private enum EventPromptType {
        case social, work, soloDate, health, deepWork
    }

    private static func eventPromptForType(_ type: EventPromptType, eventTitle: String) -> String {
        let prompts: [String]
        switch type {
        case .social:
            prompts = [
                "How was \"\(eventTitle)\"?",
                "What was the best part of \"\(eventTitle)\"?",
                "Any memorable moments from \"\(eventTitle)\"?"
            ]
        case .work:
            prompts = [
                "How did \"\(eventTitle)\" go?",
                "What did you accomplish in \"\(eventTitle)\"?",
                "Any breakthroughs from \"\(eventTitle)\"?"
            ]
        case .soloDate:
            prompts = [
                "How was your solo time during \"\(eventTitle)\"?",
                "What did you enjoy most about \"\(eventTitle)\"?",
                "How did \"\(eventTitle)\" make you feel?"
            ]
        case .health:
            prompts = [
                "How do you feel after \"\(eventTitle)\"?",
                "What did you notice during \"\(eventTitle)\"?",
                "Any wins from \"\(eventTitle)\"?"
            ]
        case .deepWork:
            prompts = [
                "What did you accomplish during \"\(eventTitle)\"?",
                "Any insights from your deep work session?",
                "How focused were you during \"\(eventTitle)\"?"
            ]
        }
        return prompts.randomElement() ?? prompts[0]
    }

    // MARK: - Weekly Reflection Prompts

    /// Returns a weekly reflection prompt for end-of-week summaries
    static func weeklyReflectionPrompt(from weekHighlights: [DayEntry]) -> String {
        let highlightCount = weekHighlights.count

        if highlightCount == 0 {
            return "What's one thing you'd like to remember from this week?"
        }

        if highlightCount >= 5 {
            return "Amazing week! What patterns do you notice in your highlights?"
        }

        if highlightCount >= 3 {
            return "Great momentum this week! What theme connects your highlights?"
        }

        // Analyze the week's highlights for patterns
        let moodEmojis = weekHighlights.compactMap { $0.moodEmoji }
        let hasPositiveMood = moodEmojis.contains { ["🤩", "😊", "🎉", "💪", "🙏"].contains($0) }

        if hasPositiveMood {
            return "You've had some great moments! What made this week special?"
        }

        return "Looking back at your week, what stands out most?"
    }

    /// Returns discovery prompts based on highlight history patterns
    static func discoveryPrompt(from allHighlights: [DayEntry], currentStreak: Int) -> String {
        let calendar = Calendar.current
        let now = Date()

        // Check if user tends to highlight on certain days
        let weekdayCounts = Dictionary(grouping: allHighlights) { entry in
            calendar.component(.weekday, from: entry.date)
        }.mapValues { $0.count }

        if let (topWeekday, count) = weekdayCounts.max(by: { $0.value < $1.value }), count >= 3 {
            let dayName = calendar.weekdaySymbols[topWeekday - 1]
            let todayWeekday = calendar.component(.weekday, from: now)

            if todayWeekday == topWeekday {
                return "\(dayName)s seem to bring good moments! What's today's highlight?"
            }
        }

        // Check for common mood patterns
        let recentHighlights = allHighlights.sorted { $0.date > $1.date }.prefix(10)
        let recentMoods = recentHighlights.compactMap { $0.moodEmoji }

        if recentMoods.filter({ $0 == "🤩" || $0 == "🎉" }).count >= 3 {
            return "You've been having amazing moments lately! What's exciting you?"
        }

        if recentMoods.filter({ $0 == "🙏" }).count >= 3 {
            return "Gratitude seems important to you. What are you thankful for today?"
        }

        // Default discovery prompts
        let discoveryPrompts = [
            "What small joy did you notice today?",
            "What made you smile, even briefly?",
            "What's something you did well today?",
            "Who or what brought positivity to your day?",
            "What moment would you want to remember?"
        ]

        return discoveryPrompts.randomElement() ?? discoveryPrompts[0]
    }

    /// Returns a random prompt to encourage highlight entry (legacy fallback)
    static func randomPrompt() -> String {
        return contextualPrompt()
    }

    // MARK: - Private Prompt Helpers

    /// Returns a prompt based on the day of the week
    private static func dayOfWeekPrompt(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // Get season to potentially vary the prompt
        let season = currentSeason(for: date)

        switch weekday {
        case 1: // Sunday - Reflection
            return seasonalVariation("What made this week special?", season: season, alternatives: [
                "What are you taking into the new week?",
                "What moment from this week stands out?"
            ])

        case 2: // Monday - Gratitude
            return seasonalVariation("What are you grateful for today?", season: season, alternatives: [
                "What's bringing you peace today?",
                "What are you looking forward to this week?"
            ])

        case 3: // Tuesday - Learning
            return seasonalVariation("What's one thing you learned today?", season: season, alternatives: [
                "What challenged you in a good way?",
                "What new perspective did you gain?"
            ])

        case 4: // Wednesday - Midweek momentum
            return seasonalVariation("What's your win so far this week?", season: season, alternatives: [
                "What progress are you proud of?",
                "What's keeping you motivated?"
            ])

        case 5: // Thursday - Connection
            return seasonalVariation("Who made a positive impact on your day?", season: season, alternatives: [
                "What meaningful conversation did you have?",
                "Who are you grateful to have in your life?"
            ])

        case 6: // Friday - Joy
            return seasonalVariation("What brought you joy today?", season: season, alternatives: [
                "What made you smile today?",
                "What are you celebrating this week?"
            ])

        case 7: // Saturday - Adventure
            return seasonalVariation("What surprised you today?", season: season, alternatives: [
                "What made today unique?",
                "What adventure did you have?"
            ])

        default:
            return "What's your highlight for today?"
        }
    }

    /// Returns a prompt based on current streak length (milestone-based)
    /// Only returns prompts for significant milestones, otherwise returns nil to use day-based prompts
    private static func streakBasedPrompt(_ streak: Int) -> String? {
        switch streak {
        case 3:
            return "Three days strong! What are you proud of?" // Early milestone
        case 7:
            return "A whole week! 🔥 What's been your favorite moment?" // Weekly milestone
        case 14:
            return "Two weeks! 🔥🔥 What surprised you most recently?" // Bi-weekly milestone
        case 30:
            return "30 days! 🏆 What's been your biggest win this month?" // Monthly milestone
        case 50:
            return "50 days! You're amazing! What keeps you going?" // Extended milestone
        case 100:
            return "100 days! 🎉 What moment sums up your journey?" // Major milestone
        default:
            return nil // Use day-based prompts for non-milestones (including 0, 1, 2, and all others)
        }
    }

    /// Determines the current season
    private static func currentSeason(for date: Date) -> Season {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)

        switch month {
        case 12, 1, 2:
            return .winter
        case 3, 4, 5:
            return .spring
        case 6, 7, 8:
            return .summer
        case 9, 10, 11:
            return .fall
        default:
            return .spring
        }
    }

    /// Adds seasonal variation to prompts
    private static func seasonalVariation(_ basePrompt: String, season: Season, alternatives: [String]) -> String {
        // 70% chance to use base prompt, 30% for seasonal alternatives
        if Int.random(in: 1...10) <= 7 {
            return basePrompt
        }

        return alternatives.randomElement() ?? basePrompt
    }

    enum Season {
        case spring, summer, fall, winter
    }

    /// Get an encouraging prompt based on streak status
    static func encouragingPrompt(currentStreak: Int, longestStreak: Int) -> String {
        if currentStreak == 0 {
            if longestStreak > 0 {
                return "Ready to start a new streak? You've done \(longestStreak) days before!"
            } else {
                return "Start your highlight streak today!"
            }
        } else if currentStreak == longestStreak && longestStreak >= 7 {
            return "You're at your best streak ever! 🌟 Keep going!"
        } else if currentStreak >= 30 {
            return "Incredible dedication! \(currentStreak) days strong! 🔥🔥🔥"
        } else if currentStreak >= 14 {
            return "You're on fire! \(currentStreak) days in a row! 🔥🔥"
        } else if currentStreak >= 7 {
            return "Amazing! One week streak! 🔥"
        } else {
            return "Great momentum! \(currentStreak) day streak! ⭐️"
        }
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
