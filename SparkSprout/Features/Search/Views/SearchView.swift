//
//  SearchView.swift
//  SparkSprout
//
//  Unified search view for events and highlights
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SearchViewModel?

    @State private var showingEventDetail = false
    @State private var selectedEvent: Event?
    @State private var selectedDate: Date?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let viewModel = viewModel {
                    // Search bar
                    searchBar(viewModel: viewModel)

                    // Filter chips
                    filterChips(viewModel: viewModel)

                    // Results
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.showRecentSearches {
                        recentSearchesView(viewModel: viewModel)
                    } else if viewModel.showEmptyState {
                        emptyStateView
                    } else if viewModel.searchText.isEmpty && viewModel.results.isEmpty {
                        promptView
                    } else {
                        resultsList(viewModel: viewModel)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Search")
            .task {
                if viewModel == nil {
                    viewModel = dependencies.makeSearchViewModel()
                }
                await viewModel?.loadData()
            }
            .sheet(isPresented: $showingEventDetail) {
                if let event = selectedEvent {
                    AddEditEventView(event: event, date: event.startDate)
                }
            }
            .sheet(item: $selectedDate) { date in
                DayDetailView(date: date)
            }
        }
    }

    // MARK: - Search Bar

    private func searchBar(viewModel: SearchViewModel) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search events and highlights...", text: Binding(
                    get: { viewModel.searchText },
                    set: { newValue in
                        viewModel.searchText = newValue
                        viewModel.performSearch()
                    }
                ))
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    viewModel.saveRecentSearch()
                }

                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                        viewModel.performSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .padding(.horizontal)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Filter Chips

    private func filterChips(viewModel: SearchViewModel) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Result type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(SearchResultType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            isSelected: viewModel.resultType == type,
                            count: countForType(type, viewModel: viewModel)
                        ) {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.resultType = type
                                viewModel.performSearch()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Time filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(SearchTimeFilter.allCases, id: \.self) { filter in
                        TimeFilterChip(
                            title: filter.rawValue,
                            isSelected: viewModel.timeFilter == filter
                        ) {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.timeFilter = filter
                                viewModel.performSearch()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func countForType(_ type: SearchResultType, viewModel: SearchViewModel) -> Int? {
        switch type {
        case .all: return nil
        case .events: return viewModel.eventCount > 0 ? viewModel.eventCount : nil
        case .highlights: return viewModel.highlightCount > 0 ? viewModel.highlightCount : nil
        }
    }

    // MARK: - Recent Searches

    private func recentSearchesView(viewModel: SearchViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Recent Searches")
                    .font(Theme.Typography.headline)
                Spacer()
                Button("Clear") {
                    viewModel.clearRecentSearches()
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.primary)
            }
            .padding(.horizontal)

            ForEach(viewModel.recentSearches, id: \.self) { search in
                Button(action: {
                    viewModel.useRecentSearch(search)
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                        Text(search)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.small)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Results List

    private func resultsList(viewModel: SearchViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                // Results count
                if !viewModel.searchText.isEmpty {
                    HStack {
                        Text("\(viewModel.results.count) result\(viewModel.results.count == 1 ? "" : "s")")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                ForEach(viewModel.results) { result in
                    SearchResultCard(result: result) {
                        handleResultTap(result)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    private func handleResultTap(_ result: SearchResult) {
        switch result.type {
        case .event(let event):
            selectedEvent = event
            showingEventDetail = true
        case .highlight(let entry):
            selectedDate = entry.date
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No results found")
                .font(Theme.Typography.headline)

            Text("Try different keywords or adjust your filters")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Prompt View

    private var promptView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(Theme.Colors.primary.opacity(0.5))

            Text("Search your memories")
                .font(Theme.Typography.headline)

            Text("Find events by title, location, or notes.\nSearch highlights by what you wrote.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Searching...")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.top, Theme.Spacing.sm)
            Spacer()
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if let count = count {
                    Text("(\(count))")
                        .font(Theme.Typography.caption2)
                }
            }
            .font(Theme.Typography.caption)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Theme.Colors.primary : Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
        }
    }
}

struct TimeFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption2)
                .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Color.clear)
                .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let result: SearchResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    if result.icon.count <= 2 {
                        // It's an emoji
                        Text(result.icon)
                            .font(.title2)
                    } else {
                        // It's an SF Symbol
                        Image(systemName: result.icon)
                            .font(.title3)
                            .foregroundStyle(iconColor)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        resultTypeIcon
                        Text(result.subtitle)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }

    private var resultTypeIcon: some View {
        Group {
            switch result.type {
            case .event:
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            case .highlight:
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
    }

    private var iconColor: Color {
        switch result.color {
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "green": return .green
        case "red": return .red
        case "teal": return .teal
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .gray
        }
    }

    private var iconBackgroundColor: Color {
        switch result.type {
        case .event: return iconColor
        case .highlight: return .yellow
        }
    }
}

// MARK: - Date Extension for Identifiable

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Preview

#Preview {
    SearchView()
        .modelContainer(ModelContainer.preview)
}
