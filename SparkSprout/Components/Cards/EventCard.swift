//
//  EventCard.swift
//  SparkSprout
//
//  Card component for displaying calendar events
//

import SwiftUI

struct EventCard: View {
    let event: Event
    var onTap: (() -> Void)? = nil
    var showDate: Bool = false

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Theme.Spacing.md) {
                // Time indicator bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(eventTypeColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(event.title)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(2)

                    // Time range
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(event.timeRangeFormatted)
                            .font(Theme.Typography.caption)
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)

                    // Location (if present)
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption)
                            Text(location)
                                .font(Theme.Typography.caption)
                        }
                        .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    // Date (if showing)
                    if showDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(event.startDate.dateString)
                                .font(Theme.Typography.caption)
                        }
                        .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    // Badges
                    HStack(spacing: 6) {
                        // Flexible badge
                        if event.isFlexible {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.caption2)
                                Text("Flexible")
                                    .font(Theme.Typography.caption2)
                            }
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Tentative badge
                        if event.isTentative {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge.questionmark")
                                    .font(.caption2)
                                Text("Tentative")
                                    .font(Theme.Typography.caption2)
                            }
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }

                Spacer()

                // Chevron indicator
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .buttonStyle(.plain)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .shadow(
            color: Theme.Shadow.small.color,
            radius: Theme.Shadow.small.radius,
            x: Theme.Shadow.small.x,
            y: Theme.Shadow.small.y
        )
    }

    // MARK: - Computed Properties

    private var eventTypeColor: Color {
        guard let type = event.eventType else { return .gray }

        switch type {
        case Event.EventType.work:
            return .blue
        case Event.EventType.personal:
            return .purple
        case Event.EventType.social:
            return .pink
        case Event.EventType.health:
            return .green
        case Event.EventType.soloDate:
            return Color(hex: "#FFB6C1") ?? .pink
        case Event.EventType.cleaning:
            return Color(hex: "#98D8C8") ?? .teal
        case Event.EventType.admin:
            return Color(hex: "#B19CD9") ?? .purple
        case Event.EventType.deepWork:
            return Color(hex: "#FFD700") ?? .yellow
        default:
            return .gray
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview
#Preview("Work Event") {
    EventCard(
        event: Event(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Office",
            eventType: Event.EventType.work
        ),
        onTap: { print("Tapped") }
    )
    .padding()
}

#Preview("Social Event") {
    EventCard(
        event: Event(
            title: "Lunch with Sarah",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Downtown Cafe",
            eventType: Event.EventType.social
        )
    )
    .padding()
}

#Preview("Flexible Event") {
    EventCard(
        event: Event(
            title: "Gym Workout",
            startDate: Date(),
            endDate: Date().addingTimeInterval(5400),
            eventType: Event.EventType.personal,
            isFlexible: true
        ),
        showDate: true
    )
    .padding()
}

#Preview("Tentative Event") {
    EventCard(
        event: Event(
            title: "Coffee Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Starbucks",
            eventType: Event.EventType.social,
            isTentative: true
        ),
        showDate: true
    )
    .padding()
}
