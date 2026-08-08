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

    @State private var isEditingName = false
    @State private var isAddingSet = false
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
                        session.update(set, weight: weight, reps: reps)
                        exercise.recordIfBest(weight: weight, reps: reps)
                        try? context.save()
                    }
                )
                rowDivider
            }

            if isAddingSet {
                SetInputRow(
                    type: exercise.type,
                    leading: "\(sets.count + 1)",
                    initialWeight: exercise.bestWeight,
                    initialReps: exercise.bestReps,
                    onCommit: { weight, reps in
                        addSet(weight: weight, reps: reps)
                        isAddingSet = false
                    },
                    onCancel: { isAddingSet = false }
                )
                rowDivider
            } else {
                addSetRow
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if isEditingName {
            TextField("", text: $exercise.name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.primary)
                .tint(Theme.accent)
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit { commitNameEdit() }
                .padding(.top, 20)
                .padding(.bottom, 8)
        } else {
            Text(exercise.name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    isEditingName = true
                    nameFocused = true
                }
                .contextMenu {
                    Button(role: .destructive) { deleteExercise() } label: { Text("Delete") }
                }
        }
    }

    private func deleteExercise() {
        context.delete(exercise)
        try? context.save()
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
        .onTapGesture { isAddingSet = true }
    }

    private var rowDivider: some View {
        Divider().overlay(Theme.divider)
    }

    // MARK: - Actions

    private func commitNameEdit() {
        let trimmed = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { exercise.name = trimmed }
        try? context.save()
        isEditingName = false
    }

    private func addSet(weight: Double?, reps: Int) {
        session.addSet(exerciseId: exercise.id, weight: weight, reps: reps)
        exercise.recordIfBest(weight: weight, reps: reps)
        try? context.save()
        // Logging a set automatically starts the rest timer.
        timer.start(
            routineName: routineName,
            nextExercise: exercise.name,
            nextSetNumber: session.sets(for: exercise.id).count + 1
        )
    }
}
