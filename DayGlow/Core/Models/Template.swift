//
//  Template.swift
//  DayGlow
//
//  SwiftData model for intentional day templates
//

import Foundation
import SwiftData

@Model
final class Template {
    // MARK: - Properties
    var id: UUID
    var name: String // Internal identifier (e.g., "solo_date")
    var displayName: String // User-facing name (e.g., "Main Character Solo Date")
    var icon: String // SF Symbol name
    var defaultDuration: TimeInterval // in seconds
    var suggestedChecklist: [String]?
    var eventType: String
    var color: String // Hex color string

    // MARK: - Computed Properties
    var durationHours: Int {
        Int(defaultDuration) / 3600
    }

    var durationFormatted: String {
        let hours = Int(defaultDuration) / 3600
        let minutes = (Int(defaultDuration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Initialization
    init(
        name: String,
        displayName: String,
        icon: String,
        defaultDuration: TimeInterval,
        eventType: String,
        color: String,
        suggestedChecklist: [String]? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.displayName = displayName
        self.icon = icon
        self.defaultDuration = defaultDuration
        self.eventType = eventType
        self.color = color
        self.suggestedChecklist = suggestedChecklist
    }

    // MARK: - Helper Methods
    func createEvent(for date: Date, at hour: Int = 10) -> Event {
        let calendar = Calendar.current
        let startComponents = DateComponents(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date),
            day: calendar.component(.day, from: date),
            hour: hour,
            minute: 0
        )

        guard let startDate = calendar.date(from: startComponents) else {
            fatalError("Failed to create start date from components")
        }

        let endDate = startDate.addingTimeInterval(defaultDuration)

        return Event(
            title: displayName,
            startDate: startDate,
            endDate: endDate,
            eventType: eventType,
            isFlexible: false
        )
    }
}

// MARK: - Default Templates
extension Template {
    static let defaultTemplates: [Template] = [
        Template(
            name: "solo_date",
            displayName: "Main Character Solo Date",
            icon: "person.fill",
            defaultDuration: 10800, // 3 hours
            eventType: Event.EventType.soloDate,
            color: "#FFB6C1",
            suggestedChecklist: [
                "Pick a fun activity",
                "Dress up for yourself",
                "Try something new",
                "Take yourself out to eat"
            ]
        ),
        Template(
            name: "cleaning_day",
            displayName: "Reset & Glow-Up Clean",
            icon: "sparkles",
            defaultDuration: 10800, // 3 hours
            eventType: Event.EventType.cleaning,
            color: "#98D8C8",
            suggestedChecklist: [
                "Declutter one room",
                "Deep clean bathroom",
                "Fresh sheets",
                "Open windows for fresh air"
            ]
        ),
        Template(
            name: "admin_day",
            displayName: "Admin Day",
            icon: "checkmark.circle.fill",
            defaultDuration: 7200, // 2 hours
            eventType: Event.EventType.admin,
            color: "#B19CD9",
            suggestedChecklist: [
                "Pay bills",
                "Respond to emails",
                "Schedule appointments",
                "File documents"
            ]
        ),
        Template(
            name: "deep_work",
            displayName: "Deep Work Block",
            icon: "brain.head.profile",
            defaultDuration: 14400, // 4 hours
            eventType: Event.EventType.deepWork,
            color: "#FFD700",
            suggestedChecklist: [
                "Turn off notifications",
                "Set clear goal",
                "Take breaks every 90min",
                "Eliminate distractions"
            ]
        ),
        Template(
            name: "social_time",
            displayName: "Social Connection Time",
            icon: "person.2.fill",
            defaultDuration: 10800, // 3 hours
            eventType: Event.EventType.social,
            color: "#FF9999",
            suggestedChecklist: [
                "Call a friend",
                "Plan a meetup",
                "Write a thoughtful message",
                "Be present and engaged"
            ]
        )
    ]
}
