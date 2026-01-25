//
//  AddEditTemplateView.swift
//  SparkSprout
//
//  Form for creating and editing custom templates
//

import SwiftUI
import SwiftData

struct AddEditTemplateView: View {
    let template: Template? // nil for new template

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: TemplateFormViewModel
    @State private var showingDeleteConfirmation = false

    init(template: Template? = nil) {
        self.template = template
        _viewModel = State(initialValue: TemplateFormViewModel(template: template))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Template Details") {
                    TextField("Template Name", text: $viewModel.displayName)
                        .font(Theme.Typography.body)
                        .onChange(of: viewModel.displayName) {
                            viewModel.validateForm()
                        }

                    // Icon Picker
                    Button(action: { viewModel.showingIconPicker.toggle() }) {
                        HStack {
                            Text("Icon")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: viewModel.selectedIcon)
                                .foregroundStyle(Color(adaptiveHex: viewModel.selectedColor))
                                .font(.title2)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }

                    // Category Picker
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .onChange(of: viewModel.selectedCategory) {
                        viewModel.updateCategory(viewModel.selectedCategory)
                    }

                    // Event Type Picker
                    Picker("Event Type", selection: $viewModel.selectedEventType) {
                        Text("Personal").tag(Event.EventType.personal)
                        Text("Work").tag(Event.EventType.work)
                        Text("Social").tag(Event.EventType.social)
                        Text("Solo Date").tag(Event.EventType.soloDate)
                        Text("Cleaning").tag(Event.EventType.cleaning)
                        Text("Admin").tag(Event.EventType.admin)
                        Text("Deep Work").tag(Event.EventType.deepWork)
                    }
                }

                // Duration Section
                Section {
                    HStack {
                        Picker("Hours", selection: $viewModel.durationHours) {
                            ForEach(0..<13) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Text("h")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Picker("Minutes", selection: $viewModel.durationMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Text("m")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .onChange(of: viewModel.durationHours) { viewModel.validateForm() }
                    .onChange(of: viewModel.durationMinutes) { viewModel.validateForm() }

                    HStack {
                        Text("Total Duration")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Spacer()
                        Text(viewModel.durationFormatted)
                            .font(Theme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("Default Duration")
                }

                // Color Section
                Section("Appearance") {
                    Button(action: { viewModel.showingColorPicker.toggle() }) {
                        HStack {
                            Text("Color")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Circle()
                                .fill(Color(adaptiveHex: viewModel.selectedColor))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }

                // Checklist Section
                Section {
                    ForEach(Array(viewModel.checklistItems.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                            Text(item)
                                .font(Theme.Typography.body)
                            Spacer()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.removeChecklistItem(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove(perform: viewModel.moveChecklistItem)

                    // Add new item
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.blue)
                        TextField("Add activity...", text: $viewModel.newChecklistItem)
                            .font(Theme.Typography.body)
                            .onSubmit {
                                viewModel.addChecklistItem()
                            }
                    }
                } header: {
                    HStack {
                        Text("Suggested Activities")
                        Spacer()
                        if !viewModel.checklistItems.isEmpty {
                            Text("\(viewModel.checklistItems.count) items")
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                } footer: {
                    Text("Add activities or steps to include when using this template")
                        .font(Theme.Typography.caption)
                }

                // Delete button for existing templates
                if let template = template, template.isCustom {
                    Section {
                        Button(role: .destructive, action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Template")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(!viewModel.isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $viewModel.showingIconPicker) {
                iconPickerSheet
            }
            .sheet(isPresented: $viewModel.showingColorPicker) {
                colorPickerSheet
            }
            .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTemplate()
                }
            } message: {
                Text("Are you sure you want to delete this template? This action cannot be undone.")
            }
        }
    }

    // MARK: - Icon Picker Sheet
    private var iconPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: Theme.Spacing.md) {
                    ForEach(viewModel.availableIcons, id: \.self) { icon in
                        Button(action: {
                            viewModel.selectIcon(icon)
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(
                                        icon == viewModel.selectedIcon ?
                                        Color(adaptiveHex: viewModel.selectedColor) : .primary
                                    )
                                    .padding()
                                    .background(
                                        Group {
                                            if icon == viewModel.selectedIcon {
                                                Color(adaptiveHex: viewModel.selectedColor).opacity(0.15)
                                            } else {
                                                Theme.Colors.cardBackground
                                            }
                                        }
                                    )
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(
                                                icon == viewModel.selectedIcon ?
                                                Color(adaptiveHex: viewModel.selectedColor).opacity(0.5) : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.showingIconPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Color Picker Sheet
    private var colorPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: Theme.Spacing.md) {
                    ForEach(viewModel.availableColors, id: \.self) { color in
                        Button(action: {
                            viewModel.selectColor(color)
                        }) {
                            Circle()
                                .fill(Color(adaptiveHex: color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            color == viewModel.selectedColor ?
                                            Color.primary : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(
                                    color: color == viewModel.selectedColor ?
                                    Color.black.opacity(0.2) : Color.clear,
                                    radius: color == viewModel.selectedColor ? 3 : 0
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.showingColorPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func saveTemplate() {
        if let existingTemplate = template {
            // Update existing template
            viewModel.updateTemplate(existingTemplate)
        } else {
            // Create new template
            let newTemplate = viewModel.createTemplate()
            modelContext.insert(newTemplate)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving template: \(error)")
        }
    }

    private func deleteTemplate() {
        guard let templateToDelete = template else { return }

        modelContext.delete(templateToDelete)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting template: \(error)")
        }
    }
}

// MARK: - Preview
#Preview("New Template") {
    AddEditTemplateView()
        .modelContainer(ModelContainer.preview)
}

#Preview("Edit Template") {
    let template = Template(
        name: "test",
        displayName: "Test Template",
        icon: "star.fill",
        defaultDuration: 3600,
        eventType: Event.EventType.personal,
        color: "#FFB6C1",
        isCustom: true
    )

    return AddEditTemplateView(template: template)
        .modelContainer(ModelContainer.preview)
}
