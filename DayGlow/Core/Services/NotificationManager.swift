//
//  NotificationManager.swift
//  DayGlow
//
//  Service for managing local notifications for daily highlight reminders
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let preferences = UserPreferences.shared

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let dailyHighlightReminder = "daily_highlight_reminder"
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    // MARK: - Permission Request

    /// Request notification permissions from the user
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

            if granted {
                print("✅ Notification permission granted")
                // Schedule the daily reminder if enabled
                await scheduleDailyReminder()
            } else {
                print("⚠️ Notification permission denied")
            }

            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }

    /// Check current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Daily Reminder Scheduling

    /// Schedule or update the daily highlight reminder based on user preferences
    func scheduleDailyReminder() async {
        // Remove any existing reminders first
        cancelDailyReminder()

        // Only schedule if enabled in preferences
        guard preferences.highlightReminderEnabled else {
            print("ℹ️ Daily reminder disabled in preferences")
            return
        }

        // Check authorization
        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            print("⚠️ Cannot schedule reminder - authorization status: \(status)")
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time for your daily highlight! ✨"
        content.body = getContextualReminderMessage()
        content.sound = .default
        content.categoryIdentifier = "HIGHLIGHT_REMINDER"

        // Schedule for the specified time every day
        var dateComponents = DateComponents()
        dateComponents.hour = preferences.highlightReminderHour
        dateComponents.minute = preferences.highlightReminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create the request
        let request = UNNotificationRequest(
            identifier: NotificationID.dailyHighlightReminder,
            content: content,
            trigger: trigger
        )

        // Add the notification
        do {
            try await notificationCenter.add(request)
            let timeString = String(format: "%02d:%02d", preferences.highlightReminderHour, preferences.highlightReminderMinute)
            print("✅ Daily reminder scheduled for \(timeString)")
        } catch {
            print("❌ Error scheduling daily reminder: \(error)")
        }
    }

    /// Cancel the daily highlight reminder
    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationID.dailyHighlightReminder])
        print("🗑️ Cancelled daily reminder")
    }

    /// Get a contextual reminder message based on day of week
    private func getContextualReminderMessage() -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())

        switch weekday {
        case 1: // Sunday
            return "What made this week special?"
        case 2: // Monday
            return "What are you grateful for today?"
        case 3: // Tuesday
            return "What's one thing you learned today?"
        case 4: // Wednesday
            return "What's your win so far this week?"
        case 5: // Thursday
            return "Who made a positive impact on your day?"
        case 6: // Friday
            return "What brought you joy today?"
        case 7: // Saturday
            return "What surprised you today?"
        default:
            return "What made you smile today?"
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap/interaction
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // User tapped the notification - could navigate to highlight entry screen
        if response.notification.request.identifier == NotificationID.dailyHighlightReminder {
            print("📲 User tapped highlight reminder notification")
            // TODO: Post notification to open highlight entry screen
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenHighlightEntry"),
                    object: nil
                )
            }
        }

        completionHandler()
    }

    // MARK: - Debugging

    /// Get all pending notifications (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /// Print all pending notifications (for debugging)
    func printPendingNotifications() async {
        let requests = await getPendingNotifications()
        print("📋 Pending notifications (\(requests.count)):")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextDate = trigger.nextTriggerDate() {
                print("    Next trigger: \(nextDate)")
            }
        }
    }
}
