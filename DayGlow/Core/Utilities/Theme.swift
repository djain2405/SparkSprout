//
//  Theme.swift
//  DayGlow
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
