//
//  TemplateFormViewModel.swift
//  DayGlow
//
//  ViewModel for creating and editing custom templates
//

import Foundation
import SwiftUI
import Observation

@Observable
final class TemplateFormViewModel {
    // MARK: - Form Fields
    var displayName: String = ""
    var selectedIcon: String = "star.fill"
    var selectedCategory: TemplateCategory = .selfCare
    var selectedEventType: String = Event.EventType.personal
    var selectedColor: String = "#FFB6C1"
    var durationHours: Int = 1
    var durationMinutes: Int = 0
    var checklistItems: [String] = []
    var newChecklistItem: String = ""

    // MARK: - State
    var showingIconPicker: Bool = false
    var showingColorPicker: Bool = false
    var isValid: Bool = false

    // MARK: - Available Options
    let availableIcons = [
        "star.fill", "heart.fill", "sparkles", "sun.max.fill", "moon.stars.fill",
        "figure.run", "book.fill", "paintbrush.fill", "fork.knife", "cup.and.saucer.fill",
        "headphones", "music.note", "camera.fill", "photo.fill", "video.fill",
        "gamecontroller.fill", "airplane", "car.fill", "bicycle", "figure.walk",
        "dumbbell.fill", "sportscourt.fill", "tennis.racket", "basketball.fill",
        "checkmark.circle.fill", "plus.circle.fill", "pencil.circle.fill", "trash.fill",
        "folder.fill", "doc.fill", "calendar", "clock.fill", "bell.fill",
        "lightbulb.fill", "brain.head.profile", "person.fill", "person.2.fill",
        "figure.2.and.child.holdinghands", "pawprint.fill", "leaf.fill", "tree.fill"
    ]

    let availableColors = [
        "#FFB6C1", // Pink
        "#FF9999", // Coral
        "#FFD700", // Gold
        "#FFE4B5", // Moccasin
        "#98D8C8", // Teal
        "#90EE90", // Light Green
        "#87CEEB", // Sky Blue
        "#ADD8E6", // Light Blue
        "#B19CD9", // Purple
        "#DDA0DD", // Plum
        "#E6E6FA", // Lavender
        "#FFA07A", // Light Salmon
        "#F0E68C", // Khaki
        "#D3D3D3"  // Light Gray
    ]

    // MARK: - Initialization
    init(template: Template? = nil) {
        if let template = template {
            // Editing existing template
            self.displayName = template.displayName
            self.selectedIcon = template.icon
            self.selectedCategory = TemplateCategory(rawValue: template.category) ?? .selfCare
            self.selectedEventType = template.eventType
            self.selectedColor = template.color
            self.durationHours = Int(template.defaultDuration) / 3600
            self.durationMinutes = (Int(template.defaultDuration) % 3600) / 60
            self.checklistItems = template.suggestedChecklist ?? []
        } else {
            // Creating new template - use category default color
            self.selectedColor = TemplateCategory.selfCare.color
        }
        validateForm()
    }

    // MARK: - Validation
    func validateForm() {
        isValid = !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  (durationHours > 0 || durationMinutes > 0)
    }

    // MARK: - Checklist Management
    func addChecklistItem() {
        let trimmed = newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        checklistItems.append(trimmed)
        newChecklistItem = ""
    }

    func removeChecklistItem(at index: Int) {
        guard checklistItems.indices.contains(index) else { return }
        checklistItems.remove(at: index)
    }

    func moveChecklistItem(from source: IndexSet, to destination: Int) {
        checklistItems.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Color & Icon Selection
    func selectIcon(_ icon: String) {
        selectedIcon = icon
        showingIconPicker = false
    }

    func selectColor(_ color: String) {
        selectedColor = color
        showingColorPicker = false
    }

    // MARK: - Category Change Handler
    func updateCategory(_ category: TemplateCategory) {
        selectedCategory = category
        // Auto-update color to match category
        selectedColor = category.color
    }

    // MARK: - Template Creation
    func createTemplate() -> Template {
        let duration = TimeInterval(durationHours * 3600 + durationMinutes * 60)
        let internalName = displayName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)

        return Template(
            name: internalName,
            displayName: displayName,
            icon: selectedIcon,
            defaultDuration: duration,
            eventType: selectedEventType,
            color: selectedColor,
            suggestedChecklist: checklistItems.isEmpty ? nil : checklistItems,
            isCustom: true,
            category: selectedCategory
        )
    }

    func updateTemplate(_ template: Template) {
        template.displayName = displayName
        template.icon = selectedIcon
        template.category = selectedCategory.rawValue
        template.eventType = selectedEventType
        template.color = selectedColor
        template.defaultDuration = TimeInterval(durationHours * 3600 + durationMinutes * 60)
        template.suggestedChecklist = checklistItems.isEmpty ? nil : checklistItems
    }

    // MARK: - Computed Properties
    var totalDuration: TimeInterval {
        TimeInterval(durationHours * 3600 + durationMinutes * 60)
    }

    var durationFormatted: String {
        if durationHours > 0 && durationMinutes > 0 {
            return "\(durationHours)h \(durationMinutes)m"
        } else if durationHours > 0 {
            return "\(durationHours)h"
        } else if durationMinutes > 0 {
            return "\(durationMinutes)m"
        } else {
            return "0m"
        }
    }
}
