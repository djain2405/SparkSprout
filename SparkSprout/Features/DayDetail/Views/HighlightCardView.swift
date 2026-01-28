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
//  - Handwriting-style fonts
//  - Background patterns/colors
//  - Card flip animation
//  - Swipe gestures for navigation
//

import SwiftUI
import SwiftData
import PhotosUI

struct HighlightCardView: View {
    let date: Date
    let events: [Event]
    @Binding var dayEntry: DayEntry?

    // Navigation callbacks for swipe gestures
    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?

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

    // Card customization state
    @State private var selectedFontStyle: Theme.HighlightFontStyle = .standard
    @State private var selectedCardStyle: Theme.HighlightCardStyle = .classic
    @State private var showStylePicker: Bool = false

    // Flip animation state
    @State private var isFlipped: Bool = false
    @State private var flipDegrees: Double = 0

    // Swipe gesture state
    @State private var dragOffset: CGSize = .zero

    @Environment(\.dismiss) private var dismissView

    private var currentStreak: Int {
        HighlightService.calculateCurrentStreak(from: allHighlights)
    }

    init(date: Date, events: [Event] = [], dayEntry: Binding<DayEntry?>, onSwipeLeft: (() -> Void)? = nil, onSwipeRight: (() -> Void)? = nil) {
        self.date = date
        self.events = events
        self._dayEntry = dayEntry
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
    }

    var body: some View {
        ZStack {
            // Front of card (teaser/closed state)
            cardFront
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0))

