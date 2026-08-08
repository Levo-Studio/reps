//
//  LoggedSetRow.swift
//  Reps
//
//  A logged set, always editable inline. Weight and reps are `TextField`s that
//  look identical to plain display text — there is no edit "mode", no row-level
//  tap, no background change. Tapping directly on a number focuses just that
//  field, and edits save live via `onEdit` as the user types.
//

import SwiftUI

struct LoggedSetRow: View {
    let number: Int
    let type: ExerciseType
    let weight: Double?
    let reps: Int
    /// Called live on every valid keystroke so the parent persists the edit.
    let onEdit: (_ weight: Double?, _ reps: Int) -> Void

    @State private var weightText: String
    @State private var repsText: String
    @FocusState private var focus: Field?

    private enum Field { case weight, reps }

    init(
        number: Int,
        type: ExerciseType,
        weight: Double?,
        reps: Int,
        onEdit: @escaping (_ weight: Double?, _ reps: Int) -> Void
    ) {
        self.number = number
        self.type = type
        self.weight = weight
        self.reps = reps
        self.onEdit = onEdit
        _weightText = State(initialValue: weight.map(Format.weight) ?? "")
        _repsText = State(initialValue: reps > 0 ? String(reps) : "")
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(number)")
                .foregroundStyle(Theme.secondary)
                .font(.system(size: 17, design: .monospaced))
            Spacer(minLength: 12)
            value
        }
        .padding(.vertical, 12)
        .onChange(of: weightText) { _, _ in commit() }
        .onChange(of: repsText) { _, _ in commit() }
    }

    @ViewBuilder
    private var value: some View {
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

    /// Persists the current values whenever they parse. Unparseable or empty
    /// reps are a no-op; for weight-and-reps an empty weight passes `nil`.
    private func commit() {
        guard let reps = Int(repsText), reps > 0 else { return }
        let weight = type == .weightAndReps ? parsedWeight : nil
        onEdit(weight, reps)
    }
}
