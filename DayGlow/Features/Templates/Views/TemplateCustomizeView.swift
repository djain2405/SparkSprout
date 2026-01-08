//
//  TemplateCustomizeView.swift
//  DayGlow
//
//  View for customizing template before creating event
//

import SwiftUI
import SwiftData

struct TemplateCustomizeView: View {
    let template: Template
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var existingEvents: [Event] = []
    @State private var conflicts: [ConflictDetector.Conflict] = []
    @State private var showingConflictWarning = false
    @State private var isSaving = false

    init(template: Template, date: Date) {
        self.template = template
        self.date = date

        // Initialize with default template times
        let calendar = Calendar.current
        let defaultStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
        _startTime = State(initialValue: defaultStart)
        _endTime = State(initialValue: defaultStart.addingTimeInterval(template.defaultDuration))
    }

    private var durationFormatted: String {
        let duration = endTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Template info section
                Section {
                    HStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(templateColor.opacity(0.2))
                                .frame(width: 50, height: 50)

                            Image(systemName: template.icon)
                                .font(.title2)
                                .foregroundStyle(templateColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.displayName)
                                .font(Theme.Typography.headline)

                            Text(template.name.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()
                    }
                }

                // Time section
                Section("Schedule") {
                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        displayedComponents: [.hourAndMinute]
                    )

                    DatePicker(
                        "End Time",
                        selection: $endTime,
                        displayedComponents: [.hourAndMinute]
                    )

                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Text("Duration: \(durationFormatted)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                // Checklist (if available)
                if let checklist = template.suggestedChecklist, !checklist.isEmpty {
                    Section("Suggested Activities") {
                        ForEach(checklist, id: \.self) { item in
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                                Text(item)
                                    .font(Theme.Typography.body)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Customize Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create Event") {
                        checkConflictsAndCreate()
                    }
                    .fontWeight(.semibold)
                    .disabled(endTime <= startTime || isSaving)
                }
            }
            .onAppear {
                loadExistingEvents()
            }
            .onChange(of: startTime) { _, _ in
                checkForConflicts()
            }
            .onChange(of: endTime) { _, _ in
                checkForConflicts()
            }
            .alert("Scheduling Conflict", isPresented: $showingConflictWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Create Anyway") {
                    createEventFromTemplate()
                }
            } message: {
                if let firstConflict = conflicts.first {
                    Text(firstConflict.description + (conflicts.count > 1 ? " (and \(conflicts.count - 1) more)" : ""))
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var templateColor: Color {
        Color(hex: template.color) ?? .blue
    }

    // MARK: - Methods

    private func loadExistingEvents() {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { event in
                event.startDate >= dayStart && event.startDate < dayEnd
            }
        )

        do {
            existingEvents = try modelContext.fetch(descriptor)
            checkForConflicts()
        } catch {
            print("Error loading existing events: \(error)")
        }
    }

    private func checkForConflicts() {
        // Create temporary event to check conflicts
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        guard let tempStartDate = calendar.date(
            bySettingHour: startComponents.hour ?? 10,
            minute: startComponents.minute ?? 0,
            second: 0,
            of: date
        ),
        let tempEndDate = calendar.date(
            bySettingHour: endComponents.hour ?? 11,
            minute: endComponents.minute ?? 0,
            second: 0,
            of: date
        ) else {
            return
        }

        let tempEvent = Event(
            title: template.displayName,
            startDate: tempStartDate,
            endDate: tempEndDate
        )

        conflicts = ConflictDetector.detectConflicts(
            for: tempEvent,
            in: existingEvents
        )
    }

    private func checkConflictsAndCreate() {
        if !conflicts.isEmpty {
            showingConflictWarning = true
        } else {
            createEventFromTemplate()
        }
    }

    private func createEventFromTemplate() {
        // Prevent multiple saves
        guard !isSaving else { return }
        isSaving = true

        // Combine date with time
        let calendar = Calendar.current

        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        guard let finalStartDate = calendar.date(
            bySettingHour: startComponents.hour ?? 10,
            minute: startComponents.minute ?? 0,
            second: 0,
            of: date
        ),
        let finalEndDate = calendar.date(
            bySettingHour: endComponents.hour ?? 11,
            minute: endComponents.minute ?? 0,
            second: 0,
            of: date
        ) else {
            isSaving = false
            return
        }

        // Create event
        let event = Event(
            title: template.displayName,
            startDate: finalStartDate,
            endDate: finalEndDate,
            eventType: template.eventType
        )

        modelContext.insert(event)

        do {
            try modelContext.save()
            isSaving = false
            dismiss()
        } catch {
            print("Error creating event from template: \(error)")
            isSaving = false
        }
    }
}

// MARK: - Preview
#Preview {
    TemplateCustomizeView(
        template: Template.defaultTemplates[0],
        date: Date()
    )
    .modelContainer(ModelContainer.preview)
}
