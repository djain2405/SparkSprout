//
//  MilestoneBadge.swift
//  SparkSprout
//
//  Animated milestone achievement badge with confetti overlay
//  Displays when users reach significant milestones
//

import SwiftUI

struct MilestoneBadge: View {
    let milestone: Milestone
    let show: Bool

    @State private var scale: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Confetti overlay
            if showConfetti {
                ConfettiView(trigger: showConfetti)
            }

            // Badge content
            VStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(milestone.gradient)
                        .frame(width: 100, height: 100)
                        .shadow(
                            color: milestone.color.opacity(0.5),
                            radius: 16,
                            x: 0,
                            y: 8
                        )

                    Image(systemName: milestone.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))

                // Title
                Text(milestone.title)
                    .font(Theme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Colors.textPrimary)

                // Description
                Text(milestone.description)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.xl)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
            .shadow(
                color: Theme.Shadow.large.color,
                radius: Theme.Shadow.large.radius,
                x: Theme.Shadow.large.x,
                y: Theme.Shadow.large.y
            )
            .scaleEffect(scale)
        }
        .onChange(of: show) { oldValue, newValue in
            if newValue {
                presentBadge()
            }
        }
    }

    private func presentBadge() {
        // Bouncy scale entrance
        withAnimation(Theme.Animation.bouncy) {
            scale = 1.0
        }

        // Rotation wiggle effect
        withAnimation(Theme.Animation.wiggle.delay(0.3)) {
            rotation = 5
        }

        // Trigger confetti after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showConfetti = true
        }

        // Haptic celebration
        Theme.Haptics.celebration()
    }
}

// MARK: - Milestone Model

enum Milestone {
    case firstHighlight
    case weekStreak
    case twoWeekStreak
    case monthStreak
    case hundredDays

    var title: String {
        switch self {
        case .firstHighlight:
            return "First Highlight!"
        case .weekStreak:
            return "7-Day Streak!"
        case .twoWeekStreak:
            return "14-Day Streak!"
        case .monthStreak:
            return "30-Day Streak!"
        case .hundredDays:
            return "100 Days!"
        }
    }

    var description: String {
        switch self {
        case .firstHighlight:
            return "You've added your first highlight! Keep tracking your best moments."
        case .weekStreak:
            return "Amazing! You've been consistent for a whole week."
        case .twoWeekStreak:
            return "Two weeks of daily highlights! You're on fire!"
        case .monthStreak:
            return "Incredible! A full month of tracking your highlights."
        case .hundredDays:
            return "Wow! 100 days of capturing your best moments. You're a legend!"
        }
    }

    var icon: String {
        switch self {
        case .firstHighlight:
            return "star.fill"
        case .weekStreak:
            return "flame.fill"
        case .twoWeekStreak:
            return "bolt.fill"
        case .monthStreak:
            return "trophy.fill"
        case .hundredDays:
            return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstHighlight:
            return .yellow
        case .weekStreak:
            return .orange
        case .twoWeekStreak:
            return .red
        case .monthStreak:
            return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case .hundredDays:
            return .purple
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .firstHighlight:
            return Theme.Gradients.sunsetOrange
        case .weekStreak:
            return Theme.Gradients.sunsetOrange
        case .twoWeekStreak:
            return Theme.Gradients.gold
        case .monthStreak:
            return Theme.Gradients.gold
        case .hundredDays:
            return Theme.Gradients.celebration
        }
    }

    /// Check if a streak count should trigger this milestone
    static func fromStreakCount(_ count: Int) -> Milestone? {
        switch count {
        case 7:
            return .weekStreak
        case 14:
            return .twoWeekStreak
        case 30:
            return .monthStreak
        case 100:
            return .hundredDays
        default:
            return nil
        }
    }
}

// MARK: - Milestone Overlay Modifier

extension View {
    func milestoneOverlay(milestone: Milestone?, isPresented: Binding<Bool>) -> some View {
        self.overlay {
            if let milestone = milestone, isPresented.wrappedValue {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented.wrappedValue = false
                        }

                    MilestoneBadge(milestone: milestone, show: isPresented.wrappedValue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct MilestonePreview: View {
        @State private var showBadge = false
        @State private var currentMilestone: Milestone = .weekStreak

        var body: some View {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Milestone Badges")
                        .font(Theme.Typography.title)

                    // Milestone selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Milestone:")
                            .font(Theme.Typography.headline)

                        ForEach([
                            Milestone.firstHighlight,
                            .weekStreak,
                            .twoWeekStreak,
                            .monthStreak,
                            .hundredDays
                        ], id: \.title) { milestone in
                            Button(action: {
                                currentMilestone = milestone
                            }) {
                                HStack {
                                    Image(systemName: milestone.icon)
                                    Text(milestone.title)
                                    Spacer()
                                    if currentMilestone.title == milestone.title {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                            .foregroundStyle(Theme.Colors.textPrimary)
                        }
                    }
                    .padding()

                    Button("Show Milestone") {
                        showBadge = true
                    }
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Theme.Colors.accent)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                .padding()
            }
            .milestoneOverlay(milestone: currentMilestone, isPresented: $showBadge)
        }
    }

    return MilestonePreview()
}
