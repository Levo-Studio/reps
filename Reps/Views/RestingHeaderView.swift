//
//  RestingHeaderView.swift
//  Reps
//
//  Pinned rest bar shown above the active-routine list while the timer runs.
//  Replaces the old full-screen rest view so the exercise list stays in place.
//

import SwiftUI

/// A slim header pinned above the exercise list during rest: a "Resting" label,
/// a monospaced countdown, and a trailing xmark button to end the rest. The
/// countdown long-presses to a menu of rest lengths; a thin draining progress
/// bar underneath tracks the remaining time.
struct RestingHeaderView: View {
    @Environment(RestTimerController.self) private var timer

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                progressBar
                    .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            Divider().overlay(Theme.divider)
        }
        .background(Theme.background)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Text("Resting")
                .font(.system(size: 17))
                .foregroundStyle(Theme.secondary)

            // Long-pressing the countdown adjusts the rest length — a secondary
            // affordance kept out of the way of the primary xmark control.
            Text(timer.remainingText)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.accent)
                .contextMenu {
                    ForEach(RestTimerController.durationOptions, id: \.self) { option in
                        Button(Self.durationLabel(option)) { timer.restart(with: option) }
                    }
                }

            Spacer()

            // The primary control: end/skip the rest.
            Button(action: timer.stop) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Skip rest")
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.divider)
                // Green represents time remaining; it drains as the rest elapses.
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * (1 - timer.progress))
            }
        }
        .frame(height: 2)
    }

    private static func durationLabel(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60, s = total % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }
}
