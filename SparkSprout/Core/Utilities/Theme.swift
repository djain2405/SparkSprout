//
//  Theme.swift
//  SparkSprout
//
//  Design system with colors, typography, spacing, and corner radius constants
//

import SwiftUI

struct Theme {
    // MARK: - Colors
    struct Colors {
        // Primary brand colors
        static let primary = Color(red: 0.4, green: 0.5, blue: 1.0)
        static let accent = Color(red: 1.0, green: 0.6, blue: 0.2)
        static let background = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)

        // Semantic colors
        static let conflictHard = Color.red
        static let conflictSoft = Color.orange
        static let conflictAdjacent = Color.blue
        static let highlight = Color.yellow
        static let streakGold = Color(red: 1.0, green: 0.84, blue: 0.0)

        // Text colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabel)

        // Calendar colors
        static let calendarToday = Color.blue.opacity(0.1)
        static let calendarSelected = accent
        static let eventDot = primary
    }

    // MARK: - Gradients
    struct Gradients {
        /// Purple to blue gradient for stats header
        static let purpleBlue = LinearGradient(
            colors: [
                Color(red: 0.5, green: 0.3, blue: 0.9),
                Color(red: 0.3, green: 0.5, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Gold gradient for streaks and achievements
        static let gold = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.0),
                Color(red: 1.0, green: 0.65, blue: 0.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Sunset orange gradient for highlights
        static let sunsetOrange = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.6, blue: 0.2),
                Color(red: 1.0, green: 0.4, blue: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Dynamic event density gradient for calendar heatmap
        /// - Parameter intensity: 0.0 (no events) to 1.0 (many events)
        static func eventDensity(intensity: Double) -> LinearGradient {
            let clampedIntensity = max(0.0, min(1.0, intensity))

            if clampedIntensity == 0.0 {
                return LinearGradient(
                    colors: [Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            let baseColor = Color(red: 0.4, green: 0.5, blue: 1.0)
            let intensityColor = baseColor.opacity(0.35 + (clampedIntensity * 0.5))

            return LinearGradient(
                colors: [intensityColor, intensityColor.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        /// Celebration gradient with rainbow colors
        static let celebration = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.3, blue: 0.3),
                Color(red: 1.0, green: 0.8, blue: 0.2),
                Color(red: 0.3, green: 0.9, blue: 0.3),
                Color(red: 0.3, green: 0.6, blue: 1.0),
                Color(red: 0.7, green: 0.3, blue: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// Mood-based gradient for highlight rings
        /// Maps mood emoji to appropriate color gradients
        static func moodGradient(for emoji: String?) -> AngularGradient {
            let colors: [Color]

            switch emoji {
            case "😊", "🙂", "😌":
                // Happy/content - warm yellows and oranges
                colors = [
                    Color(red: 1.0, green: 0.85, blue: 0.3),
                    Color(red: 1.0, green: 0.65, blue: 0.2),
                    Color(red: 1.0, green: 0.85, blue: 0.3)
                ]
            case "🤩", "🥳", "😍":
                // Excited/in love - vibrant pinks and purples
                colors = [
                    Color(red: 1.0, green: 0.4, blue: 0.6),
                    Color(red: 0.8, green: 0.3, blue: 0.9),
                    Color(red: 1.0, green: 0.4, blue: 0.6)
                ]
            case "😴", "😪", "🥱":
                // Tired - soft blues and purples
                colors = [
                    Color(red: 0.5, green: 0.5, blue: 0.8),
                    Color(red: 0.6, green: 0.4, blue: 0.7),
                    Color(red: 0.5, green: 0.5, blue: 0.8)
                ]
            case "😤", "😠", "😡":
                // Angry - reds and oranges
                colors = [
                    Color(red: 1.0, green: 0.3, blue: 0.2),
                    Color(red: 0.9, green: 0.4, blue: 0.1),
                    Color(red: 1.0, green: 0.3, blue: 0.2)
                ]
            case "😢", "😭", "🥺":
                // Sad - blues and teals
                colors = [
                    Color(red: 0.3, green: 0.5, blue: 0.8),
                    Color(red: 0.2, green: 0.6, blue: 0.7),
                    Color(red: 0.3, green: 0.5, blue: 0.8)
                ]
            case "🧘", "☮️", "🙏":
                // Peaceful - greens and teals
                colors = [
                    Color(red: 0.4, green: 0.8, blue: 0.6),
                    Color(red: 0.3, green: 0.7, blue: 0.7),
                    Color(red: 0.4, green: 0.8, blue: 0.6)
                ]
            default:
                // Default highlight - golden gradient
                colors = [
                    Color(red: 1.0, green: 0.84, blue: 0.0),
                    Color(red: 1.0, green: 0.6, blue: 0.2),
                    Color(red: 1.0, green: 0.84, blue: 0.0)
                ]
            }

            return AngularGradient(
                colors: colors,
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        }
    }

    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let headline = Font.system(size: 20, weight: .semibold)
        static let subheadline = Font.system(size: 18, weight: .medium)
        static let body = Font.system(size: 16, weight: .regular)
        static let callout = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
        static let caption2 = Font.system(size: 12, weight: .regular)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    // MARK: - Shadows
    struct Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: 4.0, x: 0.0, y: 2.0)
        static let medium = (color: Color.black.opacity(0.15), radius: 8.0, x: 0.0, y: 4.0)
        static let large = (color: Color.black.opacity(0.2), radius: 16.0, x: 0.0, y: 8.0)
    }

    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)

        /// Bouncy spring animation with low damping for playful interactions
        static let bouncy = SwiftUI.Animation.spring(
            response: 0.4,
            dampingFraction: 0.5,
            blendDuration: 0
        )

        /// Continuous pulse animation for attention-grabbing elements
        static let pulse = SwiftUI.Animation
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)

        /// Staggered animation for list entrance effects
        /// - Parameters:
        ///   - index: Item index in the list
        ///   - total: Total number of items
        /// - Returns: Animation with calculated delay
        static func staggered(index: Int, total: Int) -> SwiftUI.Animation {
            let delay = Double(index) * 0.05
            return SwiftUI.Animation
                .spring(response: 0.4, dampingFraction: 0.7)
                .delay(delay)
        }

        /// Confetti celebration animation
        static let confetti = SwiftUI.Animation.spring(
            response: 0.6,
            dampingFraction: 0.4,
            blendDuration: 0
        )

        /// Wiggle rotation animation for playful feedback
        static let wiggle = SwiftUI.Animation
            .spring(response: 0.3, dampingFraction: 0.3)
            .repeatCount(3, autoreverses: true)
    }

    // MARK: - Haptics
    struct Haptics {
        /// Light haptic feedback for subtle interactions
        static func light() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        /// Success haptic feedback for completed actions
        static func success() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        /// Multi-haptic celebration for achievements and milestones
        static func celebration() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Add additional impacts for emphasis
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
        }

        /// Warning haptic for conflicts or errors
        static func warning() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }

        /// Error haptic for failures
        static func error() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - View Modifiers for Consistent Styling
extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(
                color: Theme.Shadow.small.color,
                radius: Theme.Shadow.small.radius,
                x: Theme.Shadow.small.x,
                y: Theme.Shadow.small.y
            )
    }

    func primaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.accent)
            .cornerRadius(Theme.CornerRadius.medium)
    }
}
