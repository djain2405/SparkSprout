//
//  HighlightCardView.swift
//  SparkSprout
//
//  Card for adding/editing daily highlights with photo support
//
//  Enhanced with:
//  - Event-aware prompts
//  - Photo picker/display
//  - Weekly reflection prompts
//

import SwiftUI
import SwiftData
import PhotosUI

struct HighlightCardView: View {
    let date: Date
    let events: [Event]
    @Binding var dayEntry: DayEntry?

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<DayEntry> { $0.highlightText != nil })
    private var allHighlights: [DayEntry]

    @State private var highlightText: String = ""
    @State private var selectedEmoji: String? = nil
    @State private var isEditing: Bool = false
    @State private var showEmojiPicker: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var prompt: String = ""
    @State private var isSaving: Bool = false

    // Photo picker state
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var showingPhotoOptions: Bool = false
    @State private var isLoadingPhoto: Bool = false

    @Environment(\.dismiss) private var dismissView

    private var currentStreak: Int {
        HighlightService.calculateCurrentStreak(from: allHighlights)
    }

    init(date: Date, events: [Event] = [], dayEntry: Binding<DayEntry?>) {
        self.date = date
        self.events = events
        self._dayEntry = dayEntry
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
        .onChange(of: isEditing) { _, newValue in
            // Reload existing data when entering edit mode
            if newValue {
                loadExistingHighlight()
            }
        }
        .onChange(of: dayEntry?.highlightText) { _, _ in
            // Reload when day entry changes externally
            if !isEditing {
                loadExistingHighlight()
            }
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
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Photo display (if available)
            if let photoData = entry.highlightPhotoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 200)
                    .clipped()
                    .cornerRadius(Theme.CornerRadius.small)
            }

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

            // Photo preview/picker
            photoSection

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

            // Mood and photo buttons row
            HStack(spacing: Theme.Spacing.md) {
                // Emoji picker toggle
                Button(action: { showEmojiPicker.toggle() }) {
                    HStack {
                        Image(systemName: showEmojiPicker ? "chevron.up" : "face.smiling")
                        Text(selectedEmoji == nil ? "Add mood" : "Change mood")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                // Photo picker
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: selectedPhotoData != nil ? "photo.fill" : "photo")
                        Text(selectedPhotoData != nil ? "Change photo" : "Add photo")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            if showEmojiPicker {
                EmojiPicker(
                    selectedEmoji: $selectedEmoji,
                    emojis: EmojiPicker.moodEmojis
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Save button
            Button(action: saveHighlight) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(dayEntry?.hasHighlight == true ? "Update Highlight" : "Save Highlight")
                }
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(highlightText.isEmpty || isSaving ? Color.gray : Color.blue)
                .cornerRadius(Theme.CornerRadius.medium)
            }
            .disabled(highlightText.isEmpty || isSaving)
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadPhoto(from: newItem)
        }
    }

    // MARK: - Photo Section
    @ViewBuilder
    private var photoSection: some View {
        if isLoadingPhoto {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Loading photo...")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Theme.Colors.background)
            .cornerRadius(Theme.CornerRadius.small)
        } else if let photoData = selectedPhotoData,
                  let uiImage = UIImage(data: photoData) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 150)
                    .clipped()
                    .cornerRadius(Theme.CornerRadius.small)

                // Remove photo button
                Button(action: {
                    withAnimation {
                        selectedPhotoData = nil
                        selectedPhotoItem = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
                .padding(Theme.Spacing.sm)
            }
        }
    }

    // MARK: - Photo Loading
    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }

        isLoadingPhoto = true

        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    // Compress image for storage
                    if let uiImage = UIImage(data: data),
                       let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                        await MainActor.run {
                            selectedPhotoData = compressedData
                            isLoadingPhoto = false
                        }
                    } else {
                        await MainActor.run {
                            selectedPhotoData = data
                            isLoadingPhoto = false
                        }
                    }
                } else {
                    await MainActor.run {
                        isLoadingPhoto = false
                    }
                }
            } catch {
                print("Error loading photo: \(error)")
                await MainActor.run {
                    isLoadingPhoto = false
                }
            }
        }
    }

    // MARK: - Methods

    private func loadExistingHighlight() {
        if let entry = dayEntry {
            highlightText = entry.highlightText ?? ""
            selectedEmoji = entry.moodEmoji
            selectedPhotoData = entry.highlightPhotoData
        } else {
            highlightText = ""
            selectedEmoji = nil
            selectedPhotoData = nil
        }

        // Set event-aware prompt based on date, events, and streak
        prompt = HighlightService.eventAwarePrompt(for: date, events: events, currentStreak: currentStreak)
    }

    private func saveHighlight() {
        // Prevent multiple saves
        guard !isSaving else { return }
        isSaving = true

        if let entry = dayEntry {
            // Update existing entry
            entry.highlightText = highlightText
            entry.moodEmoji = selectedEmoji
            entry.highlightPhotoData = selectedPhotoData
        } else {
            // Create new entry
            let newEntry = DayEntry(date: date)
            newEntry.highlightText = highlightText
            newEntry.moodEmoji = selectedEmoji
            newEntry.highlightPhotoData = selectedPhotoData
            modelContext.insert(newEntry)
            dayEntry = newEntry
        }

        do {
            try modelContext.save()
            isEditing = false
            showEmojiPicker = false
            isSaving = false

            // Dismiss the detail screen after successfully adding highlight
            dismissView()
        } catch {
            print("Error saving highlight: \(error)")
            isSaving = false
        }
    }

    private func deleteHighlight() {
        guard let entry = dayEntry else { return }

        entry.clearHighlight()

        do {
            try modelContext.save()
            highlightText = ""
            selectedEmoji = nil
            selectedPhotoData = nil
            isEditing = false
        } catch {
            print("Error deleting highlight: \(error)")
        }
    }
}

// MARK: - Preview
#Preview("Empty") {
    @Previewable @State var dayEntry: DayEntry? = nil

    HighlightCardView(date: Date(), events: [], dayEntry: $dayEntry)
        .modelContainer(ModelContainer.preview)
        .padding()
}

#Preview("With Highlight") {
    @Previewable @State var dayEntry: DayEntry? = {
        let entry = DayEntry(date: Date())
        entry.addHighlight(text: "Had an amazing brainstorming session with the team!", emoji: "🤩")
        return entry
    }()

    HighlightCardView(date: Date(), events: [], dayEntry: $dayEntry)
        .modelContainer(ModelContainer.preview)
        .padding()
}
