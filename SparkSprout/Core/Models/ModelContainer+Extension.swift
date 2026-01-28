//
//  ModelContainer+Extension.swift
//  SparkSprout
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
            Template.self,
            Attendee.self
        ])

        // Use a specific database name for CloudKit mode
        // If you need to reset after schema changes, increment the version number
        // v2: Added Attendee model for contact selection and event sharing
        // v3: Added highlightFontStyle and highlightCardStyle to DayEntry
        let storeURL = URL.documentsDirectory.appending(path: "sparksprout-cloudkit-v3.store")

        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .automatic // iCloud sync enabled
        )

        print("🔵 iCloud CloudKit is ENABLED - data will sync to iCloud")

        // Check if iCloud is properly configured
        if FileManager.default.ubiquityIdentityToken != nil {
            print("✅ iCloud Identity Token: AVAILABLE")
        } else {
            print("❌ iCloud Identity Token: NOT AVAILABLE - User may not be signed in or iCloud not enabled")
        }

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            print("✅ ModelContainer created successfully with CloudKit")
            print("📦 Configuration: \(configuration.url)")
            print("🔐 CloudKit database mode: automatic")

            // Clean up any duplicate day entries from previous versions
            cleanupDuplicateDayEntries(container: container)

            // Seed default templates on first launch
            seedTemplatesIfNeeded(container: container)

            // Sample data seeding disabled - users start with a clean slate
            // Templates are still seeded for app functionality

            return container
        } catch {
            // Detailed error logging
            print("❌ FATAL ERROR creating ModelContainer:")
            print("   Error: \(error)")
            print("   LocalizedDescription: \(error.localizedDescription)")

            // If using CloudKit, try falling back to local-only mode
            print("⚠️ Attempting recovery: Switching to LOCAL-ONLY mode...")

            do {
                let fallbackConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none // Disable CloudKit temporarily
                )

                let container = try ModelContainer(
                    for: schema,
                    configurations: [fallbackConfig]
                )

                print("✅ ModelContainer created in LOCAL-ONLY mode (CloudKit disabled)")
                print("⚠️ iCloud sync is DISABLED. Data will only be stored locally.")

                // Clean up any duplicate day entries
                cleanupDuplicateDayEntries(container: container)

                // Seed default templates
                seedTemplatesIfNeeded(container: container)

                return container
            } catch {
                fatalError("Failed to create ModelContainer even in local mode: \(error.localizedDescription)")
            }
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

        do {
            let fetchDescriptor = FetchDescriptor<Template>()
            let existingTemplates = try context.fetch(fetchDescriptor)

            // First, clean up duplicates
            var templatesByName: [String: [Template]] = [:]
            for template in existingTemplates {
                templatesByName[template.name, default: []].append(template)
            }

            var duplicatesRemoved = 0
            for (name, templates) in templatesByName where templates.count > 1 {
                // Keep the first one, delete the rest
                let toDelete = templates.dropFirst()
                for duplicate in toDelete {
                    context.delete(duplicate)
                    duplicatesRemoved += 1
                }
            }

            if duplicatesRemoved > 0 {
                try context.save()
                print("🧹 Cleaned up \(duplicatesRemoved) duplicate templates")
            }

            // Refresh the list after cleanup
            let updatedTemplates = try context.fetch(fetchDescriptor)
            let existingTemplateNames = Set(updatedTemplates.map { $0.name })

            // Check which default templates are missing
            var newTemplatesAdded = 0
            for defaultTemplate in Template.defaultTemplates {
                if !existingTemplateNames.contains(defaultTemplate.name) {
                    print("📝 Adding missing template: \(defaultTemplate.displayName)")
                    context.insert(defaultTemplate)
                    newTemplatesAdded += 1
                }
            }

            if newTemplatesAdded > 0 {
                try context.save()
                print("✅ Successfully seeded \(newTemplatesAdded) new templates")
            } else {
                print("✅ All default templates already exist (\(updatedTemplates.count) total)")
            }
        } catch {
            print("⚠️ Failed to seed templates: \(error.localizedDescription)")
        }
    }

    /// Seeds sample data for demo purposes (events and highlights)
    /// Only seeds if database is empty AND user opted in via preferences
    private static func seedSampleDataIfNeeded(container: ModelContainer, shouldSeed: Bool) {
        let context = container.mainContext

        do {
            // Check if any events or day entries already exist
            let eventFetchDescriptor = FetchDescriptor<Event>()
            let dayEntryFetchDescriptor = FetchDescriptor<DayEntry>()

            let existingEvents = try context.fetch(eventFetchDescriptor)
            let existingEntries = try context.fetch(dayEntryFetchDescriptor)

            // Only seed if database is empty AND user wants sample data
            if existingEvents.isEmpty && existingEntries.isEmpty && shouldSeed {
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
                if !existingEvents.isEmpty || !existingEntries.isEmpty {
                    print("✅ Sample data already exists (\(existingEvents.count) events, \(existingEntries.count) day entries found)")
                } else {
                    print("✅ Skipping sample data (user chose to start fresh)")
                }
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
            Template.self,
            Attendee.self
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
