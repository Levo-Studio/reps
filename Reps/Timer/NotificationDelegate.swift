//
//  NotificationDelegate.swift
//  Reps
//

import UserNotifications

/// Suppresses the banner for the rest-over notification while the app is in the
/// foreground — only the short sound plays, no "Rest over" banner.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.sound])
    }
}
