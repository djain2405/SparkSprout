//
//  AdaptiveGradientBackground.swift
//  SparkSprout
//
//  Adaptive gradient background that adjusts for dark mode
//

import SwiftUI

struct AdaptiveGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            // Darker, more subtle gradient for dark mode
            return [
                Color.blue.opacity(0.15),
                Color.purple.opacity(0.15)
            ]
        } else {
            // Lighter gradient for light mode
            return [
                Color.blue.opacity(0.08),
                Color.purple.opacity(0.08)
            ]
        }
    }
}

#Preview("Light Mode") {
    AdaptiveGradientBackground()
        .frame(height: 100)
        .cornerRadius(12)
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    AdaptiveGradientBackground()
        .frame(height: 100)
        .cornerRadius(12)
        .padding()
        .preferredColorScheme(.dark)
}
