//
//  AddEditEventView.swift
//  SparkSprout
//
//  Form for creating and editing events with conflict detection
//

import SwiftUI
import SwiftData

struct AddEditEventView: View {
    let event: Event? // nil for new event
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allEvents: [Event]

    @State private var viewModel: EventFormViewModel
    @State private var showingConflictWarning = false
    @State private var showingDeleteConfirmation = false

    init(event: Event? = nil, date: Date) {
        self.event = event
        self.date = date
        _viewModel = State(initialValue: EventFormViewModel(event: event, defaultStartDate: date))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Event details section
                Section("Event Details") {
                    TextField("Title", text: $viewModel.title)
                        .font(Theme.Typography.body)

                    DatePicker(
                        "Starts",
                        selection: $viewModel.startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    DatePicker(
                        "Ends",
                        selection: $viewModel.endDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Text("Duration: \(viewModel.durationFormatted)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                // Quick duration presets
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach([
                                EventFormViewModel.QuickDuration.thirtyMinutes,
                                .oneHour,
                                .ninetyMinutes,
                                .twoHours,
                                .halfDay,
                                .fullDay
                            ], id: \.label) { preset in
                                Button(action: { viewModel.applyQuickDuration(preset) }) {
                                    Text(preset.label)
                                        .font(Theme.Typography.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Quick Durations")
                }

                // Location and notes
                Section("Additional Details") {
                    LocationSearchField(location: $viewModel.location)

                    VStack(alignment: .leading) {
                        Text("Notes")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        TextEditor(text: $viewModel.notes)
                            .frame(height: 80)
                    }
                }

                // Event type and options
                Section("Options") {
                    Picker("Type", selection: $viewModel.eventType) {
                        Text("Personal").tag(Event.EventType.personal)
                        Text("Work").tag(Event.EventType.work)
                        Text("Social").tag(Event.EventType.social)
                        Text("Health").tag(Event.EventType.health)
                        Text("Solo Date").tag(Event.EventType.soloDate)
                        Text("Cleaning").tag(Event.EventType.cleaning)
                        Text("Admin").tag(Event.EventType.admin)
                        Text("Deep Work").tag(Event.EventType.deepWork)
                    }

                    Toggle("Flexible timing", isOn: $viewModel.isFlexible)

                    if viewModel.isFlexible {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("This event can be moved if conflicts arise")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }

                    Toggle("Tentative", isOn: $viewModel.isTentative)

                    if viewModel.isTentative {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                            Text("This event is not confirmed yet")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }

                // Delete button for existing events
                if event != nil {
                    Section {
                        Button(role: .destructive, action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        checkForConflictsAndSave()
                    }
                    .disabled(!viewModel.isValid)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteEvent()
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
            .sheet(isPresented: $showingConflictWarning) {
                ConflictWarningView(
                    conflicts: viewModel.conflicts,
                    eventDuration: viewModel.endDate.timeIntervalSince(viewModel.startDate),
                    eventStartDate: viewModel.startDate,
                    existingEvents: allEvents,
                    onKeepAnyway: {
                        showingConflictWarning = false
                        saveEvent()
                    },
                    onAdjustTime: {
                        showingConflictWarning = false
                        // User can adjust the time in the form
                    },
                    onMarkFlexible: {
                        viewModel.markAsFlexible()
                        showingConflictWarning = false
                        saveEvent()
                    },
                    onMarkTentative: {
                        viewModel.markAsTentative()
                        showingConflictWarning = false
                        saveEvent()
                    },
                    onApplyTimeSlot: { newStartDate in
                        viewModel.applyTimeSlot(newStartDate)
                        showingConflictWarning = false
                        // Re-check for conflicts after applying the new time slot
                        checkForConflictsAndSave()
                    },
                    onFindNextSlot: {
                        if viewModel.findAndApplyNextAvailableSlot(in: allEvents) {
                            showingConflictWarning = false
                            // Re-check for conflicts after finding next slot
                            checkForConflictsAndSave()
                        } else {
                            // TODO: Show alert that no available slot was found
                            print("No available slot found")
                        }
                    },
                    onCancel: {
                        showingConflictWarning = false
                        viewModel.clearConflicts()
                    }
                )
            }
        }
    }

    // MARK: - Methods

    private func checkForConflictsAndSave() {
        viewModel.detectConflicts(in: allEvents, excludingEventId: event?.id)

        if viewModel.hasConflicts {
            showingConflictWarning = true
        } else {
            saveEvent()
        }
    }

    private func saveEvent() {
        if let existingEvent = event {
            // Update existing event
            existingEvent.title = viewModel.title
            existingEvent.startDate = viewModel.startDate
            existingEvent.endDate = viewModel.endDate
            existingEvent.location = viewModel.location.isEmpty ? nil : viewModel.location
            existingEvent.notes = viewModel.notes.isEmpty ? nil : viewModel.notes
            existingEvent.eventType = viewModel.eventType
            existingEvent.isFlexible = viewModel.isFlexible
            existingEvent.isTentative = viewModel.isTentative
        } else {
            // Create new event
            let newEvent = Event(
                title: viewModel.title,
                startDate: viewModel.startDate,
                endDate: viewModel.endDate,
                location: viewModel.location.isEmpty ? nil : viewModel.location,
                notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
                eventType: viewModel.eventType,
                isFlexible: viewModel.isFlexible,
                isTentative: viewModel.isTentative
            )

            modelContext.insert(newEvent)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving event: \(error)")
        }
    }

    private func deleteEvent() {
        guard let eventToDelete = event else { return }

        modelContext.delete(eventToDelete)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting event: \(error)")
        }
    }
}

// MARK: - Preview
#Preview("New Event") {
    AddEditEventView(date: Date())
        .modelContainer(ModelContainer.preview)
}

#Preview("Edit Event") {
    AddEditEventView(
        event: Event(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Office",
            eventType: Event.EventType.work
        ),
        date: Date()
    )
    .modelContainer(ModelContainer.preview)
}
