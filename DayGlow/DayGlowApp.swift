//
//  DayGlowApp.swift
//  DayGlow
//
//  Main app entry point
//
//  Configured with Dependency Injection for clean architecture
//

import SwiftUI
import SwiftData

@main
struct DayGlowApp: App {
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
                print("🚀 DAYGLOW APP STARTED")
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
        }
        .accentColor(.blue)
    }
}

// MARK: - Recap/Highlights View
struct RecapView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: RecapViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Stats Card
                    if let viewModel = viewModel {
                        if !viewModel.highlightEntries.isEmpty {
                            if viewModel.isLoading {
                                statsCardSkeleton
                            } else if let stats = viewModel.stats {
                                statsCard(with: stats)
                            }
                        }

                        // Highlights List
                        if viewModel.highlightEntries.isEmpty {
                            emptyStateView
                        } else {
                            highlightsList(entries: viewModel.highlightEntries)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Highlights")
            .task {
                if viewModel == nil {
                    viewModel = dependencies.makeRecapViewModel()
                }
                await viewModel?.loadData()
            }
            .refreshable {
                await viewModel?.refresh()
            }
        }
    }

    // Loading skeleton
    private var statsCardSkeleton: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Loading stats...")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }

    // MARK: - Stats Card
    private func statsCard(with stats: HighlightService.HighlightStats) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header with gradient
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.white)
                Text("Your Progress")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding()
            .background(Theme.Gradients.purpleBlue)
            .cornerRadius(Theme.CornerRadius.medium)

            // Progress rings
            HStack(spacing: Theme.Spacing.lg) {
                StatRing(
                    value: "\(stats.currentStreak)",
                    label: "Current Streak",
                    progress: min(Double(stats.currentStreak) / 30.0, 1.0),
                    color: .orange,
                    icon: "flame.fill"
                )

                StatRing(
                    value: "\(stats.totalDays)",
                    label: "Total Days",
                    progress: min(Double(stats.totalDays) / 100.0, 1.0),
                    color: .yellow,
                    icon: "star.fill"
                )

                StatRing(
                    value: "\(stats.longestStreak)",
                    label: "Best Streak",
                    progress: min(Double(stats.longestStreak) / 30.0, 1.0),
                    color: Color(red: 1.0, green: 0.84, blue: 0.0),
                    icon: "trophy.fill"
                )
            }
            .padding(.horizontal)

            // Encouragement message
            Text(stats.encouragementMessage)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, Theme.Spacing.xs)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.large)
        .shadow(
            color: Theme.Shadow.medium.color,
            radius: Theme.Shadow.medium.radius,
            x: Theme.Shadow.medium.x,
            y: Theme.Shadow.medium.y
        )
    }

    // MARK: - Highlights List
    private func highlightsList(entries: [DayEntry]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("Recent Highlights")
                    .font(Theme.Typography.headline)
                Spacer()
            }

            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                highlightCard(entry: entry)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(
                        Theme.Animation.staggered(index: index, total: entries.count),
                        value: entries.count
                    )
            }
        }
    }

    private func highlightCard(entry: DayEntry) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Emoji or star with gradient background
            ZStack {
                Circle()
                    .fill(Theme.Gradients.sunsetOrange.opacity(0.2))
                    .frame(width: 60, height: 60)

                if let emoji = entry.moodEmoji {
                    Text(emoji)
                        .font(.system(size: 36))
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.yellow)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.highlightText ?? "")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(entry.dateFormatted)
                        .font(Theme.Typography.caption)

                    if entry.isToday {
                        Text("• Today")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Theme.Colors.cardBackground, Theme.Colors.cardBackground.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(Theme.CornerRadius.medium)
        .shadow(
            color: Theme.Shadow.small.color,
            radius: Theme.Shadow.small.radius,
            x: Theme.Shadow.small.x,
            y: Theme.Shadow.small.y
        )
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.highlight)

            Text("Your Highlights")
                .font(Theme.Typography.title)

            Text("Start adding highlights to your days to see them here. Track your best moments and build a gratitude streak!")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(.top, Theme.Spacing.xxl)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
