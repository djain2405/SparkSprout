//
//  StreakIndicator.swift
//  DayGlow
//
//  Animated streak counter for daily highlights
//

import SwiftUI

struct StreakIndicator: View {
    let streak: Int
    let encouragementMessage: String?
    var showAnimation: Bool = true

    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(streakEmoji)
                    .font(.title)
                    .scaleEffect(scale)

                Text("\(streak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.orange)

                Text("day\(streak == 1 ? "" : "s")")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            if let message = encouragementMessage {
                Text(message)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(streakBackgroundColor)
        .cornerRadius(Theme.CornerRadius.medium)
        .onAppear {
            if showAnimation {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).repeatCount(3, autoreverses: true)) {
                    scale = 1.2
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var streakEmoji: String {
        if streak >= 30 {
            return "🔥🔥🔥"
        } else if streak >= 14 {
            return "🔥🔥"
        } else if streak >= 7 {
            return "🔥"
        } else if streak >= 3 {
            return "⭐️"
        } else if streak > 0 {
            return "✨"
        } else {
            return "💫"
        }
    }

    private var streakBackgroundColor: Color {
        if streak >= 7 {
            return .orange.opacity(0.1)
        } else if streak >= 3 {
            return .yellow.opacity(0.1)
        } else {
            return Theme.Colors.cardBackground
        }
    }
}

// MARK: - Compact Version
struct CompactStreakIndicator: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(streakEmoji)
                .font(.caption)

            Text("\(streak)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var streakEmoji: String {
        if streak >= 7 {
            return "🔥"
        } else if streak >= 3 {
            return "⭐️"
        } else {
            return "✨"
        }
    }
}

// MARK: - Preview
#Preview("Streak 0") {
    StreakIndicator(
        streak: 0,
        encouragementMessage: "Start your streak today!",
        showAnimation: false
    )
    .padding()
}

#Preview("Streak 5") {
    StreakIndicator(
        streak: 5,
        encouragementMessage: "You're on a roll! 2 more days to a week!",
        showAnimation: false
    )
    .padding()
}

#Preview("Streak 14") {
    StreakIndicator(
        streak: 14,
        encouragementMessage: "Amazing streak! 16 more to hit 30 days!",
        showAnimation: false
    )
    .padding()
}

#Preview("Streak 30+") {
    StreakIndicator(
        streak: 35,
        encouragementMessage: "Incredible! You're a highlight champion! 🏆",
        showAnimation: false
    )
    .padding()
}

#Preview("Compact") {
    VStack(spacing: 16) {
        CompactStreakIndicator(streak: 0)
        CompactStreakIndicator(streak: 3)
        CompactStreakIndicator(streak: 7)
        CompactStreakIndicator(streak: 15)
    }
    .padding()
}
