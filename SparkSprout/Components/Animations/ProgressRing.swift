//
//  ProgressRing.swift
//  SparkSprout
//
//  Animated circular progress ring with spring animation
//  Used in stats display for streaks and achievements
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let color: Color
    let showGlow: Bool

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        color: Color = Theme.Colors.primary,
        showGlow: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.color = color
        self.showGlow = showGlow
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: showGlow ? color.opacity(0.6) : .clear,
                    radius: 8,
                    x: 0,
                    y: 0
                )
        }
        .onAppear {
            withAnimation(Theme.Animation.bouncy.delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(Theme.Animation.bouncy) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Stat Ring with Value

struct StatRing: View {
    let value: String
    let label: String
    let progress: Double
    let color: Color
    let icon: String?

    init(
        value: String,
        label: String,
        progress: Double,
        color: Color,
        icon: String? = nil
    ) {
        self.value = value
        self.label = label
        self.progress = progress
        self.color = color
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ProgressRing(
                    progress: progress,
                    lineWidth: 8,
                    color: color
                )
                .frame(width: 80, height: 80)

                VStack(spacing: 2) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundStyle(color)
                    }
                    Text(value)
                        .font(Theme.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }

            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

// MARK: - Gradient Progress Ring

struct GradientProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient
    let showGlow: Bool

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        gradient: LinearGradient = Theme.Gradients.purpleBlue,
        showGlow: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.showGlow = showGlow
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: lineWidth
                )

            // Gradient progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: showGlow ? Color.blue.opacity(0.4) : .clear,
                    radius: 8,
                    x: 0,
                    y: 0
                )
        }
        .onAppear {
            withAnimation(Theme.Animation.bouncy.delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(Theme.Animation.bouncy) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Preview

#Preview("Progress Rings") {
    ScrollView {
        VStack(spacing: 40) {
            Text("Progress Rings")
                .font(Theme.Typography.title)

            // Basic progress ring
            VStack(spacing: 16) {
                Text("Basic Ring")
                    .font(Theme.Typography.headline)

                ProgressRing(
                    progress: 0.75,
                    color: .blue
                )
                .frame(width: 120, height: 120)
            }

            // Stat rings
            VStack(spacing: 16) {
                Text("Stat Rings")
                    .font(Theme.Typography.headline)

                HStack(spacing: 24) {
                    StatRing(
                        value: "7",
                        label: "Day Streak",
                        progress: 0.7,
                        color: .orange,
                        icon: "flame.fill"
                    )

                    StatRing(
                        value: "42",
                        label: "Total Days",
                        progress: 0.84,
                        color: .yellow,
                        icon: "star.fill"
                    )

                    StatRing(
                        value: "14",
                        label: "Best Streak",
                        progress: 1.0,
                        color: Color(red: 1.0, green: 0.84, blue: 0.0),
                        icon: "trophy.fill"
                    )
                }
            }

            // Gradient ring
            VStack(spacing: 16) {
                Text("Gradient Ring")
                    .font(Theme.Typography.headline)

                GradientProgressRing(
                    progress: 0.65,
                    gradient: Theme.Gradients.purpleBlue
                )
                .frame(width: 120, height: 120)
            }
        }
        .padding()
    }
}
