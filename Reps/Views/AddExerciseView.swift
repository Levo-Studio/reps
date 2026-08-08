//
//  AddExerciseView.swift
//  Reps
//
//  Inline ghost-text autocomplete for adding an exercise. Sits directly in the
//  active-routine list where the "+ New Exercise" row was — no modal, no
//  navigation chrome — so adding an exercise feels like adding a set.
//

import SwiftUI
import SwiftData

struct InlineAddExerciseRow: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var context

    /// Called when the user finishes adding (Cancel, or an empty submit) so the
    /// parent can collapse back to the "+ New Exercise" row.
    let onDone: () -> Void

    @State private var typed = ""
    @FocusState private var focused: Bool

    /// Guards against the return path and the blur path both firing.
    @State private var finished = false

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            Button("Cancel") { onDone() }
                .font(.system(size: 17))
                .foregroundStyle(Theme.secondary)
                .padding(.vertical, 12)
        }
        .onAppear { focused = true }
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
                .onChange(of: focused) { _, isFocused in
                    if !isFocused { finishFromBlur() }
                }
                .fixedSize()
            Text(ghostSuffix)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Theme.secondary)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Actions

    /// First return accepts the ghost suggestion; a second return (nothing left
    /// to accept) creates the exercise. An empty submit collapses the row.
    private func handleReturn() {
        if !ghostSuffix.isEmpty, let suggestion {
            typed = suggestion.name
            focused = true
        } else if typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onDone()
        } else {
            create()
        }
    }

    /// Appends the exercise, then collapses the row back to the "+ New Exercise"
    /// button via `onDone()`.
    private func create() {
        guard !finished else { return }
        finished = true
        let name = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let type = suggestion?.type ?? ExerciseCatalog.type(for: name)
        let exercise = Exercise(name: name, type: type, sortIndex: routine.nextExerciseSortIndex)
        exercise.routine = routine
        routine.exercises.append(exercise)
        try? context.save()
        onDone()
    }

    /// Tapping outside the field commits a non-empty entry (which collapses via
    /// `create()`), or otherwise just collapses back to the "+ New Exercise" row.
    private func finishFromBlur() {
        guard !finished else { return }
        if typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finished = true
            onDone()
        } else {
            create()
        }
    }
}
