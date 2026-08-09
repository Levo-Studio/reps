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
    @Query private var savedExercises: [SavedExercise]
    let routineName: String

    @FocusState private var nameFocused: Bool
    /// Whether the name header is in its double-tap edit state.
    @State private var isEditingName = false
    /// Working copy of the name while editing, so an empty submit can be
    /// discarded without ever writing a blank name onto the model.
    @State private var draftName = ""
    /// A manual type override chosen by tapping the badge. `nil` means the type
    /// is auto-resolved from the suggestion/catalog.
    @State private var manualType: ExerciseType?

    // Swipe-to-delete state for the exercise name header.
    @State private var offset: CGFloat = 0
    @State private var openOffset: CGFloat = 0
    @State private var isSwiping = false
    @State private var showDeleteConfirm = false

    private let revealWidth: CGFloat = 88
    private let fullSwipeThreshold: CGFloat = 200

    private var sets: [SetEntry] { exercise.orderedSets }

    /// User-learned exercises, mapped into catalog entries so they feed both the
    /// ghost-text suggestions and type auto-detection.
    private var learnedEntries: [CatalogEntry] {
        savedExercises.map { CatalogEntry(name: $0.name, type: $0.type) }
    }

    /// The catalog entry whose name begins with the drafted name, if any —
    /// powers the inline ghost-text completion while renaming.
    private var suggestion: CatalogEntry? {
        ExerciseCatalog.firstMatch(for: draftName, extra: learnedEntries)
    }

    /// The un-typed remainder of the suggestion, shown as dimmed ghost text.
    private var ghostSuffix: String {
        guard let suggestion, !draftName.isEmpty,
              suggestion.name.count > draftName.count else { return "" }
        return String(suggestion.name.dropFirst(draftName.count))
    }

    /// The type the rename would resolve to right now: a manual badge override
    /// wins, otherwise the suggestion's type, otherwise the catalog resolution.
    private var effectiveType: ExerciseType {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        // The suggestion's type is deliberately NOT peeked here: while typing a
        // prefix the badge stays on the exact-match type (custom → weight+reps),
        // and the suggestion's type only takes effect once it's accepted. A
        // manual tap on the badge overrides live.
        return manualType ?? ExerciseCatalog.type(for: trimmed, extra: learnedEntries)
    }

    /// Whether there is a drafted name to show a badge for.
    private var hasName: Bool {
        !draftName.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
        // The whole exercise block slides on a title swipe, revealing a single
        // delete affordance; the per-set swipe-to-delete stays independent.
        .background(Theme.background)
        .offset(x: offset)
        .background(alignment: .trailing) {
            if offset < 0 { deletePanel }
        }
        .confirmationDialog(
            "Delete “\(exercise.name)”?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteExercise() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header

    /// The exercise name shows as plain text and only becomes editable on a
    /// double tap — a single tap does nothing, so the field can't be focused by
    /// accident. In edit mode it becomes a ghost-text autocomplete (mirroring the
    /// Add Exercise row): the first return accepts the suggestion, the second
    /// commits, and committing auto-switches the exercise type to match. Editing
    /// commits on submit and on blur.
    private var header: some View {
        Group {
            if isEditingName {
                VStack(alignment: .leading, spacing: 0) {
                    nameInputField

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
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    Divider().overlay(Theme.divider)
                }
                // Focus after the field is mounted to dodge the SwiftUI race
                // where focusing during the Text→TextField swap is dropped.
                .onAppear {
                    DispatchQueue.main.async { nameFocused = true }
                }
            } else {
                // Swiping the title drives the whole-block swipe (offset lives on
                // the section's VStack), so the entire exercise slides together.
                Text(exercise.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { beginNameEdit() }
                    .gesture(swipe)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
        .contextMenu {
            Button(role: .destructive) { requestDeleteExercise() } label: { Text("Delete") }
        }
    }

    /// The red affordance revealed behind the name on a left swipe. Tapping it
    /// asks to delete the exercise (via the confirmation dialog).
    private var deletePanel: some View {
        Button(action: requestDeleteExercise) {
            ZStack(alignment: .trailing) {
                Color.red
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.trailing, 26)
            }
        }
        .buttonStyle(.plain)
    }

    private var swipe: some Gesture {
        // Measure in the global space: the offset moves the whole block (which
        // contains the gesture's view), and a local translation would feed back
        // into itself and jitter.
        DragGesture(minimumDistance: 18, coordinateSpace: .global)
            .onChanged { value in
                if !isSwiping {
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    isSwiping = true
                }
                let proposed = openOffset + value.translation.width
                offset = min(0, max(proposed, -(fullSwipeThreshold + 80)))
            }
            .onEnded { _ in
                isSwiping = false
                let distance = -offset
                if distance > fullSwipeThreshold {
                    requestDeleteExercise()
                } else if distance > revealWidth / 2 {
                    withAnimation(.snappy) { offset = -revealWidth; openOffset = -revealWidth }
                } else {
                    withAnimation(.snappy) { offset = 0; openOffset = 0 }
                }
            }
    }

    /// Snaps the row closed and presents the confirmation dialog — the exercise
    /// is only removed once the user confirms.
    private func requestDeleteExercise() {
        withAnimation(.snappy) { offset = 0; openOffset = 0 }
        showDeleteConfirm = true
    }

    /// The ghost-text rename input: the typed text sits in the `TextField` (white)
    /// and the un-typed remainder of the suggestion trails after it in
    /// `Theme.secondary`. Sized to match the plain name header, not the big Add row.
    private var nameInputField: some View {
        HStack(spacing: 0) {
            TextField("", text: $draftName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.primary)
                .tint(Theme.accent)
                .focused($nameFocused)
                .submitLabel(.next)
                .onSubmit(handleReturn)
                .onChange(of: nameFocused) { _, focused in
                    if !focused { commitNameEdit() }
                }
                .fixedSize()
            Text(ghostSuffix)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.secondary)
            Spacer(minLength: 0)
        }
    }

    private var addSetRow: some View {
        HStack {
            Text("+")
            Spacer()
            Text("Add Set")
                // Match the numbers' right margin (their fields inset 4pt).
                .padding(.trailing, 4)
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
        manualType = nil
        isEditingName = true
    }

    /// First return accepts the ghost suggestion (keeping focus); a second return
    /// — with nothing left to accept — commits the rename.
    private func handleReturn() {
        if !ghostSuffix.isEmpty, let suggestion {
            draftName = suggestion.name
            // Accepting a suggestion hands type authority back to that
            // suggestion, discarding any manual badge override.
            manualType = nil
            nameFocused = true
        } else {
            commitNameEdit()
        }
    }

    /// Commits (or discards) the drafted name and leaves edit mode. A blank name
    /// is discarded so the previous name and type are kept. Otherwise the name is
    /// updated and the type is auto-switched to the resolved catalog type — this
    /// only rewrites `name`/`type`, never the logged sets, so their weight/reps
    /// survive the rename (reps-only just hides the weight). The `isEditingName`
    /// guard makes the double fire from submit-then-blur idempotent.
    private func commitNameEdit() {
        guard isEditingName else { return }
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let type = effectiveType
            exercise.name = trimmed
            exercise.type = type
            learn(name: trimmed, type: type)
            try? context.save()
        }
        manualType = nil
        isEditingName = false
        nameFocused = false
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
        // Start empty: weight nil and reps 0 so both fields show the "0"
        // placeholder and you can type straight away without deleting anything.
        let entry = SetEntry(weight: nil, reps: 0, order: exercise.nextSetOrder)
        entry.exercise = exercise
        exercise.sets.append(entry)
        try? context.save()
    }
}
