//
//  ModelContainer+Extension.swift
//  DayGlow
//
//  Shared ModelContainer setup with schema configuration and template seeding
//

import Foundation
import SwiftData

extension ModelContainer {
    /// Shared ModelContainer instance for the app
    static let shared: ModelContainer = {
        let schema = Schema([
            Event.self,
            DayEntry.self,
            Template.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Local-first, no cloud sync in MVP
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Clean up any duplicate day entries from previous versions
            cleanupDuplicateDayEntries(container: container)

            // Seed default templates on first launch
            seedTemplatesIfNeeded(container: container)

            // Seed sample data for demo purposes (first launch only)
            seedSampleDataIfNeeded(container: container)

            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()

    /// Removes duplicate DayEntry objects for the same date
    private static func cleanupDuplicateDayEntries(container: ModelContainer) {
        let context = container.mainContext

        do {
            let fetchDescriptor = FetchDescriptor<DayEntry>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            let allEntries = try context.fetch(fetchDescriptor)

            // Group by normalized date
            var entriesByDate: [Date: [DayEntry]] = [:]
            for entry in allEntries {
                let normalizedDate = Calendar.current.startOfDay(for: entry.date)
                entriesByDate[normalizedDate, default: []].append(entry)
            }

            // Find and remove duplicates
            var duplicatesRemoved = 0
            for (_, entries) in entriesByDate where entries.count > 1 {
                // Keep the entry with a highlight, or the first one if none have highlights
                let toKeep = entries.first { $0.hasHighlight } ?? entries.first!
                let toDelete = entries.filter { $0.id != toKeep.id }

                for duplicate in toDelete {
                    context.delete(duplicate)
                    duplicatesRemoved += 1
                }
            }

            if duplicatesRemoved > 0 {
                try context.save()
                print("🧹 Cleaned up \(duplicatesRemoved) duplicate day entries")
            }
        } catch {
            print("⚠️ Failed to cleanup duplicates: \(error.localizedDescription)")
        }
    }

    /// Seeds default templates if they don't already exist
    private static func seedTemplatesIfNeeded(container: ModelContainer) {
        let context = container.mainContext

        // Check if templates already exist
        let fetchDescriptor = FetchDescriptor<Template>()

        do {
            let existingTemplates = try context.fetch(fetchDescriptor)

            // Only seed if no templates exist
            if existingTemplates.isEmpty {
                print("📝 Seeding default templates...")

                for defaultTemplate in Template.defaultTemplates {
                    context.insert(defaultTemplate)
                }

                try context.save()
                print("✅ Successfully seeded \(Template.defaultTemplates.count) templates")
            } else {
                print("✅ Templates already exist (\(existingTemplates.count) found)")
            }
        } catch {
            print("⚠️ Failed to seed templates: \(error.localizedDescription)")
        }
    }

    /// Seeds sample data for demo purposes (events and highlights)
    private static func seedSampleDataIfNeeded(container: ModelContainer) {
        let context = container.mainContext

        do {
            // Check if any events or day entries already exist
            let eventFetchDescriptor = FetchDescriptor<Event>()
            let dayEntryFetchDescriptor = FetchDescriptor<DayEntry>()

            let existingEvents = try context.fetch(eventFetchDescriptor)
            let existingEntries = try context.fetch(dayEntryFetchDescriptor)

            // Only seed if both events and day entries are empty (first launch)
            if existingEvents.isEmpty && existingEntries.isEmpty {
                print("📝 Seeding sample data for demo...")

                let today = Date()
                let calendar = Calendar.current

                // Add sample events for today
                let event1 = Event(
                    title: "Team Meeting",
                    startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
                    endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
                    location: "Office",
                    notes: "Weekly sync with the team",
                    eventType: Event.EventType.work
                )

                let event2 = Event(
                    title: "Lunch with Sarah",
                    startDate: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
                    endDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: today)!,
                    location: "Downtown Cafe",
                    eventType: Event.EventType.social
                )

                let event3 = Event(
                    title: "Gym Workout",
                    startDate: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!,
                    endDate: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: today)!,
                    location: "Fitness Center",
                    eventType: Event.EventType.personal
                )

                context.insert(event1)
                context.insert(event2)
                context.insert(event3)

                // Add events for tomorrow
                if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
                    let event4 = Event(
                        title: "Client Presentation",
                        startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow)!,
                        endDate: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: tomorrow)!,
                        location: "Conference Room A",
                        notes: "Q1 results presentation",
                        eventType: Event.EventType.work
                    )
                    context.insert(event4)
                }

                // Add sample day entry with highlight for today
                let todayEntry = DayEntry(date: today)
                todayEntry.addHighlight(
                    text: "Had a great brainstorming session with the team! 🎉",
                    emoji: "🤩"
                )
                context.insert(todayEntry)

                // Add highlights for past few days
                let highlightExamples = [
                    "Finished reading an amazing book",
                    "Caught up with an old friend over coffee",
                    "Completed my first 5K run!",
                    "Tried a new recipe and it turned out great",
                    "Made progress on my side project"
                ]

                for daysAgo in 1...5 {
                    if let pastDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                        let pastEntry = DayEntry(date: pastDate)
                        pastEntry.addHighlight(
                            text: highlightExamples[daysAgo - 1],
                            emoji: DayEntry.MoodEmoji.all.randomElement()
                        )
                        context.insert(pastEntry)

                        // Add a random event to past days
                        if daysAgo <= 2 {
                            let randomEvent = Event(
                                title: "Past Event",
                                startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: pastDate)!,
                                endDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: pastDate)!,
                                eventType: Event.EventType.personal
                            )
                            context.insert(randomEvent)
                        }
                    }
                }

                try context.save()
                print("✅ Successfully seeded sample data (events and highlights)")
            } else {
                print("✅ Sample data already exists (\(existingEvents.count) events, \(existingEntries.count) day entries found)")
            }
        } catch {
            print("⚠️ Failed to seed sample data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview Container
extension ModelContainer {
    /// In-memory container for SwiftUI previews
    @MainActor
    static var preview: ModelContainer = {
        let schema = Schema([
            Event.self,
            DayEntry.self,
            Template.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true // In-memory for previews
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            let context = container.mainContext

            // Add sample data for previews
            addSampleData(to: context)

            return container
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }()

    /// Adds sample data for previews
    @MainActor
    private static func addSampleData(to context: ModelContext) {
        // Add sample templates
        for template in Template.defaultTemplates {
            context.insert(template)
        }

        // Add sample events
        let today = Date()
        let calendar = Calendar.current

        let event1 = Event(
            title: "Team Meeting",
            startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
            endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
            location: "Office",
            eventType: Event.EventType.work
        )

        let event2 = Event(
            title: "Lunch with Sarah",
            startDate: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
            endDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: today)!,
            location: "Downtown Cafe",
            eventType: Event.EventType.social
        )

        context.insert(event1)
        context.insert(event2)

        // Add sample day entry with highlight
        let dayEntry = DayEntry(date: today)
        dayEntry.addHighlight(text: "Had a great brainstorming session with the team!", emoji: "🤩")
        context.insert(dayEntry)

        // Add highlights for past few days
        for daysAgo in 1...5 {
            if let pastDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                let pastEntry = DayEntry(date: pastDate)
                pastEntry.addHighlight(
                    text: "Sample highlight from \(daysAgo) days ago",
                    emoji: DayEntry.MoodEmoji.all.randomElement()
                )
                context.insert(pastEntry)
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save sample data: \(error)")
        }
    }
}