            // Back of card (full content)
            cardBack
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipDegrees - 180), axis: (x: 0, y: 1, z: 0))
        }
        .offset(x: dragOffset.width)
        .gesture(swipeGesture)
        .onAppear {
            loadExistingHighlight()
            // Auto-flip to show content if there's a highlight
            if dayEntry?.hasHighlight == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    flipCard()
                }
            }
        }
        .onChange(of: isEditing) { _, newValue in
            if newValue {
                loadExistingHighlight()
            }
        }
        .onChange(of: dayEntry?.highlightText) { _, _ in
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

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow horizontal swipes
                if abs(value.translation.width) > abs(value.translation.height) {
                    dragOffset = CGSize(width: value.translation.width * 0.5, height: 0)
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100

                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if value.translation.width > threshold {
                        // Swipe right - go to previous day
                        onSwipeRight?()
                    } else if value.translation.width < -threshold {
                        // Swipe left - go to next day
                        onSwipeLeft?()
                    }
                    dragOffset = .zero
                }
            }
    }

    // MARK: - Card Front (Teaser)

    private var cardFront: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Decorative pattern background
            ZStack {
                selectedCardStyle.backgroundColor
                CardPatternView(style: selectedCardStyle)
            }
            .frame(height: 120)
            .overlay(
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(selectedCardStyle.accentGradient)
                        .shadow(color: .black.opacity(0.2), radius: 4)

                    Text(dayEntry?.hasHighlight == true ? "Tap to reveal" : "Add your highlight")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(selectedCardStyle.secondaryTextColor)

                    if let emoji = dayEntry?.moodEmoji {
                        Text(emoji)
                            .font(.system(size: 24))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .padding()
        .background(selectedCardStyle.backgroundColor)
        .cornerRadius(Theme.CornerRadius.medium)
        .shadow(
            color: Theme.Shadow.medium.color,
            radius: Theme.Shadow.medium.radius,
            x: Theme.Shadow.medium.x,
            y: Theme.Shadow.medium.y
        )
        .onTapGesture {
            if dayEntry?.hasHighlight == true {
                flipCard()
            } else {
                // Go directly to edit mode
                isFlipped = true
                flipDegrees = 180
            }
        }
    }

    // MARK: - Card Back (Full Content)

    private var cardBack: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(selectedCardStyle.accentGradient)
                Text("Today's Highlight")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(selectedCardStyle.textColor)

                Spacer()

                // Style picker button
                Button(action: { showStylePicker.toggle() }) {
                    Image(systemName: "paintpalette")
                        .foregroundStyle(.blue)
                }

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

                // Flip back button
                Button(action: flipCard) {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .foregroundStyle(selectedCardStyle.secondaryTextColor)
                }
            }

            // Style picker
            if showStylePicker {
                stylePickerView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let entry = dayEntry, entry.hasHighlight && !isEditing {
                displayView(entry: entry)
            } else {
                editView
            }
        }
        .padding()
        .background(
            ZStack {
                selectedCardStyle.backgroundColor
                CardPatternView(style: selectedCardStyle)
            }
        )
        .cornerRadius(Theme.CornerRadius.medium)
        .shadow(
            color: Theme.Shadow.small.color,
            radius: Theme.Shadow.small.radius,
            x: Theme.Shadow.small.x,
            y: Theme.Shadow.small.y
        )
        .animation(.easeInOut(duration: 0.3), value: showStylePicker)
    }

    // MARK: - Flip Animation

    private func flipCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isFlipped.toggle()
            flipDegrees += 180
        }
        Theme.Haptics.light()
    }

    // MARK: - Style Picker

    private var stylePickerView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Font style picker
            Text("Font Style")
                .font(Theme.Typography.caption)
                .foregroundStyle(selectedCardStyle.secondaryTextColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Theme.HighlightFontStyle.allCases) { style in
                        Button(action: {
                            selectedFontStyle = style
                            saveStylePreferences()
                            Theme.Haptics.light()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 16))
                                Text(style.rawValue)
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(selectedFontStyle == style ? .white : selectedCardStyle.textColor)
                            .frame(width: 60, height: 50)
                            .background(selectedFontStyle == style ? Color.blue : Color.gray.opacity(0.2))
                            .cornerRadius(Theme.CornerRadius.small)
                        }
                    }
                }
            }

            // Card style picker
            Text("Card Style")
                .font(Theme.Typography.caption)
                .foregroundStyle(selectedCardStyle.secondaryTextColor)
                .padding(.top, Theme.Spacing.xs)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Theme.HighlightCardStyle.allCases) { style in
                        Button(action: {
                            withAnimation {
                                selectedCardStyle = style
                            }
                            saveStylePreferences()
                            Theme.Haptics.light()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .fill(style.backgroundColor)
                                    .frame(width: 50, height: 50)

                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .stroke(style.accentGradient, lineWidth: 2)
                                    .frame(width: 50, height: 50)

                                if selectedCardStyle == style {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(style.textColor)
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.small)
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
                        .font(Theme.Typography.highlightFont(style: selectedFontStyle))
                        .foregroundStyle(selectedCardStyle.textColor)
                        .lineSpacing(4)

                    Text(entry.dateFormatted)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(selectedCardStyle.secondaryTextColor)
                }

                Spacer()
            }
        }
        .padding()
        .background(selectedCardStyle.accentGradient.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.small)
    }

    // MARK: - Edit View
    private var editView: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Prompt
            Text(prompt)
                .font(Theme.Typography.caption)
                .foregroundStyle(selectedCardStyle.secondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Photo preview/picker
            photoSection

            // Text input with selected font preview
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                if let emoji = selectedEmoji {
                    Text(emoji)
                        .font(.system(size: 32))
                }

                TextField("Write your highlight...", text: $highlightText, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.highlightFont(style: selectedFontStyle))
                    .foregroundStyle(selectedCardStyle.textColor)
            }
            .padding()
            .background(selectedCardStyle.backgroundColor.opacity(0.8))
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
                .foregroundStyle(selectedCardStyle.secondaryTextColor)
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
                    .foregroundStyle(selectedCardStyle.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(selectedCardStyle.backgroundColor)
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

            // Load saved style preferences
            if let fontStyleRaw = entry.highlightFontStyle,
               let fontStyle = Theme.HighlightFontStyle(rawValue: fontStyleRaw) {
                selectedFontStyle = fontStyle
            }
            if let cardStyleRaw = entry.highlightCardStyle,
               let cardStyle = Theme.HighlightCardStyle(rawValue: cardStyleRaw) {
                selectedCardStyle = cardStyle
            }
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
            entry.highlightFontStyle = selectedFontStyle.rawValue
            entry.highlightCardStyle = selectedCardStyle.rawValue
        } else {
            // Create new entry
            let newEntry = DayEntry(date: date)
            newEntry.highlightText = highlightText
            newEntry.moodEmoji = selectedEmoji
            newEntry.highlightPhotoData = selectedPhotoData
            newEntry.highlightFontStyle = selectedFontStyle.rawValue
            newEntry.highlightCardStyle = selectedCardStyle.rawValue
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
            // Flip back to front after deleting
            flipCard()
        } catch {
            print("Error deleting highlight: \(error)")
        }
    }

    /// Saves only the style preferences (font and card style) without requiring full save flow
    /// Called automatically when styles change for existing highlights
    private func saveStylePreferences() {
        guard let entry = dayEntry, entry.hasHighlight else { return }

        entry.highlightFontStyle = selectedFontStyle.rawValue
        entry.highlightCardStyle = selectedCardStyle.rawValue

        do {
            try modelContext.save()
        } catch {
            print("Error saving style preferences: \(error)")
        }
    }
}

