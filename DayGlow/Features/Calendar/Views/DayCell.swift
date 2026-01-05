//
//  DayCell.swift
//  DayGlow
//
//  Individual day cell in the calendar grid
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasHighlight: Bool
    let moodEmoji: String?
    let eventCount: Int

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Day number with improved background
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(Theme.Typography.body)
                    .fontWeight(isToday || isSelected ? .bold : .regular)
                    .foregroundStyle(textColor)
                    .frame(width: 40, height: 40)
                    .background(backgroundColor)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    )
                    .overlay(alignment: .topTrailing) {
                        // Highlight star badge - positioned as overlay to avoid masking
                        if hasHighlight {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(starColor)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .offset(x: 3, y: -3)
                        }
                    }
            }

            // Event count dots
            if eventCount > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(eventCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(eventDotColor)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 8)
            } else {
                Spacer()
                    .frame(height: 8)
            }

            // Mood emoji - larger and more prominent
            if let emoji = moodEmoji {
                Text(emoji)
                    .font(.system(size: 16))
                    .frame(height: 18)
            } else {
                Spacer()
                    .frame(height: 18)
            }
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            // Use white text on blue background for maximum visibility
            return .white
        } else {
            return Theme.Colors.textPrimary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Theme.Colors.accent
        } else if isToday {
            // Solid blue background for today to ensure visibility
            return .blue
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        // No border needed when using solid backgrounds
        return .clear
    }

    private var borderWidth: CGFloat {
        return 0
    }

    private var starColor: Color {
        // Make star visible on different backgrounds
        if isSelected || isToday {
            // White star on blue/accent background
            return .white
        } else {
            // Yellow star on clear/default background
            return .yellow
        }
    }

    private var eventDotColor: Color {
        // Adjust dot color for better visibility on blue backgrounds
        if isSelected || isToday {
            return .white.opacity(0.8)
        } else {
            return Theme.Colors.eventDot
        }
    }
}

// MARK: - Preview
#Preview("Regular Day") {
    DayCell(
        date: Date(),
        isSelected: false,
        isToday: false,
        hasHighlight: false,
        moodEmoji: nil,
        eventCount: 0
    )
    .padding()
}

#Preview("Selected Day") {
    DayCell(
        date: Date(),
        isSelected: true,
        isToday: false,
        hasHighlight: false,
        moodEmoji: nil,
        eventCount: 2
    )
    .padding()
}

#Preview("Today") {
    DayCell(
        date: Date(),
        isSelected: false,
        isToday: true,
        hasHighlight: true,
        moodEmoji: "😊",
        eventCount: 3
    )
    .padding()
}

#Preview("With Highlight & Events") {
    DayCell(
        date: Date(),
        isSelected: false,
        isToday: false,
        hasHighlight: true,
        moodEmoji: "🤩",
        eventCount: 2
    )
    .padding()
}
