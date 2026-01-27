//
//  CalendarHeaderView.swift
//  SparkSprout
//
//  Calendar header with month/year display, navigation buttons, and view mode toggle
//

import SwiftUI

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable {
    case month = "Month"
    case week = "Week"

    var icon: String {
        switch self {
        case .month: return "calendar"
        case .week: return "calendar.day.timeline.left"
        }
    }
}

// MARK: - Calendar Header View

struct CalendarHeaderView: View {
    let currentMonth: String
    let viewMode: CalendarViewMode
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void
    let onViewModeChanged: (CalendarViewMode) -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Main navigation row
            HStack(spacing: Theme.Spacing.md) {
                // Previous button
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                // Current month and year
                VStack(spacing: 4) {
                    Text(currentMonth)
                        .font(Theme.Typography.title2)
                        .fontWeight(.bold)

                    // Today button (small)
                    Button(action: onToday) {
                        Text("Today")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Next button
                Button(action: onNext) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            // View mode toggle
            ViewModeToggle(
                selectedMode: viewMode,
                onModeChanged: onViewModeChanged
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
    }
}

// MARK: - View Mode Toggle

struct ViewModeToggle: View {
    let selectedMode: CalendarViewMode
    let onModeChanged: (CalendarViewMode) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(Theme.Animation.quick) {
                        onModeChanged(mode)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))
                        Text(mode.rawValue)
                            .font(Theme.Typography.caption)
                            .fontWeight(selectedMode == mode ? .semibold : .regular)
                    }
                    .foregroundStyle(selectedMode == mode ? .white : Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        selectedMode == mode
                            ? Theme.Colors.primary
                            : Color.clear
                    )
                    .cornerRadius(Theme.CornerRadius.small)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Preview

#Preview("Month Mode") {
    VStack {
        CalendarHeaderView(
            currentMonth: "January 2026",
            viewMode: .month,
            onPrevious: { print("Previous") },
            onNext: { print("Next") },
            onToday: { print("Today") },
            onViewModeChanged: { mode in print("Mode: \(mode)") }
        )

        Spacer()
    }
}

#Preview("Week Mode") {
    VStack {
        CalendarHeaderView(
            currentMonth: "Jan 20-26, 2026",
            viewMode: .week,
            onPrevious: { print("Previous") },
            onNext: { print("Next") },
            onToday: { print("Today") },
            onViewModeChanged: { mode in print("Mode: \(mode)") }
        )

        Spacer()
    }
}
