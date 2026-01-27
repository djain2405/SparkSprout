//
//  WeekCalendarView.swift
//  SparkSprout
//
//  7-day horizontal timeline view for week-based calendar navigation
//

import SwiftUI
import SwiftData

struct WeekCalendarView: View {
    let weekDays: [Date]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    var refreshTrigger: UUID = UUID()

    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: WeekCalendarViewModel?

    var body: some View {
        VStack(spacing: 0) {
            // Week day headers with dates
            weekDayHeader

            Divider()
                .padding(.vertical, Theme.Spacing.sm)

            // Timeline content
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    ForEach(weekDays, id: \.timeIntervalSince1970) { date in
                        WeekDayRow(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            events: viewModel?.events(for: date) ?? [],
                            dayEntry: viewModel?.dayEntry(for: date),
                            onTap: {
                                Theme.Haptics.light()
                                onDateSelected(date)
                            }
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, 100) // Extra padding for FAB
            }
        }
        .task(id: "\(weekDays.first?.timeIntervalSince1970 ?? 0)-\(refreshTrigger)") {
            if viewModel == nil {
                viewModel = dependencies.makeWeekCalendarViewModel()
            }
            if let firstDay = weekDays.first {
                await viewModel?.loadData(for: firstDay)
            }
        }
        .overlay {
            if viewModel?.isLoading == true {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }

    // MARK: - Week Day Header

    private var weekDayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.timeIntervalSince1970) { date in
                WeekDayHeaderCell(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    isToday: Calendar.current.isDateInToday(date),
                    hasHighlight: viewModel?.dayEntry(for: date)?.hasHighlight ?? false,
                    eventCount: viewModel?.eventCount(for: date) ?? 0,
                    onTap: {
                        Theme.Haptics.light()
                        onDateSelected(date)
                    }
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }
}

// MARK: - Week Day Header Cell

struct WeekDayHeaderCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasHighlight: Bool
    let eventCount: Int
    let onTap: () -> Void

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Day of week (Mon, Tue, etc.)
                Text(Self.dayFormatter.string(from: date))
                    .font(Theme.Typography.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isToday ? Theme.Colors.primary : Theme.Colors.textSecondary)

                // Day number
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 36, height: 36)

                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(Theme.Typography.body)
                        .fontWeight(isToday || isSelected ? .bold : .regular)
                        .foregroundStyle(textColor)
                }
                .overlay(alignment: .topTrailing) {
                    if hasHighlight {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                            .offset(x: 2, y: -2)
                    }
                }

                // Event indicator dots
                HStack(spacing: 2) {
                    ForEach(0..<min(eventCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(eventDotColor)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Theme.Colors.accent
        } else if isToday {
            return .blue
        }
        return .clear
    }

    private var textColor: Color {
        if isSelected || isToday {
            return .white
        }
        return Theme.Colors.textPrimary
    }

    private var eventDotColor: Color {
        if isSelected || isToday {
            return .white.opacity(0.8)
        }
        return Theme.Colors.primary
    }
}

// MARK: - Week Day Row

struct WeekDayRow: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let events: [Event]
    let dayEntry: DayEntry?
    let onTap: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Day header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Text(Self.dateFormatter.string(from: date))
                                .font(Theme.Typography.headline)
                                .fontWeight(isToday ? .bold : .semibold)
                                .foregroundStyle(isToday ? Theme.Colors.primary : Theme.Colors.textPrimary)

                            if isToday {
                                Text("Today")
                                    .font(Theme.Typography.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Theme.Colors.primary)
                                    .cornerRadius(Theme.CornerRadius.small)
                            }
                        }

                        if let entry = dayEntry, entry.hasHighlight {
                            HStack(spacing: 4) {
                                if let emoji = entry.moodEmoji {
                                    Text(emoji)
                                        .font(.system(size: 14))
                                }
                                Text(entry.highlightText ?? "")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    // Event count badge
                    if events.count > 0 {
                        Text("\(events.count)")
                            .font(Theme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Theme.Colors.primary)
                            .clipShape(Circle())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                // Events list (show up to 3)
                if !events.isEmpty {
                    VStack(spacing: Theme.Spacing.xs) {
                        ForEach(Array(events.prefix(3)), id: \.id) { event in
                            WeekEventRow(event: event)
                        }

                        if events.count > 3 {
                            Text("+\(events.count - 3) more event\(events.count - 3 == 1 ? "" : "s")")
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .padding(.leading, Theme.Spacing.lg)
                        }
                    }
                } else {
                    // Empty state for day
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Text("No events scheduled")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
            .padding(Theme.Spacing.md)
            .background(cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 0)
            )
            .shadow(
                color: Theme.Shadow.small.color,
                radius: Theme.Shadow.small.radius,
                x: Theme.Shadow.small.x,
                y: Theme.Shadow.small.y
            )
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: Color {
        if isSelected {
            return Theme.Colors.primary.opacity(0.08)
        } else if isToday {
            return Theme.Colors.primary.opacity(0.05)
        }
        return Theme.Colors.cardBackground
    }

    private var borderColor: Color {
        if isSelected {
            return Theme.Colors.accent
        }
        return .clear
    }
}

// MARK: - Week Event Row

struct WeekEventRow: View {
    let event: Event

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Time indicator
            Rectangle()
                .fill(eventColor)
                .frame(width: 3)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(Theme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(Self.timeFormatter.string(from: event.startDate))
                        .font(Theme.Typography.caption2)

                    if let location = event.location, !location.isEmpty {
                        Text("•")
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(location)
                            .font(Theme.Typography.caption2)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(eventColor.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.small)
    }

    private var eventColor: Color {
        guard let type = event.eventType else { return Theme.Colors.primary }

        switch type {
        case Event.EventType.work: return .blue
        case Event.EventType.personal: return .purple
        case Event.EventType.social: return .pink
        case Event.EventType.health: return .green
        case Event.EventType.soloDate: return .red
        case Event.EventType.cleaning: return .teal
        case Event.EventType.admin: return .purple
        case Event.EventType.deepWork: return .orange
        default: return Theme.Colors.primary
        }
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()
    let weekDays: [Date] = (0..<7).compactMap { offset in
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return nil }
        return calendar.date(byAdding: .day, value: offset, to: weekStart)
    }

    WeekCalendarView(
        weekDays: weekDays,
        selectedDate: today,
        onDateSelected: { date in
            print("Selected: \(date)")
        }
    )
    .modelContainer(ModelContainer.preview)
}
