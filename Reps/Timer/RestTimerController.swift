//
//  RestTimerController.swift
//  Reps
//

import Foundation
import Observation
import ActivityKit
import UserNotifications

/// Drives the rest timer: the in-app countdown (Screen 4), the Lock Screen
/// Live Activity, and the local notification fired on expiry.
///
/// A single timer runs at a time. Starting a new rest replaces any running one.
@MainActor
@Observable
final class RestTimerController {
    /// Default rest length, adjustable per the spec via a minimal affordance.
    static let defaultDuration: TimeInterval = 120

    /// Allowed rest lengths cycled through by the adjust affordance.
    static let durationOptions: [TimeInterval] = [60, 90, 120, 150, 180, 240]

    private(set) var isRunning = false
    private(set) var endDate: Date?
    private(set) var duration: TimeInterval = defaultDuration
    private(set) var remaining: TimeInterval = defaultDuration

    /// Context for the currently running rest, surfaced in both presentations.
    private(set) var routineName: String = ""
    private(set) var nextExercise: String = ""
    private(set) var nextSetNumber: Int = 0

    private var ticker: Timer?
    private var activity: Activity<RestActivityAttributes>?

    private let notificationID = "reps.rest.complete"

    /// Fraction of rest elapsed, 0…1 — the progress bar fills left to right.
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max((duration - remaining) / duration, 0), 1)
    }

    /// `mm:ss` for the in-app countdown.
    var remainingText: String {
        let clamped = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", clamped / 60, clamped % 60)
    }

    // MARK: - Lifecycle

    /// Starts a rest for `duration` seconds, replacing any running timer.
    func start(routineName: String, nextExercise: String, nextSetNumber: Int, duration: TimeInterval? = nil) {
        let length = duration ?? self.duration
        self.duration = length
        self.routineName = routineName
        self.nextExercise = nextExercise
        self.nextSetNumber = nextSetNumber

        let end = Date().addingTimeInterval(length)
        endDate = end
        remaining = length
        isRunning = true

        startTicker()
        scheduleNotification(at: end)
        startLiveActivity(endDate: end)
        // Hold a silent audio session so the ticker keeps running — and the chime
        // still fires — while the app is backgrounded.
        SoundPlayer.shared.beginKeepAlive()
    }

    /// Restarts the current rest from the top (used when the duration changes).
    func restart(with duration: TimeInterval) {
        guard isRunning else { self.duration = duration; return }
        start(routineName: routineName, nextExercise: nextExercise, nextSetNumber: nextSetNumber, duration: duration)
    }

    /// Stops the timer and clears both presentations without firing.
    func stop() {
        isRunning = false
        endDate = nil
        remaining = duration
        ticker?.invalidate()
        ticker = nil
        cancelNotification()
        endLiveActivity()
        // Release the keep-alive session so music returns to full volume.
        SoundPlayer.shared.stop()
    }

    private func finish() {
        isRunning = false
        remaining = 0
        ticker?.invalidate()
        ticker = nil
        // We're firing the chime in-process, so drop the pending notification to
        // avoid a double sound. If the app had been suspended instead, this line
        // never runs and the notification remains as the fallback.
        cancelNotification()
        SoundPlayer.shared.playRestOver()
        endLiveActivity()
    }

    // MARK: - Ticking

    private func startTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining <= 0 { finish() }
    }

    // MARK: - Notifications

    /// Requests notification permission once, up front.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(at date: Date) {
        cancelNotification()
        let content = UNMutableNotificationContent()
        // No title/body: we only want a short sound when rest is over, not a
        // "Rest over" text banner. The foreground delegate suppresses the banner
        // entirely and plays sound only.
        // A short, subtle custom sound. Add `RestComplete.caf` to the app
        // bundle to use it; iOS falls back to the default tone if absent.
        content.sound = UNNotificationSound(named: UNNotificationSoundName("RestComplete.caf"))
        content.interruptionLevel = .passive

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    // MARK: - Live Activity

    private func startLiveActivity(endDate: Date) {
        endLiveActivity()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = RestActivityAttributes(
            routineName: routineName,
            nextExercise: nextExercise,
            nextSetNumber: nextSetNumber
        )
        let state = RestActivityAttributes.ContentState(endDate: endDate, duration: duration)
        do {
            activity = try Activity.request(
                attributes: attributes,
                // No stale date: otherwise iOS marks the activity stale at the
                // end and shows a spinning "stale" indicator over the timer.
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            // No widget extension registered yet, or the user disabled Live
            // Activities — the in-app timer still works.
            activity = nil
        }
    }

    private func endLiveActivity() {
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
