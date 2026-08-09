//
//  NotificationDelegate.swift
//  Reps
//

import UserNotifications

/// While the app is in the foreground the rest-over sound is played through the
/// media session by `SoundPlayer` (so it ignores the silent switch), so the
/// notification presents nothing here — no banner and no duplicate sound. In the
/// background the notification still delivers its sound normally.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([])
    }
}
