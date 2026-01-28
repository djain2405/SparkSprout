//
//  DayCell.swift
//  SparkSprout
//
//  Individual day cell in the calendar grid
//  Features: Mood gradient ring, event count badge, sparkle effect, today pulse
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasHighlight: Bool
    let moodEmoji: String?
    let eventCount: Int

    @State private var isPressed = false
    @State private var todayPulseScale: CGFloat = 1.0
    @State private var sparklePhase: CGFloat = 0

    private let cellSize: CGFloat = 44

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Today pulse animation ring
                if isToday {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: cellSize + 8, height: cellSize + 8)
                        .scaleEffect(todayPulseScale)
                        .opacity(2 - todayPulseScale)
                }

                // Mood gradient ring for highlight days
                if hasHighlight && !isSelected {
                    Circle()
                        .stroke(
                            Theme.Gradients.moodGradient(for: moodEmoji),
                            lineWidth: 3
                        )
                        .frame(width: cellSize + 4, height: cellSize + 4)
                        .shadow(color: moodGlowColor.opacity(0.5), radius: 4)
                }

                // Main day circle with background
                ZStack {
                    // Background circle
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: cellSize, height: cellSize)

                    // Day number
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 16, weight: isToday || isSelected ? .bold : .medium))
                        .foregroundStyle(textColor)
                }

                // Sparkle effect for highlight days
                if hasHighlight {
                    SparkleOverlay(phase: sparklePhase)
                        .frame(width: cellSize + 16, height: cellSize + 16)
                }

                // Event count badge
                if eventCount > 0 {
                    Text("\(eventCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(eventBadgeColor)
                                .shadow(color: eventBadgeColor.opacity(0.5), radius: 2)
                        )
                        .offset(x: cellSize / 2 - 4, y: -cellSize / 2 + 4)
                }
            }
            .frame(width: cellSize + 16, height: cellSize + 16)
            .scaleEffect(isPressed ? 0.92 : 1.0)

            // Mood emoji display
            if let emoji = moodEmoji {
                Text(emoji)
                    .font(.system(size: 14))
                    .frame(height: 16)
            } else {
                Spacer()
                    .frame(height: 16)
            }
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Today pulse animation
        if isToday {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: false)
            ) {
                todayPulseScale = 1.5
            }
        }

        // Sparkle animation for highlights
        if hasHighlight {
            withAnimation(
                .linear(duration: 3.0)
                .repeatForever(autoreverses: false)
            ) {
                sparklePhase = 1.0
            }
        }
    }

    // MARK: - Computed Properties

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .white
        } else {
            return Theme.Colors.textPrimary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Theme.Colors.accent
        } else if isToday {
            return .blue
        } else if hasHighlight {
            return Color.clear
        } else {
            return Color.clear
        }
    }

    private var moodGlowColor: Color {
        switch moodEmoji {
        case "😊", "🙂", "😌":
            return .yellow
        case "🤩", "🥳", "😍":
            return .pink
        case "😴", "😪", "🥱":
            return .purple
        case "😤", "😠", "😡":
            return .red
        case "😢", "😭", "🥺":
            return .blue
        case "🧘", "☮️", "🙏":
            return .green
        default:
            return .orange
        }
    }

    private var eventBadgeColor: Color {
        if isSelected || isToday {
            return Theme.Colors.accent
        } else {
            return Theme.Colors.primary
        }
    }
}

// MARK: - Sparkle Overlay

/// Animated sparkle particles for highlight days
struct SparkleOverlay: View {
    let phase: CGFloat

    private let sparkleCount = 6

    var body: some View {
        ZStack {
            ForEach(0..<sparkleCount, id: \.self) { index in
                SparkleParticle(
                    index: index,
                    total: sparkleCount,
                    phase: phase
                )
            }
        }
    }
}

struct SparkleParticle: View {
    let index: Int
    let total: Int
    let phase: CGFloat

    private var angle: Double {
        (Double(index) / Double(total)) * 360 + (phase * 360)
    }

    private var radius: CGFloat {
        24 + sin(phase * .pi * 2 + Double(index)) * 4
    }

    private var opacity: Double {
        let baseOpacity = 0.6
        let variation = sin(phase * .pi * 4 + Double(index) * 0.5) * 0.4
        return max(0, baseOpacity + variation)
    }

    private var scale: CGFloat {
        let baseScale: CGFloat = 0.8
        let variation = CGFloat(sin(phase * .pi * 3 + Double(index))) * 0.4
        return baseScale + variation
    }

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(
                x: cos(angle * .pi / 180) * radius,
                y: sin(angle * .pi / 180) * radius
            )
    }
}

// MARK: - Previews

#Preview("Regular Day") {
    HStack {
        DayCell(
            date: Date(),
            isSelected: false,
            isToday: false,
            hasHighlight: false,
            moodEmoji: nil,
            eventCount: 0
        )

        DayCell(
            date: Date(),
            isSelected: false,
            isToday: false,
            hasHighlight: false,
            moodEmoji: nil,
            eventCount: 3
        )
    }
    .padding()
}

#Preview("Today with Pulse") {
    DayCell(
        date: Date(),
        isSelected: false,
        isToday: true,
        hasHighlight: false,
        moodEmoji: nil,
        eventCount: 2
    )
    .padding()
}

#Preview("Highlight with Mood Ring") {
    HStack {
        DayCell(
            date: Date(),
            isSelected: false,
            isToday: false,
            hasHighlight: true,
            moodEmoji: "🤩",
            eventCount: 1
        )

        DayCell(
            date: Date(),
            isSelected: false,
            isToday: false,
            hasHighlight: true,
            moodEmoji: "😊",
            eventCount: 0
        )

        DayCell(
            date: Date(),
            isSelected: false,
            isToday: false,
            hasHighlight: true,
            moodEmoji: "😢",
            eventCount: 2
        )
    }
    .padding()
}

#Preview("Selected Day") {
    DayCell(
        date: Date(),
        isSelected: true,
        isToday: false,
        hasHighlight: true,
        moodEmoji: "😊",
        eventCount: 4
    )
    .padding()
}

#Preview("Today with Highlight") {
    DayCell(
        date: Date(),
        isSelected: false,
        isToday: true,
        hasHighlight: true,
        moodEmoji: "🥳",
        eventCount: 3
    )
    .padding()
}

#Preview("Calendar Week Row") {
    HStack(spacing: 0) {
        DayCell(date: Date(), isSelected: false, isToday: false, hasHighlight: false, moodEmoji: nil, eventCount: 0)
        DayCell(date: Date(), isSelected: false, isToday: false, hasHighlight: true, moodEmoji: "😊", eventCount: 1)
        DayCell(date: Date(), isSelected: false, isToday: true, hasHighlight: false, moodEmoji: nil, eventCount: 2)
        DayCell(date: Date(), isSelected: true, isToday: false, hasHighlight: true, moodEmoji: "🤩", eventCount: 3)
        DayCell(date: Date(), isSelected: false, isToday: false, hasHighlight: false, moodEmoji: nil, eventCount: 0)
        DayCell(date: Date(), isSelected: false, isToday: false, hasHighlight: true, moodEmoji: "😴", eventCount: 0)
        DayCell(date: Date(), isSelected: false, isToday: false, hasHighlight: false, moodEmoji: nil, eventCount: 5)
    }
    .padding()
}
