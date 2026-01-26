//
//  HomeCalendarView.swift
//  SparkSprout
//
//  Main calendar view with month grid and navigation
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
                    // Calendar header with navigation
                    CalendarHeaderView(
                        currentMonth: viewModel.currentMonthFormatted,
                        onPrevious: {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.moveToPreviousMonth()
                            }
                        },
                        onNext: {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.moveToNextMonth()
                            }
                        },
                        onToday: {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.selectToday()
                            }
                        }
                    )

                    Divider()
                        .padding(.vertical, Theme.Spacing.sm)

                    // Month grid
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

// MARK: - Day Detail View (moved to separate file in next iteration)

// MARK: - Preview
#Preview {
    HomeCalendarView()
        .modelContainer(ModelContainer.preview)
}
