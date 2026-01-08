//
//  OnboardingPageView.swift
//  DayGlow
//
//  Reusable onboarding page component with icon, title, and description
//

import SwiftUI

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
    let additionalContent: AnyView?

    init(
        icon: String,
        title: String,
        description: String,
        gradient: LinearGradient,
        additionalContent: AnyView? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.gradient = gradient
        self.additionalContent = additionalContent
    }

    var body: some View {
        ZStack {
            // Gradient background
            gradient
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .shadow(
                        color: .black.opacity(0.2),
                        radius: 8,
                        x: 0,
                        y: 4
                    )

                // Title
                Text(title)
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Description
                Text(description)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .fixedSize(horizontal: false, vertical: true)

                // Additional content (e.g., buttons on final page)
                if let content = additionalContent {
                    content
                        .padding(.top, Theme.Spacing.lg)
                }

                Spacer()
            }
            .padding(Theme.Spacing.lg)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingPageView(
        icon: "calendar.badge.plus",
        title: "Plan with Purpose",
        description: "Use templates and smart scheduling to design days that align with your values. Conflict detection helps you stay balanced.",
        gradient: Theme.Gradients.purpleBlue
    )
}
