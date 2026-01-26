//
//  QuickAddEventView.swift
//  SparkSprout
//
//  Quick event creation with natural language parsing
//  Floating input bar with live preview and suggestions
//

import SwiftUI
import SwiftData

struct QuickAddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [Event]

    @State private var inputText = ""
    @State private var parsedEvent: ParsedEvent?
    @State private var showingFullEditor = false
    @State private var showingConflictWarning = false
    @State private var conflicts: [ConflictDetector.Conflict] = []
    @State private var isSaving = false
    @State private var showSuccessAnimation = false

    @FocusState private var isInputFocused: Bool

    private let suggestions = QuickAddParser.suggestions()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Input field
                        inputFieldView

                        // Suggestions (when input is empty)
                        if inputText.isEmpty {
                            suggestionsView
                        }

                        // Live preview (when we have parsed content)
                        if let parsed = parsedEvent {
                            parsedPreviewView(parsed)
                        }

                        // Tips
                        if inputText.isEmpty {
                            tipsView
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }

                // Bottom action bar
                if parsedEvent != nil {
                    actionBarView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isInputFocused = true
                }
            }
            .onChange(of: inputText) { _, newValue in
                parseInput(newValue)
            }
            .sheet(isPresented: $showingFullEditor) {
                if let parsed = parsedEvent {
                    AddEditEventView(
                        event: createEventFromParsed(parsed),
                        date: parsed.startDate
                    )
                }
            }
            .sheet(isPresented: $showingConflictWarning) {
                if let parsed = parsedEvent {
                    ConflictWarningView(
                        conflicts: conflicts,
                        eventDuration: parsed.endDate.timeIntervalSince(parsed.startDate),
                        eventStartDate: parsed.startDate,
                        existingEvents: allEvents,
                        onKeepAnyway: {
                            showingConflictWarning = false
                            saveEvent(from: parsed, markFlexible: false, markTentative: false)
                        },
                        onAdjustTime: {
                            showingConflictWarning = false
                            showingFullEditor = true
                        },
                        onMarkFlexible: {
                            showingConflictWarning = false
                            saveEvent(from: parsed, markFlexible: true, markTentative: false)
                        },
                        onMarkTentative: {
                            showingConflictWarning = false
                            saveEvent(from: parsed, markFlexible: false, markTentative: true)
                        },
                        onApplyTimeSlot: { newStartDate in
                            showingConflictWarning = false
                            let duration = parsed.endDate.timeIntervalSince(parsed.startDate)
                            var updatedParsed = parsed
                            updatedParsed.startDate = newStartDate
                            updatedParsed.endDate = newStartDate.addingTimeInterval(duration)
                            parsedEvent = updatedParsed
                            // Re-check conflicts
                            checkAndSave(updatedParsed)
                        },
                        onFindNextSlot: {
                            showingConflictWarning = false
                            if let nextSlot = findNextAvailableSlot(for: parsed) {
                                var updatedParsed = parsed
                                updatedParsed.startDate = nextSlot
                                updatedParsed.endDate = nextSlot.addingTimeInterval(parsed.endDate.timeIntervalSince(parsed.startDate))
                                parsedEvent = updatedParsed
                                checkAndSave(updatedParsed)
                            }
                        },
                        onCancel: {
                            showingConflictWarning = false
                        }
                    )
                }
            }
            .overlay {
                if showSuccessAnimation {
                    successOverlay
                }
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Quick Add")
                .font(Theme.Typography.headline)

            Spacer()

            // Placeholder to balance the X button
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.clear)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Input Field

    private var inputFieldView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.accent)

                TextField("Dinner w/ Sarah 7pm Thursday...", text: $inputText, axis: .vertical)
                    .font(Theme.Typography.body)
                    .focused($isInputFocused)
                    .lineLimit(1...3)
                    .submitLabel(.done)
                    .onSubmit {
                        if let parsed = parsedEvent {
                            checkAndSave(parsed)
                        }
                    }

                if !inputText.isEmpty {
                    Button(action: { inputText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
            .shadow(
                color: Theme.Shadow.medium.color,
                radius: Theme.Shadow.medium.radius,
                x: Theme.Shadow.medium.x,
                y: Theme.Shadow.medium.y
            )

            // Confidence indicator
            if let parsed = parsedEvent {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: confidenceIcon(for: parsed.confidence))
                        .foregroundStyle(confidenceColor(for: parsed.confidence))

                    Text(confidenceText(for: parsed.confidence))
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, Theme.Spacing.sm)
            }
        }
    }

    // MARK: - Suggestions View

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Try something like:")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: {
                    inputText = suggestion
                    Theme.Haptics.light()
                }) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(Theme.Colors.primary)

                        Text(suggestion)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
        }
    }

    // MARK: - Parsed Preview View

    private func parsedPreviewView(_ parsed: ParsedEvent) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Preview")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()

                Button(action: {
                    showingFullEditor = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit details")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.primary)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Title
                HStack(spacing: Theme.Spacing.md) {
                    eventTypeIcon(for: parsed.eventType)
                        .frame(width: 40, height: 40)
                        .background(eventTypeColor(for: parsed.eventType).opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.small)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(parsed.title)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        if let type = parsed.eventType {
                            Text(type.capitalized.replacingOccurrences(of: "_", with: " "))
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(eventTypeColor(for: type))
                        }
                    }
                }

                Divider()

                // Date and time
                HStack(spacing: Theme.Spacing.lg) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Theme.Colors.primary)
                        Text(formatDate(parsed.startDate))
                            .font(Theme.Typography.body)
                    }

                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "clock")
                            .foregroundStyle(Theme.Colors.primary)
                        Text(formatTimeRange(start: parsed.startDate, end: parsed.endDate))
                            .font(Theme.Typography.body)
                    }
                }

                // Duration
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "hourglass")
                        .foregroundStyle(.secondary)
                    Text(formatDuration(parsed.endDate.timeIntervalSince(parsed.startDate)))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                // Location if present
                if let location = parsed.location {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "location")
                            .foregroundStyle(.secondary)
                        Text(location)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
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
        }
    }

    // MARK: - Tips View

    private var tipsView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Tips")
                    .font(Theme.Typography.caption)
                    .fontWeight(.medium)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                tipRow(icon: "clock", text: "Add time: \"7pm\", \"14:30\", \"noon\"")
                tipRow(icon: "calendar", text: "Add day: \"tomorrow\", \"Thu\", \"Friday\"")
                tipRow(icon: "timer", text: "Add duration: \"2hr\", \"30min\", \"quick\"")
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Action Bar

    private var actionBarView: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: Theme.Spacing.md) {
                // Edit button
                Button(action: { showingFullEditor = true }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("More Options")
                    }
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(.vertical, Theme.Spacing.md)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                }

                // Add button
                Button(action: {
                    if let parsed = parsedEvent {
                        checkAndSave(parsed)
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Event")
                        }
                    }
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Colors.accent)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                .disabled(isSaving)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                    .animation(Theme.Animation.bouncy, value: showSuccessAnimation)

                Text("Event Added!")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.white)
            }
            .padding(Theme.Spacing.xl)
            .background(.ultraThinMaterial)
            .cornerRadius(Theme.CornerRadius.large)
        }
    }

    // MARK: - Methods

    private func parseInput(_ text: String) {
        guard !text.isEmpty else {
            parsedEvent = nil
            return
        }

        parsedEvent = QuickAddParser.parse(text)
    }

    private func checkAndSave(_ parsed: ParsedEvent) {
        // Check for conflicts
        let detector = ConflictDetector()
        let detectedConflicts = detector.detectConflicts(
            for: (start: parsed.startDate, end: parsed.endDate),
            in: allEvents,
            excludingEventId: nil
        )

        if !detectedConflicts.isEmpty {
            conflicts = detectedConflicts
            showingConflictWarning = true
        } else {
            saveEvent(from: parsed, markFlexible: false, markTentative: false)
        }
    }

    private func saveEvent(from parsed: ParsedEvent, markFlexible: Bool, markTentative: Bool) {
        isSaving = true

        let event = Event(
            title: parsed.title,
            startDate: parsed.startDate,
            endDate: parsed.endDate,
            location: parsed.location,
            eventType: parsed.eventType,
            isFlexible: markFlexible,
            isTentative: markTentative
        )

        modelContext.insert(event)

        do {
            try modelContext.save()
            Theme.Haptics.success()

            // Show success animation
            withAnimation {
                showSuccessAnimation = true
            }

            // Dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } catch {
            print("Error saving event: \(error)")
            Theme.Haptics.error()
            isSaving = false
        }
    }

    private func createEventFromParsed(_ parsed: ParsedEvent) -> Event? {
        // Return nil to indicate this is a new event (not editing)
        // The AddEditEventView will use the date from parsed.startDate
        return nil
    }

    private func findNextAvailableSlot(for parsed: ParsedEvent) -> Date? {
        let detector = ConflictDetector()
        let duration = parsed.endDate.timeIntervalSince(parsed.startDate)
        return detector.findNextAvailableSlot(
            duration: duration,
            startingFrom: parsed.startDate,
            in: allEvents
        )
    }

    // MARK: - Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            if remainingMins == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            }
            return "\(hours)h \(remainingMins)m"
        }
        return "\(minutes) min"
    }

    private func eventTypeIcon(for type: String?) -> some View {
        let iconName: String
        switch type {
        case Event.EventType.work: iconName = "briefcase.fill"
        case Event.EventType.social: iconName = "person.2.fill"
        case Event.EventType.cleaning: iconName = "sparkles"
        case Event.EventType.admin: iconName = "doc.text.fill"
        case Event.EventType.deepWork: iconName = "brain.head.profile"
        case Event.EventType.soloDate: iconName = "heart.fill"
        case "health": iconName = "figure.run"
        default: iconName = "calendar"
        }

        return Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(eventTypeColor(for: type))
    }

    private func eventTypeColor(for type: String?) -> Color {
        switch type {
        case Event.EventType.work: return .blue
        case Event.EventType.social: return .pink
        case Event.EventType.cleaning: return .teal
        case Event.EventType.admin: return .purple
        case Event.EventType.deepWork: return .orange
        case Event.EventType.soloDate: return .red
        case "health": return .green
        default: return Theme.Colors.primary
        }
    }

    private func confidenceIcon(for confidence: Double) -> String {
        if confidence >= 0.7 { return "checkmark.circle.fill" }
        if confidence >= 0.4 { return "checkmark.circle" }
        return "questionmark.circle"
    }

    private func confidenceColor(for confidence: Double) -> Color {
        if confidence >= 0.7 { return .green }
        if confidence >= 0.4 { return .orange }
        return .secondary
    }

    private func confidenceText(for confidence: Double) -> String {
        if confidence >= 0.7 { return "Looks good!" }
        if confidence >= 0.4 { return "Mostly understood" }
        return "Tap 'More Options' to add details"
    }
}

// MARK: - Quick Add Button Component

/// Floating action button for Quick Add
struct QuickAddButton: View {
    @Binding var showingQuickAdd: Bool

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            showingQuickAdd = true
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Quick Add")
                    .font(Theme.Typography.body)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Capsule()
                    .fill(Theme.Colors.accent)
                    .shadow(
                        color: Theme.Colors.accent.opacity(0.4),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    QuickAddEventView()
        .modelContainer(ModelContainer.preview)
}

#Preview("Quick Add Button") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                QuickAddButton(showingQuickAdd: .constant(false))
                    .padding()
            }
        }
    }
}
