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
    @Environment(RestTimerController.self) private var timer
    @Environment(CompletionStore.self) private var completion
    @Environment(\.modelContext) private var context
    let routineName: String

    @FocusState private var nameFocused: Bool
    /// Whether the name header is in its double-tap edit state.
    @State private var isEditingName = false
    /// Working copy of the name while editing, so an empty submit can be
    /// discarded without ever writing a blank name onto the model.
    @State private var draftName = ""

    private var sets: [SetEntry] { exercise.orderedSets }

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
                    isDone: completion.isDone(set.id),
                    onEdit: { weight, reps in
                        // Editing an existing set saves live to the routine — it
                        // never touches the rest timer (only marking done does).
                        set.weight = weight
                        set.reps = reps
                        exercise.recordIfBest(weight: weight, reps: reps)
                        try? context.save()
                    },
                    onToggleDone: {
                        // Marking a set done starts the rest for the next set;
                        // un-marking it stops the running rest. Completion is
                        // in-memory only (CompletionStore), never persisted.
                        let nowDone = completion.toggle(set.id)
                        if nowDone {
                            timer.start(
                                routineName: routineName,
                                nextExercise: exercise.name,
                                nextSetNumber: index + 2
                            )
                        } else {
                            timer.stop()
                        }
                    },
                    onDelete: { deleteSet(set) }
                )
                rowDivider
            }

            addSetRow
        }
    }

    // MARK: - Header

    /// The exercise name shows as plain text and only becomes editable on a
    /// double tap — a single tap does nothing, so the field can't be focused by
    /// accident. Editing commits on submit and on blur.
    private var header: some View {
        Group {
            if isEditingName {
                TextField("", text: $draftName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .tint(Theme.accent)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit { commitNameEdit() }
                    // Focus after the field is mounted to dodge the SwiftUI race
                    // where focusing during the Text→TextField swap is dropped.
                    .onAppear {
                        DispatchQueue.main.async { nameFocused = true }
                    }
                    .onChange(of: nameFocused) { _, focused in
                        if !focused { commitNameEdit() }
                    }
            } else {
                Text(exercise.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .onTapGesture(count: 2) { beginNameEdit() }
            }
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

    private func beginNameEdit() {
        draftName = exercise.name
        isEditingName = true
    }

    /// Commits (or discards) the drafted name and leaves edit mode. A blank name
    /// is discarded so the previous name is kept. The `isEditingName` guard makes
    /// the double fire from submit-then-blur idempotent.
    private func commitNameEdit() {
        guard isEditingName else { return }
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            exercise.name = trimmed
            try? context.save()
        }
        isEditingName = false
        nameFocused = false
    }

    private func deleteExercise() {
        context.delete(exercise)
        try? context.save()
    }

    private func deleteSet(_ set: SetEntry) {
        context.delete(set)
        exercise.sets.removeAll { $0.id == set.id }
        try? context.save()
    }

    /// Appends a new set — it only adds the row, never the rest timer (marking
    /// a set done is what starts the rest). The set is pre-filled from the
    /// previous set (or the exercise's baseline) and is then freely editable.
    private func addSet() {
        let last = sets.last
        let weight = exercise.type == .weightAndReps ? (last?.weight ?? exercise.bestWeight) : nil
        let reps = last?.reps ?? (exercise.bestReps > 0 ? exercise.bestReps : 10)

        let entry = SetEntry(weight: weight, reps: reps, order: exercise.nextSetOrder)
        entry.exercise = exercise
        exercise.sets.append(entry)
        exercise.recordIfBest(weight: weight, reps: reps)
        try? context.save()
    }
}