// MARK: - Card Pattern View

/// Decorative pattern overlay for highlight cards
struct CardPatternView: View {
    let style: Theme.HighlightCardStyle

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw subtle pattern based on style
                let patternSize: CGFloat = 30

                for x in stride(from: 0, to: size.width + patternSize, by: patternSize) {
                    for y in stride(from: 0, to: size.height + patternSize, by: patternSize) {
                        let offset = (Int(y / patternSize) % 2 == 0) ? patternSize / 2 : 0

                        switch style {
                        case .classic, .warm:
                            // Dots pattern
                            let path = Circle().path(in: CGRect(x: x + offset, y: y, width: 4, height: 4))
                            context.fill(path, with: .color(.gray.opacity(style.patternOpacity)))

                        case .cool, .midnight:
                            // Diamond pattern
                            var diamond = Path()
                            diamond.move(to: CGPoint(x: x + offset + 6, y: y))
                            diamond.addLine(to: CGPoint(x: x + offset + 12, y: y + 6))
                            diamond.addLine(to: CGPoint(x: x + offset + 6, y: y + 12))
                            diamond.addLine(to: CGPoint(x: x + offset, y: y + 6))
                            diamond.closeSubpath()
                            context.stroke(diamond, with: .color(.gray.opacity(style.patternOpacity)), lineWidth: 0.5)

                        case .nature:
                            // Leaf-like curves
                            var leaf = Path()
                            leaf.move(to: CGPoint(x: x + offset, y: y + 8))
                            leaf.addQuadCurve(to: CGPoint(x: x + offset + 8, y: y), control: CGPoint(x: x + offset + 8, y: y + 8))
                            context.stroke(leaf, with: .color(.green.opacity(style.patternOpacity * 2)), lineWidth: 0.5)

                        case .sunset:
                            // Wave pattern
                            var wave = Path()
                            wave.move(to: CGPoint(x: x, y: y + 4))
                            wave.addQuadCurve(to: CGPoint(x: x + patternSize, y: y + 4), control: CGPoint(x: x + patternSize / 2, y: y - 4))
                            context.stroke(wave, with: .color(.orange.opacity(style.patternOpacity * 2)), lineWidth: 0.5)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Empty - Front") {
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

#Preview("Card Styles") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(Theme.HighlightCardStyle.allCases) { style in
                VStack(alignment: .leading) {
                    Text(style.rawValue)
                        .font(.caption)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(style.backgroundColor)
                        .frame(height: 80)
                        .overlay(
                            CardPatternView(style: style)
                        )
                        .overlay(
                            Text("Sample Text")
                                .foregroundStyle(style.textColor)
                        )
                }
            }
        }
        .padding()
    }
}
