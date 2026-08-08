//
//  SetInputRow.swift
//  Reps
//
//  Inline numeric entry used both to add a new set and to edit an existing
//  one. No slider — a decimal pad for weight, a number pad for reps, matching
//  the minimal, Notes-like language of the design.
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
                    numberField("0", text: $weightText, field: .weight, keyboard: .decimalPad, width: 64)
                    unit("kg")
                    unit("×")
                }
                numberField("0", text: $repsText, field: .reps, keyboard: .numberPad, width: 48)

                Button(action: commit) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(canCommit ? Theme.accent : Theme.secondary)
                        .frame(width: 32, height: 32)
                }
                .disabled(!canCommit)
                .padding(.leading, 6)
            }
        }
        .padding(.vertical, 12)
        .onAppear { focus = type == .weightAndReps ? .weight : .reps }
    }

    private func numberField(_ placeholder: String, text: Binding<String>, field: Field, keyboard: UIKeyboardType, width: CGFloat) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 17, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.primary)
            .tint(Theme.accent)
            .frame(width: width)
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

    private func commit() {
        guard let reps = parsedReps, reps > 0 else { return }
        let weight = type == .weightAndReps ? parsedWeight : nil
        onCommit(weight, reps)
    }
}
