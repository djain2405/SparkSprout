//
//  HighlightCardView.swift
//  DayGlow
//
//  Card for adding/editing daily highlights
//

import SwiftUI
import SwiftData

struct HighlightCardView: View {
    let date: Date
    @Binding var dayEntry: DayEntry?

    @Environment(\.modelContext) private var modelContext

    @State private var highlightText: String = ""
    @State private var selectedEmoji: String? = nil
    @State private var isEditing: Bool = false
    @State private var showEmojiPicker: Bool = false
    @State private var showingDeleteConfirmation: Bool = false

    private var prompt: String {
        HighlightService.randomPrompt()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Today's Highlight")
                    .font(Theme.Typography.headline)

                Spacer()

                if dayEntry?.hasHighlight == true && !isEditing {
                    Button("Edit") {
                        isEditing = true
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.blue)

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .font(Theme.Typography.caption)
                }
            }

            if let entry = dayEntry, entry.hasHighlight && !isEditing {
                // Display mode
                displayView(entry: entry)
            } else {
                // Edit/Add mode
                editView
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .shadow(
            color: Theme.Shadow.small.color,
            radius: Theme.Shadow.small.radius,
            x: Theme.Shadow.small.x,
            y: Theme.Shadow.small.y
        )
        .onAppear {
            loadExistingHighlight()
        }
        .alert("Delete Highlight", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHighlight()
            }
        } message: {
            Text("Are you sure you want to delete this highlight? This action cannot be undone.")
        }
    }

    // MARK: - Display View
    @ViewBuilder
    private func displayView(entry: DayEntry) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            if let emoji = entry.moodEmoji {
                Text(emoji)
                    .font(.system(size: 40))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.highlightText ?? "")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(entry.dateFormatted)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(.yellow.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.small)
    }

    // MARK: - Edit View
    private var editView: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Prompt
            Text(prompt)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Text input
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                if let emoji = selectedEmoji {
                    Text(emoji)
                        .font(.system(size: 32))
                }

                TextField("Write your highlight...", text: $highlightText, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.body)
            }
            .padding()
            .background(Theme.Colors.background)
            .cornerRadius(Theme.CornerRadius.small)

            // Emoji picker toggle
            Button(action: { showEmojiPicker.toggle() }) {
                HStack {
                    Image(systemName: showEmojiPicker ? "chevron.up" : "chevron.down")
                    Text(selectedEmoji == nil ? "Add a mood" : "Change mood")
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            if showEmojiPicker {
                EmojiPicker(
                    selectedEmoji: $selectedEmoji,
                    emojis: EmojiPicker.moodEmojis
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Save button
            Button(action: saveHighlight) {
                Text(dayEntry?.hasHighlight == true ? "Update Highlight" : "Save Highlight")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(highlightText.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(Theme.CornerRadius.medium)
            }
            .disabled(highlightText.isEmpty)
            .buttonStyle(.plain)

            if isEditing {
                Button("Cancel") {
                    isEditing = false
                    loadExistingHighlight()
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showEmojiPicker)
    }

    // MARK: - Methods

    private func loadExistingHighlight() {
        if let entry = dayEntry {
            highlightText = entry.highlightText ?? ""
            selectedEmoji = entry.moodEmoji
        } else {
            highlightText = ""
            selectedEmoji = nil
        }
    }

    private func saveHighlight() {
        if let entry = dayEntry {
            // Update existing entry
            entry.highlightText = highlightText
            entry.moodEmoji = selectedEmoji
        } else {
            // Create new entry
            let newEntry = DayEntry(date: date)
            newEntry.highlightText = highlightText
            newEntry.moodEmoji = selectedEmoji
            modelContext.insert(newEntry)
            dayEntry = newEntry
        }

        do {
            try modelContext.save()
            isEditing = false
            showEmojiPicker = false
        } catch {
            print("Error saving highlight: \(error)")
        }
    }

    private func deleteHighlight() {
        guard let entry = dayEntry else { return }

        entry.clearHighlight()

        do {
            try modelContext.save()
            highlightText = ""
            selectedEmoji = nil
            isEditing = false
        } catch {
            print("Error deleting highlight: \(error)")
        }
    }
}

// MARK: - Preview
#Preview("Empty") {
    @Previewable @State var dayEntry: DayEntry? = nil

    HighlightCardView(date: Date(), dayEntry: $dayEntry)
        .modelContainer(ModelContainer.preview)
        .padding()
}

#Preview("With Highlight") {
    @Previewable @State var dayEntry: DayEntry? = {
        let entry = DayEntry(date: Date())
        entry.addHighlight(text: "Had an amazing brainstorming session with the team!", emoji: "🤩")
        return entry
    }()

    HighlightCardView(date: Date(), dayEntry: $dayEntry)
        .modelContainer(ModelContainer.preview)
        .padding()
}
