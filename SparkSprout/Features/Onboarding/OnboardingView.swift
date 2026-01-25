//
//  OnboardingView.swift
//  SparkSprout
//
//  Main onboarding container with swipeable pages and skip functionality
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showConfetti = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let totalPages = 3

    var body: some View {
        ZStack {
            // Main onboarding content
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: skipOnboarding) {
                        Text("Skip")
                            .font(Theme.Typography.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                    }
                }
                .padding(.top, Theme.Spacing.lg)
                .padding(.trailing, Theme.Spacing.md)

                // Pages
                TabView(selection: $currentPage) {
                    // Page 1: Intentional Planning
                    OnboardingPageView(
                        icon: "sparkles",
                        title: "Plan with Purpose",
                        description: "Use templates and smart scheduling to design days that align with your values. Conflict detection helps you stay balanced.",
                        gradient: Theme.Gradients.purpleBlue
                    )
                    .tag(0)

                    // Page 2: Daily Gratitude
                    OnboardingPageView(
                        icon: "heart.fill",
                        title: "Capture What Matters",
                        description: "Reflect on your highlights each day. What made you smile? Who made a difference? Build a timeline of gratitude.",
                        gradient: Theme.Gradients.sunsetOrange
                    )
                    .tag(1)

                    // Page 3: Build Consistency
                    OnboardingPageView(
                        icon: "flame.fill",
                        title: "Grow Your Streak",
                        description: "Track consecutive days with highlights. Celebrate milestones with confetti and encouragement. Small steps, big impact.",
                        gradient: Theme.Gradients.gold
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .onChange(of: currentPage) { oldValue, newValue in
                    // Haptic feedback on page change
                    Theme.Haptics.light()
                }

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView(trigger: showConfetti)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            if currentPage < totalPages - 1 {
                // Next button
                Button(action: nextPage) {
                    Text("Next")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(Theme.CornerRadius.medium)
                }
            } else {
                // Get Started button
                Button(action: completeOnboarding) {
                    Text("Get Started")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(Theme.CornerRadius.medium)
                }
            }
        }
    }

    // MARK: - Actions

    private func nextPage() {
        withAnimation(Theme.Animation.spring) {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
        Theme.Haptics.light()
    }

    private func skipOnboarding() {
        hasCompletedOnboarding = true
        Theme.Haptics.success()
    }

    private func completeOnboarding() {
        // Show confetti
        showConfetti = true
        Theme.Haptics.celebration()

        // Mark onboarding as complete after confetti animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
