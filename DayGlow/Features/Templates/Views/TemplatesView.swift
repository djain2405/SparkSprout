//
//  TemplatesView.swift
//  DayGlow
//
//  View for selecting intentional day templates with category filtering
//

import SwiftUI
import SwiftData

struct TemplatesView: View {
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Template.sortOrder) private var allTemplates: [Template]

    @State private var selectedTemplate: Template?
    @State private var selectedCategory: TemplateCategory? = nil
    @State private var showingNewTemplate = false
    @State private var templateToEdit: Template?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var filteredTemplates: [Template] {
        if let category = selectedCategory {
            return allTemplates.filter { $0.category == category.rawValue }
        }
        return allTemplates
    }

    private var groupedTemplates: [(TemplateCategory, [Template])] {
        let grouped = Dictionary(grouping: filteredTemplates) { template in
            TemplateCategory(rawValue: template.category) ?? .selfCare
        }
        return TemplateCategory.allCases.compactMap { category in
            guard let templates = grouped[category], !templates.isEmpty else { return nil }
            return (category, templates)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Your Day")
                            .font(Theme.Typography.title)
                            .fontWeight(.bold)

                        Text("Select a template or create your own")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.horizontal)

                    // Create Custom Template Button
                    Button(action: {
                        showingNewTemplate = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Create Custom Template")
                                    .font(Theme.Typography.subheadline)
                                    .fontWeight(.semibold)
                                Text("Design your own intentional block")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(Theme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal)

                    // Category Filter
                    if allTemplates.count > 6 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.sm) {
                                categoryFilterButton(category: nil, label: "All")

                                ForEach(TemplateCategory.allCases, id: \.self) { category in
                                    if allTemplates.contains(where: { $0.category == category.rawValue }) {
                                        categoryFilterButton(category: category, label: category.rawValue)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Templates organized by category
                    if filteredTemplates.isEmpty {
                        emptyState
                    } else if selectedCategory == nil {
                        // Show all templates grouped by category
                        ForEach(groupedTemplates, id: \.0) { category, templates in
                            categorySection(category: category, templates: templates)
                        }
                    } else {
                        // Show filtered templates in grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredTemplates) { template in
                                templateCard(template)
                            }
                        }
                        .padding(.horizontal)
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
            .sheet(isPresented: $showingNewTemplate) {
                AddEditTemplateView()
            }
            .sheet(item: $templateToEdit) { template in
                AddEditTemplateView(template: template)
            }
        }
    }

    // MARK: - Category Section
    @ViewBuilder
    private func categorySection(category: TemplateCategory, templates: [Template]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(Color(hex: category.color) ?? .blue)
                Text(category.rawValue)
                    .font(Theme.Typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(templates.count)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(templates) { template in
                    templateCard(template)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Template Card
    @ViewBuilder
    private func templateCard(_ template: Template) -> some View {
        TemplateCardView(
            template: template,
            isSelected: selectedTemplate?.id == template.id,
            onTap: {
                selectedTemplate = template
            }
        )
        .contextMenu {
            if template.isCustom {
                Button(action: {
                    templateToEdit = template
                }) {
                    Label("Edit Template", systemImage: "pencil")
                }
            }
        }
    }

    // MARK: - Category Filter Button
    @ViewBuilder
    private func categoryFilterButton(category: TemplateCategory?, label: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 6) {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .font(.caption)
                }
                Text(label)
                    .font(Theme.Typography.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedCategory == category ?
                Color(hex: category?.color ?? "#FFB6C1")?.opacity(0.2) ?? .blue.opacity(0.2) :
                Theme.Colors.cardBackground
            )
            .foregroundStyle(
                selectedCategory == category ?
                Color(hex: category?.color ?? "#FFB6C1") ?? .blue :
                Theme.Colors.textSecondary
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        selectedCategory == category ?
                        Color(hex: category?.color ?? "#FFB6C1") ?? .blue :
                        .clear,
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No templates in this category")
                .font(Theme.Typography.headline)

            Text("Try a different category or create a custom template")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: {
                showingNewTemplate = true
            }) {
                Text("Create Template")
                    .font(Theme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .cornerRadius(Theme.CornerRadius.medium)
            }
            .padding(.top, Theme.Spacing.sm)
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
