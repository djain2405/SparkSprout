//
//  StreakIndicator.swift
//  SparkSprout
//
//  Animated streak counter for daily highlights
//

import SwiftUI

struct StreakIndicator: View {
    let streak: Int
    let encouragementMessage: String?
    var showAnimation: Bool = true

    @State private var scale: CGFloat = 1.0
    @State private var emojiGlow: CGFloat = 0
    @State private var showMilestoneConfetti = false

    var body: some View {
        ZStack {
            // Confetti overlay for milestones
            if showMilestoneConfetti {
                ConfettiView(trigger: showMilestoneConfetti)
            }

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    // Animated flame emoji with glow
                    Text(streakEmoji)
                        .font(.title)
                        .scaleEffect(scale)
                        .shadow(
                            color: streakGlowColor.opacity(emojiGlow),
                            radius: 12,
                            x: 0,
                            y: 0
                        )

                    // Streak count with gradient for high streaks
                    if streak >= 7 {
                        Text("\(streak)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(Theme.Gradients.gold)
                    } else {
                        Text("\(streak)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.orange)
                    }

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
            .background(streakBackgroundGradient)
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .onAppear {
            if showAnimation {
                // Continuous pulse animation
                withAnimation(Theme.Animation.pulse) {
                    scale = 1.2
                }

                // Glow pulse
                withAnimation(Theme.Animation.pulse) {
                    emojiGlow = 0.8
                }

                // Check for milestone confetti
                checkForMilestone()
            }
        }
        .onChange(of: streak) { oldValue, newValue in
            if newValue > oldValue {
                checkForMilestone()
            }
        }
    }

    // MARK: - Methods

    private func checkForMilestone() {
        if let _ = Milestone.fromStreakCount(streak) {
            // Trigger confetti for milestones
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showMilestoneConfetti = true
                Theme.Haptics.celebration()
            }

            // Reset confetti after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                showMilestoneConfetti = false
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

    private var streakBackgroundGradient: some ShapeStyle {
        if streak >= 30 {
            // Rainbow gradient for 30+ day streaks
            return AnyShapeStyle(Theme.Gradients.celebration.opacity(0.2))
        } else if streak >= 7 {
            // Gold gradient for 7+ day streaks
            return AnyShapeStyle(Theme.Gradients.gold.opacity(0.15))
        } else if streak >= 3 {
            return AnyShapeStyle(Color.yellow.opacity(0.1))
        } else {
            return AnyShapeStyle(Theme.Colors.cardBackground)
        }
    }

    private var streakGlowColor: Color {
        if streak >= 30 {
            return .purple
        } else if streak >= 14 {
            return .red
        } else if streak >= 7 {
            return .orange
        } else {
            return .yellow
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
