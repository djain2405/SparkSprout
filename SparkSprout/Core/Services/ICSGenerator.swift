//
//  ICSGenerator.swift
//  SparkSprout
//
//  Service for generating ICS (iCalendar) files for event sharing
//

import Foundation

struct ICSGenerator {

    // MARK: - Public API

    /// Generates an ICS string for a single event
    /// - Parameter event: The event to convert to ICS format
    /// - Returns: A string containing the ICS file content
    static func generateICS(for event: Event) -> String {
        var icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//SparkSprout//iOS//EN
        CALSCALE:GREGORIAN
        METHOD:REQUEST
        BEGIN:VEVENT
        UID:\(event.id.uuidString)@sparksprout
        DTSTAMP:\(formatICSDate(Date()))
        DTSTART:\(formatICSDate(event.startDate))
        DTEND:\(formatICSDate(event.endDate))
        SUMMARY:\(escapeICSText(event.title))
        """

        // Add location if present
        if let location = event.location, !location.isEmpty {
            icsContent += "\nLOCATION:\(escapeICSText(location))"
        }

        // Add notes as description if present
        if let notes = event.notes, !notes.isEmpty {
            icsContent += "\nDESCRIPTION:\(escapeICSText(notes))"
        }

        // Add attendees
        if let attendees = event.attendees {
            for attendee in attendees {
                if let email = attendee.email, !email.isEmpty {
                    icsContent += "\nATTENDEE;CN=\(escapeICSText(attendee.name)):mailto:\(email)"
                } else if let phone = attendee.phoneNumber, !phone.isEmpty {
                    // Fallback to phone number if no email
                    icsContent += "\nATTENDEE;CN=\(escapeICSText(attendee.name)):tel:\(phone)"
                }
            }
        }

        // Add event type as category if present
        if let eventType = event.eventType {
            icsContent += "\nCATEGORIES:\(escapeICSText(eventType.uppercased()))"
        }

        // Add status based on tentative flag
        if event.isTentative {
            icsContent += "\nSTATUS:TENTATIVE"
        } else {
            icsContent += "\nSTATUS:CONFIRMED"
        }

        icsContent += """

        SEQUENCE:0
        END:VEVENT
        END:VCALENDAR
        """

        return icsContent
    }

    /// Generates an ICS file and returns its URL
    /// - Parameter event: The event to export
    /// - Returns: URL to the temporary ICS file, or nil if creation failed
    static func generateICSFile(for event: Event) -> URL? {
        let icsContent = generateICS(for: event)

        // Create a safe filename from the event title
        let safeTitle = event.title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .prefix(50)

        let fileName = "\(safeTitle).ics"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try icsContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing ICS file: \(error)")
            return nil
        }
    }

    /// Generates a human-readable share message for an event
    /// - Parameter event: The event to describe
    /// - Returns: A formatted string suitable for sharing
    static func generateShareMessage(for event: Event) -> String {
        var message = "You're invited to: \(event.title)"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short

        message += "\nWhen: \(dateFormatter.string(from: event.startDate))"
        message += " - \(DateFormatter.localizedString(from: event.endDate, dateStyle: .none, timeStyle: .short))"

        if let location = event.location, !location.isEmpty {
            message += "\nWhere: \(location)"
        }

        if let notes = event.notes, !notes.isEmpty {
            message += "\n\n\(notes)"
        }

        if let attendees = event.attendees, !attendees.isEmpty {
            message += "\n\nAttendees: \(attendees.map { $0.name }.joined(separator: ", "))"
        }

        message += "\n\nSent via SparkSprout"

        return message
    }

    // MARK: - Private Helpers

    /// Formats a date for ICS (RFC 5545 format)
    private static func formatICSDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    /// Escapes special characters for ICS format
    private static func escapeICSText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
    }
}
