//
//  DayDetailView.swift
//  SparkSprout
//
//  Complete day detail view showing schedule and highlight
//
//  Refactored with ViewModel + Repository pattern for clean architecture
//

import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dependencies) private var dependencies

    @State private var viewModel: DayDetailViewModel?
    @State private var showingAddEvent = false
    @State private var selectedEvent: Event?
    @State private var showingTemplates = false

    // Get day entry for this date (binding-compatible)
    private var dayEntryBinding: Binding<DayEntry?> {
        Binding(
            get: { viewModel?.dayEntry },
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

                    // Highlight card (with event-aware prompts)
                    HighlightCardView(
                        date: date,
                        events: viewModel?.events ?? [],
                        dayEntry: dayEntryBinding
                    )

                    Divider()
                        .padding(.vertical, Theme.Spacing.sm)

                    // Schedule
                    if let viewModel = viewModel {
                        DayScheduleView(
                            events: viewModel.events,
                            onEventTap: { event in
                                selectedEvent = event
                            }
                        )
                    }
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
            .task {
                if viewModel == nil {
                    viewModel = dependencies.makeDayDetailViewModel(for: date)
                }
                await viewModel?.loadData()
            }
            .refreshable {
                await viewModel?.loadData()
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
            .onChange(of: showingAddEvent) { oldValue, newValue in
                // Reload data when add event sheet is dismissed
                if oldValue == true && newValue == false {
                    Task {
                        await viewModel?.loadData()
                    }
                }
            }
            .onChange(of: showingTemplates) { oldValue, newValue in
                // Reload data when templates sheet is dismissed
                if oldValue == true && newValue == false {
                    Task {
                        await viewModel?.loadData()
                    }
                }
            }
            .onChange(of: selectedEvent) { oldValue, newValue in
                // Reload data when edit event sheet is dismissed
                if oldValue != nil && newValue == nil {
                    Task {
                        await viewModel?.loadData()
                    }
                }
            }
        }
    }

}

// MARK: - Preview
#Preview {
    DayDetailView(date: Date())
        .modelContainer(ModelContainer.preview)
}
