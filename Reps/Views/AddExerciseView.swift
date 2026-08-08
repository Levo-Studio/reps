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
    @Query private var savedExercises: [SavedExercise]

    /// Called when the user finishes adding (Cancel, or an empty submit) so the
    /// parent can collapse back to the "+ New Exercise" row.
    let onDone: () -> Void

    @State private var typed = ""
    @FocusState private var focused: Bool

    /// Guards against the return path and the blur path both firing.
    @State private var finished = false

    /// A manual type override chosen by tapping the badge. `nil` means the type
    /// is auto-resolved from the suggestion/catalog.
    @State private var manualType: ExerciseType?

    /// User-learned exercises, mapped into catalog entries so they feed both the
    /// ghost-text suggestions and type auto-detection.
    private var learnedEntries: [CatalogEntry] {
        savedExercises.map { CatalogEntry(name: $0.name, type: $0.type) }
    }

    /// The catalog entry whose name begins with what's typed, if any.
    private var suggestion: CatalogEntry? {
        ExerciseCatalog.firstMatch(for: typed, extra: learnedEntries)
    }

    /// The un-typed remainder of the suggestion, shown as dimmed ghost text.
    private var ghostSuffix: String {
        guard let suggestion, !typed.isEmpty,
              suggestion.name.count > typed.count else { return "" }
        return String(suggestion.name.dropFirst(typed.count))
    }

    /// The type that would be created right now: a manual badge override wins,
    /// otherwise the suggestion's type, otherwise the catalog resolution.
    private var effectiveType: ExerciseType {
        let trimmed = typed.trimmingCharacters(in: .whitespaces)
        // The suggestion's type is deliberately NOT peeked here: while typing a
        // prefix the badge stays on the exact-match type (custom → weight+reps),
        // and the suggestion's type only takes effect once it's accepted (the
        // text becomes the full name). A manual tap overrides live.
        return manualType ?? ExerciseCatalog.type(for: trimmed, extra: learnedEntries)
    }

    /// Whether there is a name to show a badge for.
    private var hasName: Bool {
        !typed.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputField
                .padding(.top, 20)

            HStack {
                Text("Double-tap return to accept")
                    .foregroundStyle(Theme.secondary)
                Spacer()
                if hasName {
                    Button {
                        manualType = (effectiveType == .weightAndReps) ? .repsOnly : .weightAndReps
                    } label: {
                        Text(effectiveType.badge)
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
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
            // Accepting a suggestion hands type authority back to that
            // suggestion, discarding any manual badge override.
            manualType = nil
            focused = true
        } else if typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            manualType = nil
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
        let type = effectiveType
        let exercise = Exercise(name: name, type: type, sortIndex: routine.nextExerciseSortIndex)
        exercise.routine = routine
        routine.exercises.append(exercise)
        learn(name: name, type: type)
        try? context.save()
        manualType = nil
        onDone()
    }

    /// Persists a custom (non-built-in) exercise name and its chosen type so it
    /// feeds suggestions next time. Upserts by case-insensitive name to respect
    /// the `@Attribute(.unique)` constraint on `SavedExercise.name`.
    private func learn(name: String, type: ExerciseType) {
        guard !ExerciseCatalog.isBuiltIn(name) else { return }
        if let existing = savedExercises.first(where: { $0.name.lowercased() == name.lowercased() }) {
            existing.type = type
        } else {
            context.insert(SavedExercise(name: name, type: type))
        }
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
