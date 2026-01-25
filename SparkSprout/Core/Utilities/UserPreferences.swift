//
//  UserPreferences.swift
//  SparkSprout
//
//  Manages user preferences and app state using UserDefaults
//  Centralized storage for onboarding status, feature tips, and user settings
//
//  Note: To enable iCloud sync for preferences across devices,
//  replace UserDefaults.standard with NSUbiquitousKeyValueStore.default
//

import Foundation

/// Manages user preferences and app state with iCloud sync
@Observable
final class UserPreferences {
    static let shared = UserPreferences()

    // Use iCloud Key-Value Storage for cross-device sync and persistence across installs
    private let store = NSUbiquitousKeyValueStore.default

    // Also keep local UserDefaults as a fallback
    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        // Feature tip flags
        static let hasSeenTemplateIntro = "hasSeenTemplateIntro"
        static let hasSeenConflictTip = "hasSeenConflictTip"
        static let hasSeenStreakTip = "hasSeenStreakTip"
        // Reminder settings
        static let highlightReminderEnabled = "highlightReminderEnabled"
        static let highlightReminderHour = "highlightReminderHour"
        static let highlightReminderMinute = "highlightReminderMinute"
    }

    // MARK: - Properties

    /// Whether the user has completed the onboarding flow
    var hasCompletedOnboarding: Bool {
        get { store.bool(forKey: Keys.hasCompletedOnboarding) }
        set {
            store.set(newValue, forKey: Keys.hasCompletedOnboarding)
            store.synchronize() // Force immediate sync to iCloud
            // Also sync to UserDefaults for @AppStorage compatibility
            defaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }

    // MARK: - Feature Tips

    /// Whether the user has seen the template introduction
    var hasSeenTemplateIntro: Bool {
        get { store.bool(forKey: Keys.hasSeenTemplateIntro) }
        set {
            store.set(newValue, forKey: Keys.hasSeenTemplateIntro)
            store.synchronize()
        }
    }

    /// Whether the user has seen the conflict detection tip
    var hasSeenConflictTip: Bool {
        get { store.bool(forKey: Keys.hasSeenConflictTip) }
        set {
            store.set(newValue, forKey: Keys.hasSeenConflictTip)
            store.synchronize()
        }
    }

    /// Whether the user has seen the streak tracking tip
    var hasSeenStreakTip: Bool {
        get { store.bool(forKey: Keys.hasSeenStreakTip) }
        set {
            store.set(newValue, forKey: Keys.hasSeenStreakTip)
            store.synchronize()
        }
    }

    // MARK: - Reminder Settings

    /// Whether daily highlight reminders are enabled
    var highlightReminderEnabled: Bool {
        get {
            // Default to true if never set
            guard store.object(forKey: Keys.highlightReminderEnabled) != nil else {
                return true
            }
            return store.bool(forKey: Keys.highlightReminderEnabled)
        }
        set {
            store.set(newValue, forKey: Keys.highlightReminderEnabled)
            store.synchronize()
            defaults.set(newValue, forKey: Keys.highlightReminderEnabled)
        }
    }

    /// The hour component of the reminder time (0-23, default: 20 for 8 PM)
    var highlightReminderHour: Int {
        get {
            let hour = store.longLong(forKey: Keys.highlightReminderHour)
            return hour == 0 && store.object(forKey: Keys.highlightReminderHour) == nil ? 20 : Int(hour)
        }
        set {
            store.set(Int64(newValue), forKey: Keys.highlightReminderHour)
            store.synchronize()
            defaults.set(newValue, forKey: Keys.highlightReminderHour)
        }
    }

    /// The minute component of the reminder time (0-59, default: 0)
    var highlightReminderMinute: Int {
        get {
            let minute = store.longLong(forKey: Keys.highlightReminderMinute)
            return Int(minute)
        }
        set {
            store.set(Int64(newValue), forKey: Keys.highlightReminderMinute)
            store.synchronize()
            defaults.set(newValue, forKey: Keys.highlightReminderMinute)
        }
    }

    /// Get the reminder time as a Date object
    var highlightReminderTime: Date {
        get {
            let calendar = Calendar.current
            let components = DateComponents(hour: highlightReminderHour, minute: highlightReminderMinute)
            return calendar.date(from: components) ?? Date()
        }
        set {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: newValue)
            highlightReminderHour = components.hour ?? 20
            highlightReminderMinute = components.minute ?? 0
        }
    }

    // MARK: - Initialization

    private init() {
        // Listen for iCloud changes from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleiCloudChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )

        // Debug: Check if iCloud is available
        if FileManager.default.ubiquityIdentityToken != nil {
            print("✅ iCloud is AVAILABLE - user is signed in")
        } else {
            print("⚠️ iCloud is NOT AVAILABLE - user may not be signed in to iCloud")
        }
    }

    // MARK: - Helper Methods

    /// Handle iCloud changes from other devices
    @objc private func handleiCloudChange(_ notification: Notification) {
        // Force UI update when iCloud syncs from another device
        store.synchronize()

        // Sync iCloud changes back to UserDefaults for @AppStorage to detect
        defaults.set(store.bool(forKey: Keys.hasCompletedOnboarding), forKey: Keys.hasCompletedOnboarding)
        defaults.set(store.bool(forKey: Keys.hasSeenTemplateIntro), forKey: Keys.hasSeenTemplateIntro)
        defaults.set(store.bool(forKey: Keys.hasSeenConflictTip), forKey: Keys.hasSeenConflictTip)
        defaults.set(store.bool(forKey: Keys.hasSeenStreakTip), forKey: Keys.hasSeenStreakTip)
        defaults.set(store.bool(forKey: Keys.highlightReminderEnabled), forKey: Keys.highlightReminderEnabled)
        defaults.set(Int(store.longLong(forKey: Keys.highlightReminderHour)), forKey: Keys.highlightReminderHour)
        defaults.set(Int(store.longLong(forKey: Keys.highlightReminderMinute)), forKey: Keys.highlightReminderMinute)
    }

    /// Reset all preferences to defaults (useful for testing)
    func reset() {
        store.removeObject(forKey: Keys.hasCompletedOnboarding)
        store.removeObject(forKey: Keys.hasSeenTemplateIntro)
        store.removeObject(forKey: Keys.hasSeenConflictTip)
        store.removeObject(forKey: Keys.hasSeenStreakTip)
        store.removeObject(forKey: Keys.highlightReminderEnabled)
        store.removeObject(forKey: Keys.highlightReminderHour)
        store.removeObject(forKey: Keys.highlightReminderMinute)
        store.synchronize()
    }
}
