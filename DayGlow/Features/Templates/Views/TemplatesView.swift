//
//  TemplatesView.swift
//  DayGlow
//
//  View for selecting intentional day templates
//

import SwiftUI
import SwiftData

struct TemplatesView: View {
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Query private var templates: [Template]

    @State private var selectedTemplate: Template?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Your Day")
                            .font(Theme.Typography.title)
                            .fontWeight(.bold)

                        Text("Select a template to create an intentional day block")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.horizontal)

                    // Templates grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(templates) { template in
                            TemplateCardView(
                                template: template,
                                isSelected: selectedTemplate?.id == template.id,
                                onTap: {
                                    selectedTemplate = template
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    if templates.isEmpty {
                        emptyState
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Day Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateCustomizeView(template: template, date: date)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No templates available")
                .font(Theme.Typography.headline)

            Text("Templates help you schedule intentional days quickly")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    TemplatesView(date: Date())
        .modelContainer(ModelContainer.preview)
}
