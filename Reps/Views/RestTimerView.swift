//
//  RestTimerView.swift
//  Reps
//
//  Screen 4 — the focused rest view shown while the timer runs and the app is
//  foregrounded. Tapping anywhere returns to Screen 2; it also auto-returns
//  when the timer ends.
//

import SwiftUI

struct RestTimerView: View {
    let routine: Routine
    @Environment(RestTimerController.self) private var timer
    @Environment(WorkoutSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    /// The exercise the next set belongs to, resolved from the timer context.
    private var currentExercise: Exercise? {
        routine.orderedExercises.first { $0.name == timer.nextExercise }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            progressBar
                .padding(.top, 12)

            Divider().overlay(Theme.divider)
                .padding(.top, 20)

            Text(routine.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.primary)
                .padding(.top, 24)

            if let exercise = currentExercise {
                Text(exercise.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 20)
                    .padding(.bottom, 4)

                ForEach(Array(session.sets(for: exercise.id).enumerated()), id: \.element.id) { index, set in
                    readonlyRow(number: index + 1, type: exercise.type, weight: set.weight, reps: set.reps)
                    Divider().overlay(Theme.divider)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .onChange(of: timer.isRunning) { _, running in
            if !running { dismiss() }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Resting")
                .font(.system(size: 17))
                .foregroundStyle(Theme.secondary)
            Spacer()
            // Long-press / menu to adjust the rest length — the only affordance,
            // no dedicated settings screen.
            Menu {
                ForEach(RestTimerController.durationOptions, id: \.self) { option in
                    Button(Self.durationLabel(option)) { timer.restart(with: option) }
                }
            } label: {
                Text(timer.remainingText)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.accent)
            }
        }
    }

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

    private func readonlyRow(number: Int, type: ExerciseType, weight: Double?, reps: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(number)")
                .foregroundStyle(Theme.secondary)
            Spacer(minLength: 12)
            if type == .weightAndReps {
                Text("\(Format.weight(weight ?? 0)) kg × \(reps)")
                    .foregroundStyle(Theme.secondary)
            } else {
                Text("\(reps) reps")
                    .foregroundStyle(Theme.secondary)
            }
        }
        .font(.system(size: 17, design: .monospaced))
        .padding(.vertical, 12)
    }

    private static func durationLabel(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60, s = total % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }
}
