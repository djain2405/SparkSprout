//
//  DayGlowApp.swift
//  DayGlow
//
//  Main app entry point
//

import SwiftUI
import SwiftData

@main
struct DayGlowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.shared)
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
    @Query(sort: \DayEntry.date, order: .reverse) private var allDayEntries: [DayEntry]

    private var highlightsOnly: [DayEntry] {
        allDayEntries.filter { $0.hasHighlight }
    }

    private var stats: HighlightService.HighlightStats {
        HighlightService.calculateStats(from: allDayEntries)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Stats Card
                    if !highlightsOnly.isEmpty {
                        statsCard
                    }

                    // Highlights List
                    if highlightsOnly.isEmpty {
                        emptyStateView
                    } else {
                        highlightsList
                    }
                }
                .padding()
            }
            .navigationTitle("Highlights")
        }
    }

    // MARK: - Stats Card
    private var statsCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("Your Progress")
                    .font(Theme.Typography.headline)
                Spacer()
            }

            HStack(spacing: Theme.Spacing.lg) {
                statItem(
                    value: "\(stats.currentStreak)",
                    label: "Current Streak",
                    icon: "flame.fill",
                    color: .orange
                )

                statItem(
                    value: "\(stats.totalDays)",
                    label: "Total Days",
                    icon: "star.fill",
                    color: .yellow
                )

                statItem(
                    value: "\(stats.longestStreak)",
                    label: "Best Streak",
                    icon: "trophy.fill",
                    color: Color(hex: "#FFD700") ?? .yellow
                )
            }

            // Encouragement message
            Text(stats.encouragementMessage)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.Spacing.xs)
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .shadow(
            color: Theme.Shadow.small.color,
            radius: Theme.Shadow.small.radius,
            x: Theme.Shadow.small.x,
            y: Theme.Shadow.small.y
        )
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(Theme.Typography.title2)
                .fontWeight(.bold)
            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Highlights List
    private var highlightsList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("Recent Highlights")
                    .font(Theme.Typography.headline)
                Spacer()
            }

            ForEach(highlightsOnly) { entry in
                highlightCard(entry: entry)
            }
        }
    }

    private func highlightCard(entry: DayEntry) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            if let emoji = entry.moodEmoji {
                Text(emoji)
                    .font(.system(size: 40))
            } else {
                Image(systemName: "star.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.yellow)
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
        .background(Theme.Colors.cardBackground)
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
