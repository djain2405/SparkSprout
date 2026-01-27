//
//  RecapView.swift
//  SparkSprout
//
//  Highlights view with stats visualization and filtered list
//

import SwiftUI
import SwiftData

// MARK: - Highlight Filter

enum HighlightFilter: String, CaseIterable {
    case thisMonth = "This Month"
    case thisWeek = "This Week"
    case all = "All Time"

    var icon: String {
        switch self {
        case .thisMonth: return "calendar"
        case .thisWeek: return "calendar.badge.clock"
        case .all: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .thisMonth: return .blue
        case .thisWeek: return .orange
        case .all: return .yellow
        }
    }
}

// MARK: - RecapView

struct RecapView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: RecapViewModel?
    @State private var selectedFilter: HighlightFilter = .thisMonth

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let viewModel = viewModel {
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.highlightEntries.isEmpty {
                            emptyStateView
                        } else {
                            // Stats Card
                            if let stats = viewModel.stats {
                                statsCard(with: stats)
                            }

                            // Filter selector
                            filterSelector

                            // Highlights list
                            highlightsList(entries: filteredEntries(from: viewModel.highlightEntries))
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

    // MARK: - Filter Selector

    private var filterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(HighlightFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(Theme.Animation.quick) {
                            selectedFilter = filter
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption)
                            Text(filter.rawValue)
                        }
                        .font(Theme.Typography.caption)
                        .fontWeight(selectedFilter == filter ? .semibold : .regular)
                        .foregroundStyle(selectedFilter == filter ? .white : Theme.Colors.textPrimary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(selectedFilter == filter ? filter.color : Theme.Colors.cardBackground)
                        .cornerRadius(Theme.CornerRadius.large)
                    }
                }
            }
        }
    }

    // MARK: - Filtered Entries

    private func filteredEntries(from entries: [DayEntry]) -> [DayEntry] {
        let calendar = Calendar.current
        let now = Date()

        let filtered: [DayEntry]
        switch selectedFilter {
        case .thisMonth:
            filtered = entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .thisWeek:
            filtered = entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        case .all:
            filtered = entries
        }

        return filtered.sorted { $0.date > $1.date }
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
            // Dynamic header based on filter
            HStack {
                Image(systemName: selectedFilter.icon)
                    .foregroundStyle(selectedFilter.color)
                Text(highlightHeaderTitle)
                    .font(Theme.Typography.headline)
                Spacer()
                Text("\(entries.count)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.small)
            }

            if entries.isEmpty {
                noHighlightsForFilter
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    HighlightListCard(entry: entry)
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
    }

    private var highlightHeaderTitle: String {
        switch selectedFilter {
        case .thisMonth:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            return "\(formatter.string(from: Date()))'s Highlights"
        case .thisWeek:
            return "This Week's Highlights"
        case .all:
            return "All Highlights"
        }
    }

    private var noHighlightsForFilter: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "text.badge.xmark")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.5))

            Text("No highlights \(selectedFilter == .thisWeek ? "this week" : "this month") yet")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("Tap on a day to add your first highlight!")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Loading highlights...")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
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

// MARK: - Highlight List Card

struct HighlightListCard: View {
    let entry: DayEntry

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Emoji with gradient background
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
}

// MARK: - Preview

#Preview {
    RecapView()
        .modelContainer(ModelContainer.preview)
}
