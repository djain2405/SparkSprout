//
//  ContactPickerView.swift
//  SparkSprout
//
//  UIViewControllerRepresentable wrapper for CNContactPickerViewController
//

import SwiftUI
import ContactsUI

/// Represents a selected contact with relevant information
struct SelectedContact: Identifiable, Equatable {
    let id = UUID()
    let identifier: String
    let name: String
    let email: String?
    let phoneNumber: String?

    var hasEmail: Bool {
        guard let email = email else { return false }
        return !email.isEmpty
    }

    var displayContact: String {
        if let email = email, !email.isEmpty {
            return email
        }
        if let phone = phoneNumber, !phone.isEmpty {
            return phone
        }
        return "No contact info"
    }
}

/// SwiftUI wrapper for the system contact picker
struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedContacts: [SelectedContact]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        // Allow selecting any contact
        picker.predicateForEnablingContact = NSPredicate(value: true)
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            let newContacts = contacts.compactMap { contact -> SelectedContact? in
                let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown"

                // Get first email address
                let email = contact.emailAddresses.first?.value as String?

                // Get first phone number
                let phoneNumber = contact.phoneNumbers.first?.value.stringValue

                // Skip if we already have this contact (by identifier)
                if parent.selectedContacts.contains(where: { $0.identifier == contact.identifier }) {
                    return nil
                }

                return SelectedContact(
                    identifier: contact.identifier,
                    name: name,
                    email: email,
                    phoneNumber: phoneNumber
                )
            }

            parent.selectedContacts.append(contentsOf: newContacts)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // User cancelled - nothing to do
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var contacts: [SelectedContact] = []
        @State private var showPicker = true

        var body: some View {
            VStack {
                Text("Selected: \(contacts.count)")
                ForEach(contacts) { contact in
                    Text(contact.name)
                }
            }
            .sheet(isPresented: $showPicker) {
                ContactPickerView(selectedContacts: $contacts)
            }
        }
    }

    return PreviewWrapper()
}
