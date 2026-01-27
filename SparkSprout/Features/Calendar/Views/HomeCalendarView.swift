//
//  HomeCalendarView.swift
//  SparkSprout
//
//  Main calendar view with month/week toggle and navigation
//

import SwiftUI
import SwiftData

struct HomeCalendarView: View {
    @State private var viewModel = CalendarViewModel()
    @State private var showingDayDetail = false
    @State private var showingQuickAdd = false
    @State private var gridRefreshTrigger = UUID()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Calendar header with navigation and view mode toggle
                    CalendarHeaderView(
                        currentMonth: viewModel.headerTitle,
                        viewMode: viewModel.viewMode,
                        onPrevious: {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.moveToPrevious()
                            }
                        },
                        onNext: {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.moveToNext()
                            }
                        },
                        onToday: {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.selectToday()
                            }
                        },
                        onViewModeChanged: { mode in
                            withAnimation(Theme.Animation.standard) {
                                viewModel.setViewMode(mode)
                            }
                        }
                    )

                    Divider()
                        .padding(.vertical, Theme.Spacing.sm)

                    // Calendar content based on view mode
                    Group {
                        switch viewModel.viewMode {
                        case .month:
                            // Month grid view
                            ScrollView {
                                MonthGridView(
                                    paddedDays: viewModel.paddedDaysForGrid(),
                                    selectedDate: viewModel.selectedDate,
                                    month: viewModel.currentMonth,
                                    onDateSelected: { date in
                                        withAnimation(Theme.Animation.quick) {
                                            viewModel.selectDate(date)
                                        }
                                        showingDayDetail = true
                                    },
                                    refreshTrigger: gridRefreshTrigger
                                )
                                .padding(.bottom, 100) // Extra padding for FAB
                            }

                        case .week:
                            // Week timeline view
                            WeekCalendarView(
                                weekDays: viewModel.daysInCurrentWeek(),
                                selectedDate: viewModel.selectedDate,
                                onDateSelected: { date in
                                    withAnimation(Theme.Animation.quick) {
                                        viewModel.selectDate(date)
                                    }
                                    showingDayDetail = true
                                },
                                refreshTrigger: gridRefreshTrigger
                            )
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

                    Spacer()
                }

                // Floating Quick Add Button
                HStack {
                    Spacer()
                    QuickAddButton(showingQuickAdd: $showingQuickAdd)
                        .padding(.trailing, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDayDetail) {
                DayDetailView(date: viewModel.selectedDate)
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddEventView()
            }
            .onChange(of: showingDayDetail) { oldValue, newValue in
                // Refresh calendar grid when returning from day detail
                if oldValue && !newValue {
                    gridRefreshTrigger = UUID()
                }
            }
            .onChange(of: showingQuickAdd) { oldValue, newValue in
                // Refresh calendar grid when returning from quick add
                if oldValue && !newValue {
                    gridRefreshTrigger = UUID()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HomeCalendarView()
        .modelContainer(ModelContainer.preview)
}
