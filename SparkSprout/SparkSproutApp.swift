//
//  SparkSproutApp.swift
//  SparkSprout
//
//  Main app entry point
//
//  Configured with Dependency Injection for clean architecture
//

import SwiftUI
import SwiftData

@main
struct SparkSproutApp: App {
    @State private var dependenciesConfigured = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environment(\.dependencies, DependencyContainer.shared)
                } else {
                    OnboardingView()
                }
            }
            .onAppear {
                print("=" + String(repeating: "=", count: 60))
                print("🚀 SPARKSPROUT APP STARTED")
                print("=" + String(repeating: "=", count: 60))
            }
            .task {
                if !dependenciesConfigured {
                    print("⚙️ Configuring dependencies...")
                    await configureDependencies()
                    dependenciesConfigured = true
                    print("✅ Dependencies configured!")
                }
            }
        }
        .modelContainer(ModelContainer.shared)
    }

    @MainActor
    private func configureDependencies() async {
        DependencyContainer.shared.configure(modelContext: ModelContainer.shared.mainContext)

        // Debug: Check if there's any data in the database
        await checkDatabaseContents()
    }

    @MainActor
    private func checkDatabaseContents() async {
        let context = ModelContainer.shared.mainContext

        do {
            let eventDescriptor = FetchDescriptor<Event>()
            let events = try context.fetch(eventDescriptor)

            let entryDescriptor = FetchDescriptor<DayEntry>()
            let entries = try context.fetch(entryDescriptor)

            let templateDescriptor = FetchDescriptor<Template>()
            let templates = try context.fetch(templateDescriptor)

            print("📊 DATABASE CONTENTS:")
            print("   Events: \(events.count)")
            print("   Day Entries: \(entries.count)")
            print("   Templates: \(templates.count)")

            if events.isEmpty && entries.isEmpty {
                print("⚠️ Database is EMPTY - Create some data to test iCloud sync!")
            } else {
                print("✅ Database has data - should sync to iCloud")
            }
        } catch {
            print("❌ Error checking database: \(error)")
        }
    }
}

/// Main content view with tab navigation
struct ContentView: View {
    var body: some View {
        TabView {
            HomeCalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }

            RecapView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Highlights")
                }

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
        }
        .accentColor(.blue)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
