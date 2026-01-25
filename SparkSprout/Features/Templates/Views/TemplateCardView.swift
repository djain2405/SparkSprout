//
//  TemplateCardView.swift
//  SparkSprout
//
//  Card component for displaying template options
//

import SwiftUI

struct TemplateCardView: View {
    let template: Template
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 60, height: 60)

                    Image(systemName: template.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(iconColor)
                }

                // Name
                VStack(spacing: 4) {
                    Text(template.displayName)
                        .font(Theme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(template.durationFormatted)
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: Theme.Shadow.small.color,
                radius: Theme.Shadow.small.radius,
                x: Theme.Shadow.small.x,
                y: Theme.Shadow.small.y
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        Color(adaptiveHex: template.color).opacity(0.2)
    }

    private var iconColor: Color {
        Color(adaptiveHex: template.color)
    }
}

// MARK: - Preview
#Preview {
    let templates = Template.defaultTemplates

    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(templates) { template in
                TemplateCardView(
                    template: template,
                    onTap: { print("Tapped: \(template.name)") }
                )
            }
        }
        .padding()
    }
}

#Preview("Selected") {
    TemplateCardView(
        template: Template.defaultTemplates[0],
        isSelected: true
    )
    .padding()
}
