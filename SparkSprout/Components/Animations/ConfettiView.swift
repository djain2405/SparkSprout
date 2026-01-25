//
//  ConfettiView.swift
//  SparkSprout
//
//  Confetti particle explosion animation for celebrations and milestones
//  Triggers on milestone achievements (streaks, highlights, etc.)
//

import SwiftUI

struct ConfettiView: View {
    let trigger: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiParticleView(particle: particle, isAnimating: isAnimating)
            }
        }
        .onChange(of: trigger) { oldValue, newValue in
            if newValue {
                explode()
            }
        }
    }

    private func explode() {
        // Generate 50 particles
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: -400...0),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5),
                color: randomColor(),
                shape: randomShape()
            )
        }

        // Trigger multi-haptic feedback
        Theme.Haptics.celebration()

        // Start animation
        withAnimation(Theme.Animation.confetti) {
            isAnimating = true
        }

        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isAnimating = false
                particles = []
            }
        }
    }

    private func randomColor() -> Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink,
            Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        ]
        return colors.randomElement() ?? .blue
    }

    private func randomShape() -> ConfettiShape {
        ConfettiShape.allCases.randomElement() ?? .circle
    }
}

// MARK: - Confetti Particle Model

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let color: Color
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case circle
    case square
    case triangle
    case star
}

// MARK: - Particle View

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let isAnimating: Bool

    var body: some View {
        shapeView
            .frame(width: 10, height: 10)
            .scaleEffect(isAnimating ? particle.scale : 0)
            .rotationEffect(Angle(degrees: isAnimating ? particle.rotation : 0))
            .offset(
                x: isAnimating ? particle.x : 0,
                y: isAnimating ? particle.y : 0
            )
            .opacity(isAnimating ? 0 : 1)
    }

    @ViewBuilder
    private var shapeView: some View {
        switch particle.shape {
        case .circle:
            Circle()
                .fill(particle.color)
        case .square:
            Rectangle()
                .fill(particle.color)
        case .triangle:
            Triangle()
                .fill(particle.color)
        case .star:
            Star()
                .fill(particle.color)
        }
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let pointCount = 5

        for i in 0..<pointCount * 2 {
            let angle = (Double(i) * .pi / Double(pointCount)) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    struct ConfettiPreview: View {
        @State private var showConfetti = false

        var body: some View {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 40) {
                    Button("Trigger Confetti") {
                        showConfetti.toggle()
                    }
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Theme.Colors.accent)
                    .cornerRadius(Theme.CornerRadius.medium)

                    Text("Tap the button to see confetti!")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                ConfettiView(trigger: showConfetti)
            }
        }
    }

    return ConfettiPreview()
}
