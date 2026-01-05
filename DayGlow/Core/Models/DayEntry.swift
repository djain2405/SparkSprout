//
//  DayEntry.swift
//  DayGlow
//
//  SwiftData model for daily highlights linked to calendar days
//

import Foundation
import SwiftData

@Model
final class DayEntry {
    // MARK: - Properties
    var id: UUID
    var date: Date // Normalized to midnight
    var highlightText: String?
    var moodEmoji: String?

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify)
    var events: [Event]?

    // MARK: - Computed Properties
    var hasHighlight: Bool {
        guard let text = highlightText else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var eventsCount: Int {
        events?.count ?? 0
    }

    // MARK: - Initialization
    init(date: Date) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.highlightText = nil
        self.moodEmoji = nil
        self.events = []
    }

    // MARK: - Helper Methods
    func addHighlight(text: String, emoji: String? = nil) {
        self.highlightText = text
        self.moodEmoji = emoji
    }

    func clearHighlight() {
        self.highlightText = nil
        self.moodEmoji = nil
    }

    func addEvent(_ event: Event) {
        if events == nil {
            events = []
        }
        events?.append(event)
        event.dayEntry = self
    }

    func removeEvent(_ event: Event) {
        events?.removeAll { $0.id == event.id }
        event.dayEntry = nil
    }
}

// MARK: - Mood Emoji Constants
extension DayEntry {
    enum MoodEmoji {
        static let amazing = "🤩"
        static let happy = "😊"
        static let good = "🙂"
        static let okay = "😐"
        static let sad = "😔"
        static let stressed = "😰"
        static let excited = "🎉"
        static let grateful = "🙏"
        static let proud = "💪"
        static let relaxed = "😌"

        static let all = [amazing, happy, good, okay, sad, stressed, excited, grateful, proud, relaxed]
    }
}
