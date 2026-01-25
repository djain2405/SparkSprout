//
//  AdaptiveColor.swift
//  SparkSprout
//
//  Helper extension for dark mode adaptive colors
//

import SwiftUI
import UIKit

extension Color {
    /// Initialize color from hex string with automatic dark mode variant
    /// Automatically adjusts brightness for dark mode
    init(adaptiveHex hex: String, darkModeAdjustment: Double = 0.3) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            self.init(.gray)
            return
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        // Create light and dark variants
        let lightColor = Color(red: r, green: g, blue: b)

        // Increase brightness for dark mode
        let darkR = min(1.0, r + darkModeAdjustment)
        let darkG = min(1.0, g + darkModeAdjustment)
        let darkB = min(1.0, b + darkModeAdjustment)
        let darkColor = Color(red: darkR, green: darkG, blue: darkB)

        self.init(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(darkColor)
            } else {
                return UIColor(lightColor)
            }
        })
    }

    /// Creates an adaptive color that works in both light and dark modes
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(dark)
            } else {
                return UIColor(light)
            }
        })
    }

    /// Get lighter version of color for dark mode backgrounds
    func opacity(light: Double, dark: Double) -> some View {
        modifier(AdaptiveOpacityModifier(lightOpacity: light, darkOpacity: dark, color: self))
    }
}

// MARK: - Adaptive Opacity Modifier
private struct AdaptiveOpacityModifier: ViewModifier {
    let lightOpacity: Double
    let darkOpacity: Double
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(color.opacity(colorScheme == .dark ? darkOpacity : lightOpacity))
    }
}

// MARK: - Adaptive Gradient
extension LinearGradient {
    /// Creates a gradient that adapts to dark mode
    static func adaptive(
        lightColors: [Color],
        darkColors: [Color],
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing
    ) -> some View {
        AdaptiveGradientView(
            lightColors: lightColors,
            darkColors: darkColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

private struct AdaptiveGradientView: View {
    let lightColors: [Color]
    let darkColors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? darkColors : lightColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}
