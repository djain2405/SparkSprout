//
//  QuickAddParser.swift
//  SparkSprout
//
//  Natural language parser for quick event creation
//  Parses input like "Dinner w/ Asha 7pm Thu" into structured event data
//

import Foundation
import SwiftData

/// Parsed result from natural language event input
struct ParsedEvent {
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var eventType: String?

    /// Confidence score from 0.0 to 1.0
    var confidence: Double

    /// Human-readable summary of what was parsed
    var summary: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        let duration = Int(endDate.timeIntervalSince(startDate) / 60)
        return "\(title) - \(formatter.string(from: startDate)) (\(duration) min)"
    }
}

/// Service for parsing natural language event descriptions
final class QuickAddParser {

    // MARK: - Time Patterns

    private static let timePatterns: [(pattern: String, format: String)] = [
        // 12-hour formats
        (#"(\d{1,2}):(\d{2})\s*(am|pm|AM|PM)"#, "h:mm a"),
        (#"(\d{1,2})\s*(am|pm|AM|PM)"#, "h a"),
        (#"(\d{1,2}):(\d{2})"#, "H:mm"),
        // Common words
        (#"\b(noon)\b"#, "noon"),
        (#"\b(midnight)\b"#, "midnight"),
        (#"\b(morning)\b"#, "morning"),
        (#"\b(afternoon)\b"#, "afternoon"),
        (#"\b(evening)\b"#, "evening"),
        (#"\b(night)\b"#, "night"),
    ]

    // MARK: - Day Patterns

    private static let dayPatterns: [(pattern: String, offset: (Calendar, Date) -> Date?)] = [
        (#"\b(today)\b"#, { _, date in date }),
        (#"\b(tomorrow)\b"#, { cal, date in cal.date(byAdding: .day, value: 1, to: date) }),
        (#"\b(tmrw)\b"#, { cal, date in cal.date(byAdding: .day, value: 1, to: date) }),
        (#"\b(mon|monday)\b"#, { cal, date in nextWeekday(1, from: date, calendar: cal) }),
        (#"\b(tue|tues|tuesday)\b"#, { cal, date in nextWeekday(2, from: date, calendar: cal) }),
        (#"\b(wed|wednesday)\b"#, { cal, date in nextWeekday(3, from: date, calendar: cal) }),
        (#"\b(thu|thur|thurs|thursday)\b"#, { cal, date in nextWeekday(4, from: date, calendar: cal) }),
        (#"\b(fri|friday)\b"#, { cal, date in nextWeekday(5, from: date, calendar: cal) }),
        (#"\b(sat|saturday)\b"#, { cal, date in nextWeekday(6, from: date, calendar: cal) }),
        (#"\b(sun|sunday)\b"#, { cal, date in nextWeekday(0, from: date, calendar: cal) }),
    ]

    // MARK: - Duration Patterns

    private static let durationPatterns: [(pattern: String, minutes: Int)] = [
        (#"(\d+)\s*(hr|hour|hours|h)\b"#, 60),  // Multiplier per match
        (#"(\d+)\s*(min|mins|minutes|m)\b"#, 1),
        (#"\bquick\b"#, 15),
        (#"\bshort\b"#, 30),
        (#"\blong\b"#, 120),
    ]

    // MARK: - Event Type Keywords
    // Using string literals to keep parser decoupled from Event model

    private static let eventTypeKeywords: [(keywords: [String], type: String)] = [
        (["meeting", "sync", "standup", "review", "interview", "1:1", "one on one"], "work"),
        (["dinner", "lunch", "brunch", "breakfast", "coffee", "drinks", "happy hour", "party", "hangout"], "social"),
        (["gym", "workout", "run", "yoga", "exercise", "fitness"], "health"),
        (["clean", "cleaning", "organize", "laundry", "chores"], "cleaning"),
        (["admin", "bills", "errands", "appointments"], "admin"),
        (["focus", "deep work", "writing", "study", "coding", "work on"], "deep_work"),
        (["solo", "me time", "self care", "spa", "relax"], "solo_date"),
    ]

    // MARK: - Location Keywords

    private static let locationPrepositions = ["at", "in", "@"]

    // MARK: - Public API

    /// Parse a natural language event description
    /// - Parameters:
    ///   - input: Natural language string like "Dinner w/ Asha 7pm Thu"
    ///   - referenceDate: Date to use as reference (defaults to now)
    /// - Returns: ParsedEvent if successful, nil if parsing fails
    static func parse(_ input: String, referenceDate: Date = Date()) -> ParsedEvent? {
        let calendar = Calendar.current
        let lowercased = input.lowercased()
        var confidence = 0.0

        // 1. Extract time
        let (extractedTime, timeConfidence, _) = extractTime(from: lowercased, referenceDate: referenceDate)
        let startTime = extractedTime ?? defaultTime(for: referenceDate)
        confidence += timeConfidence

        // 2. Extract day
        let (extractedDay, dayConfidence) = extractDay(from: lowercased, referenceDate: referenceDate, calendar: calendar)
        confidence += dayConfidence

        // 3. Combine day and time
        var startDate: Date
        if let day = extractedDay {
            // Combine the extracted day with the extracted time
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)

            var combined = DateComponents()
            combined.year = dayComponents.year
            combined.month = dayComponents.month
            combined.day = dayComponents.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute

            startDate = calendar.date(from: combined) ?? referenceDate
        } else {
            startDate = startTime
        }

        // 4. Extract duration
        let (duration, durationConfidence) = extractDuration(from: lowercased)
        confidence += durationConfidence

        let endDate = calendar.date(byAdding: .minute, value: duration, to: startDate) ?? startDate.addingTimeInterval(TimeInterval(duration * 60))

        // 5. Extract event type
        let eventType = extractEventType(from: lowercased)
        if eventType != nil {
            confidence += 0.1
        }

        // 6. Extract location
        let location = extractLocation(from: input)
        if location != nil {
            confidence += 0.1
        }

        // 7. Extract title (clean remaining text)
        let title = extractTitle(from: input, lowercased: lowercased)

        guard !title.isEmpty else { return nil }

        // Normalize confidence to 0-1 range
        confidence = min(1.0, confidence)

        return ParsedEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            eventType: eventType,
            confidence: confidence
        )
    }

    // MARK: - Extraction Methods

    private static func extractTime(from text: String, referenceDate: Date) -> (Date?, Double, String?) {
        let calendar = Calendar.current

        // Check for specific time patterns
        for (pattern, format) in timePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(text.startIndex..., in: text)

            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let matchedString = String(text[Range(match.range, in: text)!])
                let remainingText = text.replacingOccurrences(of: matchedString, with: "").trimmingCharacters(in: .whitespaces)

                // Handle special time words
                switch format {
                case "noon":
                    var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
                    components.hour = 12
                    components.minute = 0
                    if let date = calendar.date(from: components) {
                        return (date, 0.4, remainingText)
                    }
                case "midnight":
                    var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
                    components.hour = 0
                    components.minute = 0
                    if let date = calendar.date(from: components) {
                        return (date, 0.4, remainingText)
                    }
                case "morning":
                    var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
                    components.hour = 9
                    components.minute = 0
                    if let date = calendar.date(from: components) {
                        return (date, 0.3, remainingText)
                    }
                case "afternoon":
                    var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
                    components.hour = 14
                    components.minute = 0
                    if let date = calendar.date(from: components) {
                        return (date, 0.3, remainingText)
                    }
                case "evening":
                    var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
                    components.hour = 18
                    components.minute = 0
                    if let date = calendar.date(from: components) {
                        return (date, 0.3, remainingText)
                    }
                case "night":
                    var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
                    components.hour = 20
                    components.minute = 0
                    if let date = calendar.date(from: components) {
                        return (date, 0.3, remainingText)
                    }
                default:
                    // Parse numeric time
                    if let time = parseNumericTime(matchedString, referenceDate: referenceDate, calendar: calendar) {
                        return (time, 0.4, remainingText)
                    }
                }
            }
        }

        return (nil, 0.0, nil)
    }

    private static func parseNumericTime(_ timeString: String, referenceDate: Date, calendar: Calendar) -> Date? {
        let cleaned = timeString.lowercased().trimmingCharacters(in: .whitespaces)

        // Try parsing "7pm", "7:30pm", "14:00" etc.
        let patterns: [(regex: String, hasMinutes: Bool, is24Hour: Bool)] = [
            (#"(\d{1,2}):(\d{2})\s*(am|pm)"#, true, false),
            (#"(\d{1,2})\s*(am|pm)"#, false, false),
            (#"(\d{1,2}):(\d{2})"#, true, true),
        ]

        for (pattern, hasMinutes, is24Hour) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(cleaned.startIndex..., in: cleaned)

            if let match = regex.firstMatch(in: cleaned, options: [], range: range) {
                var hour = 0
                var minute = 0

                if let hourRange = Range(match.range(at: 1), in: cleaned) {
                    hour = Int(cleaned[hourRange]) ?? 0
                }

                if hasMinutes, let minuteRange = Range(match.range(at: 2), in: cleaned) {
                    minute = Int(cleaned[minuteRange]) ?? 0
                }

                // Handle AM/PM
                if !is24Hour {
                    let ampmRange = hasMinutes ? match.range(at: 3) : match.range(at: 2)
                    if let range = Range(ampmRange, in: cleaned) {
                        let ampm = cleaned[range].lowercased()
                        if ampm == "pm" && hour != 12 {
                            hour += 12
                        } else if ampm == "am" && hour == 12 {
                            hour = 0
                        }
                    }
                }

                var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
                components.hour = hour
                components.minute = minute

                return calendar.date(from: components)
            }
        }

        return nil
    }

    private static func extractDay(from text: String, referenceDate: Date, calendar: Calendar) -> (Date?, Double) {
        for (pattern, offset) in dayPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(text.startIndex..., in: text)

            if regex.firstMatch(in: text, options: [], range: range) != nil {
                if let date = offset(calendar, referenceDate) {
                    return (date, 0.3)
                }
            }
        }

        // Check for date formats like "Jan 15", "1/15", "15th"
        // For now, return nil and let it default to today
        return (nil, 0.0)
    }

    private static func extractDuration(from text: String) -> (Int, Double) {
        var totalMinutes = 0
        var confidence = 0.0

        // Check for explicit durations
        for (pattern, multiplier) in durationPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(text.startIndex..., in: text)

            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if match.numberOfRanges > 1, let numRange = Range(match.range(at: 1), in: text) {
                    if let num = Int(text[numRange]) {
                        totalMinutes += num * multiplier
                        confidence = 0.2
                    }
                } else {
                    // Fixed duration keywords (quick, short, long)
                    totalMinutes = multiplier
                    confidence = 0.1
                }
            }
        }

        // Default duration if not specified
        if totalMinutes == 0 {
            totalMinutes = 60 // Default 1 hour
        }

        return (totalMinutes, confidence)
    }

    private static func extractEventType(from text: String) -> String? {
        for (keywords, type) in eventTypeKeywords {
            for keyword in keywords {
                if text.contains(keyword) {
                    return type
                }
            }
        }
        return nil
    }

    private static func extractLocation(from text: String) -> String? {
        // Look for "at [location]" or "@ [location]" patterns
        for prep in locationPrepositions {
            let pattern = #"\b"# + prep + #"\s+([A-Za-z0-9\s']+?)(?:\s+(?:at|on|for|tomorrow|today|\d|am|pm)|$)"#

            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(text.startIndex..., in: text)

            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let locationRange = Range(match.range(at: 1), in: text) {
                    let location = String(text[locationRange]).trimmingCharacters(in: .whitespaces)
                    // Filter out common words that aren't locations
                    let nonLocations = ["the", "a", "an", "my", "your"]
                    if !nonLocations.contains(location.lowercased()) && location.count > 1 {
                        return location.capitalized
                    }
                }
            }
        }

        return nil
    }

    private static func extractTitle(from originalText: String, lowercased: String) -> String {
        var title = originalText

        // Remove "at" + time patterns (e.g., "at 3 pm", "at 14:30")
        let atTimePatterns = [
            #"\bat\s+\d{1,2}:\d{2}\s*(am|pm|AM|PM)?"#,
            #"\bat\s+\d{1,2}\s*(am|pm|AM|PM)"#,
            #"\bat\s+(noon|midnight|morning|afternoon|evening|night)\b"#,
        ]

        for pattern in atTimePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: "")
            }
        }

        // Remove standalone time patterns (without "at")
        let timeRemovalPatterns = [
            #"\d{1,2}:\d{2}\s*(am|pm|AM|PM)?"#,
            #"\b\d{1,2}\s*(am|pm|AM|PM)"#,
            #"\b(noon|midnight)\b"#,
        ]

        for pattern in timeRemovalPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: "")
            }
        }

        // Remove "on" + day patterns (e.g., "on Saturday", "on Monday")
        let onDayPatterns = [
            #"\bon\s+(today|tomorrow|tmrw)\b"#,
            #"\bon\s+(mon|monday|tue|tues|tuesday|wed|wednesday|thu|thur|thurs|thursday|fri|friday|sat|saturday|sun|sunday)\b"#,
        ]

        for pattern in onDayPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: "")
            }
        }

        // Remove standalone day patterns (without "on")
        let dayRemovalPatterns = [
            #"\b(today|tomorrow|tmrw)\b"#,
            #"\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#,
            #"\b(mon|tue|tues|wed|thu|thur|thurs|fri|sat|sun)\b"#,
        ]

        for pattern in dayRemovalPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: "")
            }
        }

        // Remove "for" + duration patterns (e.g., "for 2 hours", "for 30 min")
        let forDurationPatterns = [
            #"\bfor\s+\d+\s*(hr|hour|hours|h|min|mins|minutes|m)\b"#,
        ]

        for pattern in forDurationPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: "")
            }
        }

        // Remove standalone duration patterns
        let durationRemovalPatterns = [
            #"\b\d+\s*(hr|hour|hours|h|min|mins|minutes|m)\b"#,
            #"\b(quick|short|long)\b"#,
        ]

        for pattern in durationRemovalPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: "")
            }
        }

        // Remove trailing prepositions that are now orphaned (e.g., "Meeting with Sarah at on" -> "Meeting with Sarah")
        let trailingPrepositionPattern = #"\s+(at|on|for|in)\s*$"#
        if let regex = try? NSRegularExpression(pattern: trailingPrepositionPattern, options: .caseInsensitive) {
            title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: "")
        }

