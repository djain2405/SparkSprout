//
//  AttendeeListView.swift
//  SparkSprout
//
//  UI component for displaying and managing event attendees
//

import SwiftUI

struct AttendeeListView: View {
    @Binding var selectedContacts: [SelectedContact]
    @State private var showingContactPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with add button
            HStack {
                Label("Attendees", systemImage: "person.2")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Button(action: { showingContactPicker = true }) {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.blue)
                }
            }

            // List of selected contacts
            if selectedContacts.isEmpty {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text("Tap Add to invite people")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(.vertical, Theme.Spacing.sm)
            } else {
                VStack(spacing: Theme.Spacing.xs) {
                    ForEach(selectedContacts) { contact in
                        attendeeRow(for: contact)
                    }
                }
            }
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView(selectedContacts: $selectedContacts)
        }
    }

    // MARK: - Attendee Row

    private func attendeeRow(for contact: SelectedContact) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Avatar
            Circle()
                .fill(avatarColor(for: contact.name))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(initials(for: contact.name))
                        .font(Theme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                )

            // Name and contact info
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: contact.hasEmail ? "envelope" : "phone")
                        .font(.caption2)
                    Text(contact.displayContact)
                        .font(Theme.Typography.caption)
                }
                .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            // Warning if no email (calendar invites work best with email)
            if !contact.hasEmail {
                Image(systemName: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .help("No email address - calendar invite may not work")
            }

            // Remove button
            Button(action: { removeContact(contact) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Helpers

    private func removeContact(_ contact: SelectedContact) {
        withAnimation {
            selectedContacts.removeAll { $0.id == contact.id }
        }
    }

    private func initials(for name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func avatarColor(for name: String) -> Color {
        // Generate a consistent color based on the name
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo]
        let hash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[hash % colors.count]
    }
}

// MARK: - Preview

#Preview("With Attendees") {
    struct PreviewWrapper: View {
        @State private var contacts: [SelectedContact] = [
            SelectedContact(identifier: "1", name: "Sarah Johnson", email: "sarah@example.com", phoneNumber: nil),
            SelectedContact(identifier: "2", name: "Mike Chen", email: nil, phoneNumber: "+1 555-123-4567"),
            SelectedContact(identifier: "3", name: "Emily Davis", email: "emily.davis@work.com", phoneNumber: "+1 555-987-6543")
        ]

        var body: some View {
            Form {
                Section {
                    AttendeeListView(selectedContacts: $contacts)
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Empty") {
    struct PreviewWrapper: View {
        @State private var contacts: [SelectedContact] = []

        var body: some View {
            Form {
                Section {
                    AttendeeListView(selectedContacts: $contacts)
                }
            }
        }
    }

    return PreviewWrapper()
}
