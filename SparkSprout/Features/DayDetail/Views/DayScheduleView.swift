//
//  DayScheduleView.swift
//  SparkSprout
//
//  Displays list of events for a specific day
//

import SwiftUI

struct DayScheduleView: View {
    let events: [Event]
    var onEventTap: ((Event) -> Void)? = nil

    private var sortedEvents: [Event] {
        events.sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("Schedule")
                    .font(Theme.Typography.headline)

                Spacer()

                Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            if events.isEmpty {
                // Empty state
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text("No events scheduled")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Text("Tap + to add your first event")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xl)
            } else {
                // Events list
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(sortedEvents) { event in
                        EventCard(
                            event: event,
                            onTap: onEventTap != nil ? { onEventTap?(event) } : nil
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("With Events") {
    let calendar = Calendar.current
    let today = Date()

    let events = [
        Event(
            title: "Team Meeting",
            startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
            endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
            location: "Office",
            eventType: Event.EventType.work
        ),
        Event(
            title: "Lunch with Sarah",
            startDate: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
            endDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: today)!,
            location: "Downtown Cafe",
            eventType: Event.EventType.social
        ),
        Event(
            title: "Gym Workout",
            startDate: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!,
            endDate: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: today)!,
            eventType: Event.EventType.personal,
            isFlexible: true
        )
    ]

    return DayScheduleView(
        events: events,
        onEventTap: { event in
            print("Tapped: \(event.title)")
        }
    )
    .padding()
}

#Preview("Empty State") {
    DayScheduleView(events: [])
        .padding()
}
