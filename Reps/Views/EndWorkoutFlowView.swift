//
//  EndWorkoutFlowView.swift
//  Reps
//
//  The end-of-workout flow triggered by the checkmark on Screen 2:
//  review (chips) → export preview (card) → saved. "Done" ends the session and
//  returns to Screen 1; the ■ button dismisses back to Screen 2 intact.
//

import SwiftUI

struct EndWorkoutFlowView: View {
    let routine: Routine
    /// Ends the session and returns to Screen 1.
    let onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Phase { case review, preview, saved }
    @State private var phase: Phase = .review
    @State private var isSaving = false
    private let date = Date()

    /// Exercises that actually have a logged set.
    private var loggedExercises: [Exercise] {
        routine.orderedExercises.filter { !$0.sets.isEmpty }
    }

    private var allSets: [SetEntry] {
        routine.exercises.flatMap(\.sets)
    }

    private var totalVolume: Double {
        allSets.reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps) }
    }

    private var totalSets: Int { allSets.count }

    private var totalReps: Int { allSets.reduce(0) { $0 + $1.reps } }

    private var card: SummaryCardView {
        SummaryCardView(
            routineName: routine.name,
            date: date,
            totalVolume: totalVolume,
            totalSets: totalSets,
            totalReps: totalReps,
            exerciseCount: loggedExercises.count
        )
    }

    /// Same card as on-screen but with square corners for a clean, full-bleed
    /// export. Passed to `PhotoSaver.save` so the saved image has no rounded corners.
    private var exportCard: SummaryCardView {
        SummaryCardView(
            routineName: routine.name,
            date: date,
            totalVolume: totalVolume,
            totalSets: totalSets,
            totalReps: totalReps,
            exerciseCount: loggedExercises.count,
            cornerRadius: 0
        )
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch phase {
            case .review: reviewScreen
            case .preview: previewScreen
            case .saved: savedScreen
            }
        }
    }

    // MARK: - Review (Screen: image #4)

    private var reviewScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S WORKOUT")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.secondary)
                    Text(routine.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.primary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.primary)
                        .frame(width: 40, height: 40)
                        .background(Theme.surfaceRaised, in: Circle())
                }
                .accessibilityLabel("Stop")
            }
            .padding(.top, 12)
            .padding(.bottom, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(loggedExercises) { exercise in
                        exerciseChips(exercise)
                    }
                }
            }

            Spacer()

            VStack(spacing: 12) {
                secondaryButton("Save to Gallery") { phase = .preview }
                primaryButton("Done", action: onFinish)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func exerciseChips(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.name)
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondary)
            HStack(spacing: 8) {
                ForEach(exercise.orderedSets) { set in
                    Text(chipText(for: exercise.type, weight: set.weight, reps: set.reps))
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Theme.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func chipText(for type: ExerciseType, weight: Double?, reps: Int) -> String {
        if type == .weightAndReps {
            return "\(Format.weight(weight ?? 0))kg × \(reps)"
        }
        return "\(reps) reps"
    }

    // MARK: - Export preview (Screen 5)

    private var previewScreen: some View {
        VStack(spacing: 0) {
            Text("REPS")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.secondary)
                .padding(.top, 20)

            Spacer()
            card
            Spacer()

            VStack(spacing: 12) {
                secondaryButton("Back") { phase = .review }
                primaryButton(isSaving ? "Saving…" : "Save to Gallery") { Task { await saveCard() } }
                    .disabled(isSaving)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Saved (Screen 6)

    private var savedScreen: some View {
        VStack(spacing: 0) {
            Text("REPS")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.secondary)
                .padding(.top, 20)

            Spacer()
            card
            Spacer()

            VStack(spacing: 16) {
                Text("Saved to Gallery!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.primary)
                Image(systemName: "arrow.down.to.line")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }

            Spacer()

            primaryButton("Done", action: onFinish)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Actions

    private func saveCard() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await PhotoSaver.save(exportCard)
            phase = .saved
        } catch {
            // Permission denied or render failure — stay on the preview screen.
        }
    }

    // MARK: - Buttons

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
