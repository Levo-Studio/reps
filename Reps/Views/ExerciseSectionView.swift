//
//  ExerciseSectionView.swift
//  Reps
//
//  One exercise on the active routine screen: an inline-editable name header,
//  the sets logged this session, and an Add Set affordance.
//

import SwiftUI
import SwiftData

struct ExerciseSectionView: View {
    @Bindable var exercise: Exercise
    @Environment(WorkoutSession.self) private var session
    @Environment(RestTimerController.self) private var timer
    @Environment(\.modelContext) private var context
    let routineName: String

    @FocusState private var nameFocused: Bool

    private var sets: [LoggedSet] { session.sets(for: exercise.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 4)

            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                LoggedSetRow(
                    number: index + 1,
                    type: exercise.type,
                    weight: set.weight,
                    reps: set.reps,
                    onEdit: { weight, reps in
                        // Editing an existing set saves live — it never starts
                        // the rest timer (only adding a new set does).
                        session.update(set, weight: weight, reps: reps)
                        exercise.recordIfBest(weight: weight, reps: reps)
                        try? context.save()
                    }
                )
                rowDivider
            }

            addSetRow
        }
    }

    // MARK: - Header

    /// The exercise name is an always-editable field — a single tap focuses it,
    /// and it saves when it loses focus (like editing a Notes title).
    private var header: some View {
        TextField("", text: $exercise.name)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(Theme.primary)
            .tint(Theme.accent)
            .focused($nameFocused)
            .submitLabel(.done)
            .onSubmit { commitNameEdit() }
            .onChange(of: nameFocused) { _, focused in
                if !focused { commitNameEdit() }
            }
            .padding(.top, 20)
            .padding(.bottom, 8)
            .contextMenu {
                Button(role: .destructive) { deleteExercise() } label: { Text("Delete") }
            }
    }

    private var addSetRow: some View {
        HStack {
            Text("+")
            Spacer()
            Text("Add Set")
        }
        .font(.system(size: 17))
        .foregroundStyle(Theme.secondary)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { addSet() }
    }

    private var rowDivider: some View {
        Divider().overlay(Theme.divider)
    }

    // MARK: - Actions

    private func commitNameEdit() {
        let trimmed = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { exercise.name = trimmed }
        try? context.save()
    }

    private func deleteExercise() {
        context.delete(exercise)
        try? context.save()
    }

    /// Appends a new set — this deliberate tap is what starts the rest timer.
    /// The set is pre-filled from the previous set (or the exercise's baseline)
    /// and is then freely editable inline.
    private func addSet() {
        let last = sets.last
        let weight = exercise.type == .weightAndReps ? (last?.weight ?? exercise.bestWeight) : nil
        let reps = last?.reps ?? (exercise.bestReps > 0 ? exercise.bestReps : 10)

        session.addSet(exerciseId: exercise.id, weight: weight, reps: reps)
        exercise.recordIfBest(weight: weight, reps: reps)
        try? context.save()

        timer.start(
            routineName: routineName,
            nextExercise: exercise.name,
            nextSetNumber: session.sets(for: exercise.id).count + 1
        )
    }
}
