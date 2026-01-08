//
//  Template.swift
//  DayGlow
//
//  SwiftData model for intentional day templates
//

import Foundation
import SwiftData

// MARK: - Template Category

enum TemplateCategory: String, CaseIterable, Codable {
    case selfCare = "Self-Care"
    case productivity = "Productivity"
    case social = "Social"
    case health = "Health"
    case creative = "Creative"
    case learning = "Learning"

    var icon: String {
        switch self {
        case .selfCare: return "heart.fill"
        case .productivity: return "checkmark.circle.fill"
        case .social: return "person.2.fill"
        case .health: return "heart.text.square.fill"
        case .creative: return "paintpalette.fill"
        case .learning: return "book.fill"
        }
    }

    var color: String {
        switch self {
        case .selfCare: return "#FFB6C1" // Pink
        case .productivity: return "#B19CD9" // Purple
        case .social: return "#FF9999" // Coral
        case .health: return "#98D8C8" // Teal
        case .creative: return "#FFD700" // Gold
        case .learning: return "#87CEEB" // Sky Blue
        }
    }
}

@Model
final class Template {
    // MARK: - Properties
    var id: UUID = UUID()
    var name: String = "" // Internal identifier (e.g., "solo_date")
    var displayName: String = "" // User-facing name (e.g., "Main Character Solo Date")
    var icon: String = "" // SF Symbol name
    var defaultDuration: TimeInterval = 0 // in seconds
    var suggestedChecklist: [String]?
    var eventType: String = ""
    var color: String = "" // Hex color string
    var isCustom: Bool = false // Whether this is a user-created template
    var category: String = TemplateCategory.selfCare.rawValue // Template category
    var createdDate: Date = Date() // When the template was created
    var sortOrder: Int = 0 // Custom sort order (0 = default order)

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
        suggestedChecklist: [String]? = nil,
        isCustom: Bool = false,
        category: TemplateCategory = .selfCare,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.displayName = displayName
        self.icon = icon
        self.defaultDuration = defaultDuration
        self.eventType = eventType
        self.color = color
        self.suggestedChecklist = suggestedChecklist
        self.isCustom = isCustom
        self.category = category.rawValue
        self.createdDate = Date()
        self.sortOrder = sortOrder
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
        // SELF-CARE Templates
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
            ],
            category: .selfCare
        ),
        Template(
            name: "morning_routine",
            displayName: "Morning Routine",
            icon: "sunrise.fill",
            defaultDuration: 3600, // 1 hour
            eventType: Event.EventType.personal,
            color: "#FFE4B5",
            suggestedChecklist: [
                "Wake up gently",
                "Hydrate with water",
                "Morning stretch or yoga",
                "Healthy breakfast",
                "Set daily intention"
            ],
            category: .selfCare
        ),
        Template(
            name: "evening_winddown",
            displayName: "Evening Wind-Down",
            icon: "moon.stars.fill",
            defaultDuration: 3600, // 1 hour
            eventType: Event.EventType.personal,
            color: "#E6E6FA",
            suggestedChecklist: [
                "Dim the lights",
                "Screen-free time",
                "Skincare routine",
                "Light reading or journaling",
                "Prepare for tomorrow"
            ],
            category: .selfCare
        ),

        // PRODUCTIVITY Templates
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
            ],
            category: .productivity
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
            ],
            category: .productivity
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
            ],
            category: .productivity
        ),

        // SOCIAL Templates
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
            ],
            category: .social
        ),
        Template(
            name: "family_time",
            displayName: "Family Time",
            icon: "figure.2.and.child.holdinghands",
            defaultDuration: 7200, // 2 hours
            eventType: Event.EventType.social,
            color: "#FFA07A",
            suggestedChecklist: [
                "Put away devices",
                "Play a game together",
                "Share a meal",
                "Have meaningful conversation"
            ],
            category: .social
        ),

        // HEALTH Templates
        Template(
            name: "workout_session",
            displayName: "Workout Session",
            icon: "figure.run",
            defaultDuration: 3600, // 1 hour
            eventType: Event.EventType.personal,
            color: "#90EE90",
            suggestedChecklist: [
                "Warm up",
                "Main workout",
                "Cool down and stretch",
                "Hydrate"
            ],
            category: .health
        ),
        Template(
            name: "meal_prep",
            displayName: "Meal Prep",
            icon: "fork.knife",
            defaultDuration: 5400, // 1.5 hours
            eventType: Event.EventType.personal,
            color: "#98D8C8",
            suggestedChecklist: [
                "Plan meals for the week",
                "Create shopping list",
                "Prep ingredients",
                "Cook and portion meals"
            ],
            category: .health
        ),

        // CREATIVE Templates
        Template(
            name: "hobby_hour",
            displayName: "Hobby Hour",
            icon: "paintbrush.fill",
            defaultDuration: 5400, // 1.5 hours
            eventType: Event.EventType.personal,
            color: "#FFD700",
            suggestedChecklist: [
                "Gather materials",
                "Set up workspace",
                "Focus on your craft",
                "Clean up and reflect"
            ],
            category: .creative
        ),
        Template(
            name: "creative_hour",
            displayName: "Creative Hour",
            icon: "paintpalette.fill",
            defaultDuration: 3600, // 1 hour
            eventType: Event.EventType.personal,
            color: "#DDA0DD",
            suggestedChecklist: [
                "Free your mind",
                "Explore new ideas",
                "Create without judgment",
                "Save your work"
            ],
            category: .creative
        ),

        // LEARNING Templates
        Template(
            name: "reading_time",
            displayName: "Reading Time",
            icon: "book.fill",
            defaultDuration: 3600, // 1 hour
            eventType: Event.EventType.personal,
            color: "#87CEEB",
            suggestedChecklist: [
                "Find a quiet space",
                "Minimize distractions",
                "Take notes if desired",
                "Reflect on what you learned"
            ],
            category: .learning
        ),
        Template(
            name: "skill_building",
            displayName: "Skill Building",
            icon: "lightbulb.fill",
            defaultDuration: 5400, // 1.5 hours
            eventType: Event.EventType.personal,
            color: "#ADD8E6",
            suggestedChecklist: [
                "Choose learning resource",
                "Practice actively",
                "Take breaks",
                "Review and summarize"
            ],
            category: .learning
        )
    ]
}
