//
//  LoggedSetRow.swift
//  Reps
//
//  A read-only logged set: set number on the left, weight × reps on the
//  right. Tapping hands editing back to the parent section.
//

import SwiftUI

struct LoggedSetRow: View {
    let number: Int
    let type: ExerciseType
    let weight: Double?
    let reps: Int
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("\(number)")
                .foregroundStyle(Theme.secondary)
                .font(.system(size: 17, design: .monospaced))
            Spacer(minLength: 12)
            value
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var value: some View {
        HStack(spacing: 6) {
            if type == .weightAndReps {
                Text("\(Format.weight(weight ?? 0)) kg")
                    .foregroundStyle(Theme.primary)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                Text("× \(reps)")
                    .foregroundStyle(Theme.secondary)
                    .font(.system(size: 17, design: .monospaced))
            } else {
                Text("\(reps)")
                    .foregroundStyle(Theme.primary)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                Text("reps")
                    .foregroundStyle(Theme.secondary)
                    .font(.system(size: 17, design: .monospaced))
            }
        }
    }
}
