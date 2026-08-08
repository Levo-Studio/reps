//
//  SetInputRow.swift
//  Reps
//
//  Inline numeric entry used both to add a new set and to edit an existing
//  one. Visually identical to `LoggedSetRow` — editing looks like nothing
//  changed, you just edit the numbers. There is no confirm button: the entry
//  commits on focus loss (tap outside / keyboard dismissed).
//

import SwiftUI

struct SetInputRow: View {
    let type: ExerciseType
    /// Leading label — the set number, or "+" when adding.
    let leading: String
    var onCommit: (_ weight: Double?, _ reps: Int) -> Void
    var onCancel: () -> Void

    @State private var weightText: String
    @State private var repsText: String
    /// Guards `onCommit`/`onCancel` against firing more than once — focus
    /// changes and disappearance can both resolve the row.
    @State private var finished = false
    @FocusState private var focus: Field?

    private enum Field { case weight, reps }

    init(
        type: ExerciseType,
        leading: String,
        initialWeight: Double?,
        initialReps: Int,
        onCommit: @escaping (_ weight: Double?, _ reps: Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.type = type
        self.leading = leading
        self.onCommit = onCommit
        self.onCancel = onCancel
        _weightText = State(initialValue: initialWeight.map(Format.weight) ?? "")
        _repsText = State(initialValue: initialReps > 0 ? String(initialReps) : "")
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(leading)
                .foregroundStyle(Theme.secondary)
                .font(.system(size: 17, design: .monospaced))

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                if type == .weightAndReps {
                    numberField("0", text: $weightText, field: .weight, keyboard: .decimalPad, weight: .bold, color: Theme.primary)
                    unit("kg")
                    unit("×")
                    numberField("0", text: $repsText, field: .reps, keyboard: .numberPad, weight: .regular, color: Theme.secondary)
                } else {
                    numberField("0", text: $repsText, field: .reps, keyboard: .numberPad, weight: .bold, color: Theme.primary)
                }
            }
        }
        .padding(.vertical, 12)
        .onAppear { focus = type == .weightAndReps ? .weight : .reps }
        // Commit when focus leaves the row (tap outside / keyboard dismissed).
        .onChange(of: focus) { _, newValue in
            if newValue == nil { resolve() }
        }
    }

    private func numberField(_ placeholder: String, text: Binding<String>, field: Field, keyboard: UIKeyboardType, weight: Font.Weight, color: Color) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .fixedSize()
            .font(.system(size: 17, weight: weight, design: .monospaced))
            .foregroundStyle(color)
            .tint(Theme.accent)
            .focused($focus, equals: field)
    }

    private func unit(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, design: .monospaced))
            .foregroundStyle(Theme.secondary)
    }

    private var parsedWeight: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }

    private var parsedReps: Int? {
        Int(repsText)
    }

    private var canCommit: Bool {
        guard let reps = parsedReps, reps > 0 else { return false }
        if type == .weightAndReps { return parsedWeight != nil }
        return true
    }

    /// Commits if the entry is valid, otherwise cancels — fired exactly once.
    private func resolve() {
        guard !finished else { return }
        finished = true
        if canCommit, let reps = parsedReps {
            let weight = type == .weightAndReps ? parsedWeight : nil
            onCommit(weight, reps)
        } else {
            onCancel()
        }
    }
}
