//
//  DayDetailView.swift
//  DayGlow
//
//  Complete day detail view showing schedule and highlight
//

import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allEvents: [Event]
    @Query private var allDayEntries: [DayEntry]

    @State private var showingAddEvent = false
    @State private var selectedEvent: Event?
    @State private var showingTemplates = false

    // Filter events for this specific day
    private var dayEvents: [Event] {
        allEvents.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
    }

    // Get day entry for this date (binding-compatible)
    private var dayEntryBinding: Binding<DayEntry?> {
        Binding(
            get: { allDayEntries.first { Calendar.current.isDate($0.date, inSameDayAs: date) } },
            set: { _ in }
        )
    }

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Date header
                    VStack(spacing: 4) {
                        Text(dateFormatted)
                            .font(Theme.Typography.title2)
                            .fontWeight(.bold)

                        if isToday {
                            Text("Today")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, Theme.Spacing.md)

                    // Highlight card
                    HighlightCardView(date: date, dayEntry: dayEntryBinding)

                    Divider()
                        .padding(.vertical, Theme.Spacing.sm)

                    // Schedule
                    DayScheduleView(
                        events: dayEvents,
                        onEventTap: { event in
                            selectedEvent = event
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("Day Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingAddEvent = true }) {
                            Label("Add Event", systemImage: "calendar.badge.plus")
                        }

                        Button(action: { showingTemplates = true }) {
                            Label("Use Template", systemImage: "square.grid.2x2")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEditEventView(date: date)
            }
            .sheet(item: $selectedEvent) { event in
                AddEditEventView(event: event, date: date)
            }
            .sheet(isPresented: $showingTemplates) {
                TemplatesView(date: date)
            }
        }
    }

}

// MARK: - Preview
#Preview {
    DayDetailView(date: Date())
        .modelContainer(ModelContainer.preview)
}
