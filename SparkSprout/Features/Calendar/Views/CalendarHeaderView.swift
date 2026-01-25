//
//  CalendarHeaderView.swift
//  SparkSprout
//
//  Calendar header with month/year display and navigation buttons
//

import SwiftUI

struct CalendarHeaderView: View {
    let currentMonth: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Previous month button
            Button(action: onPrevious) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Spacer()

            // Current month and year
            VStack(spacing: 4) {
                Text(currentMonth)
                    .font(Theme.Typography.title2)
                    .fontWeight(.bold)

                // Today button (small)
                Button(action: onToday) {
                    Text("Today")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Next month button
            Button(action: onNext) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        CalendarHeaderView(
            currentMonth: "January 2026",
            onPrevious: { print("Previous") },
            onNext: { print("Next") },
            onToday: { print("Today") }
        )

        Spacer()
    }
}
