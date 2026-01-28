//
//  Attendee.swift
//  SparkSprout
//
//  SwiftData model for event attendees
//

import Foundation
import SwiftData

@Model
final class Attendee {
    // MARK: - Properties
    var id: UUID = UUID()
    var name: String = ""
    var email: String?
    var phoneNumber: String?
    var contactIdentifier: String? // CNContact.identifier for re-fetching contact info

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \Event.attendees)
    var event: Event?

    // MARK: - Computed Properties
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

    // MARK: - Initialization
    init(
        name: String,
        email: String? = nil,
        phoneNumber: String? = nil,
        contactIdentifier: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.contactIdentifier = contactIdentifier
    }
}