        // Remove orphaned prepositions in the middle (multiple spaces around them indicate they're orphaned)
        // e.g., "Meeting  at  with Sarah" should become "Meeting with Sarah"
        let orphanedPrepositionPattern = #"\s+(at|on|for)\s+(?=(at|on|for|with|\s|$))"#
        if let regex = try? NSRegularExpression(pattern: orphanedPrepositionPattern, options: .caseInsensitive) {
            title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: " ")
        }

        // Clean up multiple spaces
        while title.contains("  ") {
            title = title.replacingOccurrences(of: "  ", with: " ")
        }

        // Final cleanup
        title = title
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,;:"))
            .trimmingCharacters(in: .whitespaces)

        // Remove any remaining trailing prepositions after cleanup
        let finalTrailingPreps = #"\s+(at|on|for|in)$"#
        if let regex = try? NSRegularExpression(pattern: finalTrailingPreps, options: .caseInsensitive) {
            title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(title.startIndex..., in: title), withTemplate: "")
        }

        // Capitalize first letter
        if let first = title.first {
            title = first.uppercased() + title.dropFirst()
        }

        return title
    }

    private static func defaultTime(for date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)

        // Default to next hour
        let hour = calendar.component(.hour, from: date)
        components.hour = min(hour + 1, 23)
        components.minute = 0

        return calendar.date(from: components) ?? date
    }

    private static func nextWeekday(_ targetWeekday: Int, from date: Date, calendar: Calendar) -> Date? {
        // Sunday = 1, Monday = 2, etc. in Calendar
        // Our input: Sunday = 0, Monday = 1, etc.
        let calendarWeekday = targetWeekday + 1
        let currentWeekday = calendar.component(.weekday, from: date)

        var daysToAdd = calendarWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }
}

// MARK: - Quick Add Suggestions

extension QuickAddParser {

    /// Generate example suggestions based on current context
    static func suggestions(for time: Date = Date()) -> [String] {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)

        // Context-aware suggestions
        if hour < 12 {
            return [
                "Coffee chat 10am",
                "Team standup 9:30am",
                "Gym session tomorrow morning",
            ]
        } else if hour < 17 {
            return [
                "Lunch with Sarah 12:30pm",
                "Focus time 2pm 2hr",
                "Quick call at 3pm",
            ]
        } else {
            return [
                "Dinner 7pm",
                "Yoga class tomorrow evening",
                "Movie night Friday",
            ]
        }
    }
}
