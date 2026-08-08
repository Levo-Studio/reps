//
//  RestingHeaderView.swift
//  Reps
//
//  Pinned rest bar shown above the active-routine list while the timer runs.
//  Replaces the old full-screen rest view so the exercise list stays in place.
//

import SwiftUI

/// A slim header pinned above the exercise list during rest: a "Resting" label,
/// a tappable monospaced countdown that opens a menu to change or skip the rest,
/// and a thin draining progress bar for the remaining time.
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
        HStack {
            Text("Resting")
                .font(.system(size: 17))
                .foregroundStyle(Theme.secondary)
            Spacer()
            // Tapping the countdown adjusts the rest length or skips it — the
            // only affordance, no dedicated settings screen.
            Menu {
                ForEach(RestTimerController.durationOptions, id: \.self) { option in
                    Button(Self.durationLabel(option)) { timer.restart(with: option) }
                }
                Divider()
                Button("Skip rest", role: .destructive) { timer.stop() }
            } label: {
                Text(timer.remainingText)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.accent)
            }
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
