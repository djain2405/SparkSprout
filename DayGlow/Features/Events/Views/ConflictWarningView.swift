//
//  ConflictWarningView.swift
//  DayGlow
//
//  Warning view for event scheduling conflicts
//

import SwiftUI

struct ConflictWarningView: View {
    let conflicts: [ConflictDetector.Conflict]
    let onKeepAnyway: () -> Void
    let onAdjustTime: () -> Void
    let onMarkFlexible: () -> Void
    let onCancel: () -> Void

    private var primaryConflict: ConflictDetector.Conflict? {
        conflicts.first
    }

    private var severityColor: Color {
        guard let conflict = primaryConflict else { return .gray }

        switch conflict.severity {
        case .hard: return .red
        case .soft: return .orange
        case .adjacent: return .blue
        }
    }

    private var severityIcon: String {
        guard let conflict = primaryConflict else { return "exclamationmark.triangle" }

        switch conflict.severity {
        case .hard: return "exclamationmark.octagon.fill"
        case .soft: return "exclamationmark.triangle.fill"
        case .adjacent: return "info.circle.fill"
        }
    }

    private var title: String {
        guard let conflict = primaryConflict else { return "Scheduling Conflict" }

        switch conflict.severity {
        case .hard: return "You're Double-Booked!"
        case .soft: return "You're Tight Here"
        case .adjacent: return "Back-to-Back Schedule"
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon and title
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: severityIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(severityColor)

                Text(title)
                    .font(Theme.Typography.title2)
                    .fontWeight(.bold)
            }

            // Conflict list
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(Array(conflicts.enumerated()), id: \.offset) { index, conflict in
                    conflictRow(conflict: conflict)

                    if index < conflicts.count - 1 {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)

            // Action buttons
            VStack(spacing: Theme.Spacing.sm) {
                // Keep anyway button
                Button(action: onKeepAnyway) {
                    Text("Keep Anyway")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(severityColor)
                        .cornerRadius(Theme.CornerRadius.medium)
                }

                // Adjust time button
                Button(action: onAdjustTime) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Adjust Time")
                    }
                    .font(Theme.Typography.body)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                }

                // Mark as flexible button
                Button(action: onMarkFlexible) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                        Text("Mark as Flexible")
                    }
                    .font(Theme.Typography.body)
                    .foregroundStyle(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                }

                // Cancel button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Conflict Row
    @ViewBuilder
    private func conflictRow(conflict: ConflictDetector.Conflict) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Severity indicator
            Circle()
                .fill(severityColorFor(conflict.severity))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(conflict.event.title)
                    .font(Theme.Typography.subheadline)
                    .fontWeight(.medium)

                Text(conflict.event.timeRangeFormatted)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text(conflict.description)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(severityColorFor(conflict.severity))
            }

            Spacer()
        }
    }

    private func severityColorFor(_ severity: ConflictDetector.ConflictSeverity) -> Color {
        switch severity {
        case .hard: return .red
        case .soft: return .orange
        case .adjacent: return .blue
        }
    }
}

// MARK: - Preview
#Preview {
    let conflicts = [
        ConflictDetector.Conflict(
            event: Event(
                title: "Team Meeting",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600)
            ),
            severity: .hard
        ),
        ConflictDetector.Conflict(
            event: Event(
                title: "Lunch",
                startDate: Date().addingTimeInterval(7200),
                endDate: Date().addingTimeInterval(9000)
            ),
            severity: .adjacent
        )
    ]

    return ConflictWarningView(
        conflicts: conflicts,
        onKeepAnyway: { print("Keep anyway") },
        onAdjustTime: { print("Adjust time") },
        onMarkFlexible: { print("Mark flexible") },
        onCancel: { print("Cancel") }
    )
}
