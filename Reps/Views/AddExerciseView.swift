//
//  AddExerciseView.swift
//  Reps
//
//  Screen 3 — add an exercise with inline ghost-text autocomplete.
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var typed = ""
    @FocusState private var focused: Bool

    /// The catalog entry whose name begins with what's typed, if any.
    private var suggestion: CatalogEntry? {
        ExerciseCatalog.firstMatch(for: typed)
    }

    /// The un-typed remainder of the suggestion, shown as dimmed ghost text.
    private var ghostSuffix: String {
        guard let suggestion, !typed.isEmpty,
              suggestion.name.count > typed.count else { return "" }
        return String(suggestion.name.dropFirst(typed.count))
    }

    /// The type badge reflects what would be created right now.
    private var resolvedType: ExerciseType? {
        let trimmed = typed.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return suggestion?.type ?? ExerciseCatalog.type(for: trimmed)
    }

    private var canCreate: Bool {
        !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            navBar
                .padding(.top, 12)
                .padding(.bottom, 28)

            if let last = routine.orderedExercises.last {
                Text(last.name)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Theme.secondary)
                    .padding(.vertical, 16)
                Divider().overlay(Theme.divider)
            }

            inputField
                .padding(.top, 20)

            HStack {
                Text("Double-tap return to accept")
                    .foregroundStyle(Theme.secondary)
                Spacer()
                if let resolvedType {
                    Text(resolvedType.badge)
                        .foregroundStyle(Theme.accent)
                }
            }
            .font(.system(size: 13, design: .monospaced))
            .padding(.top, 10)
            .padding(.bottom, 12)

            Divider().overlay(Theme.divider)

            Spacer()

            Button("Cancel") { dismiss() }
                .font(.system(size: 17))
                .foregroundStyle(Theme.secondary)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background)
        .onAppear { focused = true }
    }

    private var navBar: some View {
        HStack {
            Text(routine.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.primary)
            Spacer()
            Button(action: create) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(canCreate ? Theme.primary : Theme.secondary)
            }
            .disabled(!canCreate)
        }
    }

    private var inputField: some View {
        HStack(spacing: 0) {
            TextField("", text: $typed)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Theme.primary)
                .tint(Theme.accent)
                .focused($focused)
                .submitLabel(.next)
                .onSubmit(handleReturn)
                .fixedSize()
            Text(ghostSuffix)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Theme.secondary)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Actions

    /// First return accepts the ghost suggestion; a second return (nothing left
    /// to accept) creates the exercise.
    private func handleReturn() {
        if !ghostSuffix.isEmpty, let suggestion {
            typed = suggestion.name
            focused = true
        } else {
            create()
        }
    }

    private func create() {
        let name = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let type = suggestion?.type ?? ExerciseCatalog.type(for: name)
        let exercise = Exercise(name: name, type: type, sortIndex: routine.nextExerciseSortIndex)
        exercise.routine = routine
        routine.exercises.append(exercise)
        try? context.save()
        dismiss()
    }
}
