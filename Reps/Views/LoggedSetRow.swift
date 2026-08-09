//
//  LoggedSetRow.swift
//  Reps
//
//  A logged set, always editable inline. Weight and reps are `TextField`s that
//  look identical to plain display text — there is no edit "mode". Tapping
//  directly on a number focuses just that field, and edits save live via
//  `onEdit` as the user types. Tapping the rest of the row toggles the set
//  "done" via `onToggleDone`, which highlights the row and drives the timer.
//
//  The row lives in a `ScrollView`/`VStack` (not a `List`), so `.swipeActions`
//  isn't available — a left-swipe to delete is implemented by hand with a
//  `DragGesture` driving `offset` over a red "Delete" panel revealed at the
//  trailing edge.
//

import SwiftUI

struct LoggedSetRow: View {
    let number: Int
    let type: ExerciseType
    let weight: Double?
    let reps: Int
    /// Whether the set is marked done — drives the row highlight.
    let isDone: Bool
    /// Called live on every valid keystroke so the parent persists the edit.
    let onEdit: (_ weight: Double?, _ reps: Int) -> Void
    /// Called when the user taps the row (outside the number fields) to toggle done.
    let onToggleDone: () -> Void
    /// Called when the set is swiped away or the revealed Delete panel is tapped.
    let onDelete: () -> Void

    @State private var weightText: String
    @State private var repsText: String

    // Swipe-to-delete state. `offset` is the live horizontal displacement of the
    // row (negative = swiped left); `openOffset` is the resting position it
    // settles into so a second drag continues from where it stopped.
    @State private var offset: CGFloat = 0
    @State private var openOffset: CGFloat = 0
    @State private var isSwiping = false

    /// How far the row rests open when the swipe passes the small threshold.
    private let revealWidth: CGFloat = 88
    /// Swiping past this triggers the delete outright, without resting open.
    private let fullSwipeThreshold: CGFloat = 200

    init(
        number: Int,
        type: ExerciseType,
        weight: Double?,
        reps: Int,
        isDone: Bool,
        onEdit: @escaping (_ weight: Double?, _ reps: Int) -> Void,
        onToggleDone: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.number = number
        self.type = type
        self.weight = weight
        self.reps = reps
        self.isDone = isDone
        self.onEdit = onEdit
        self.onToggleDone = onToggleDone
        self.onDelete = onDelete
        // Show a weight only when it's a real positive value; 0/none stays an
        // empty placeholder so you don't have to delete a "0" before typing.
        _weightText = State(initialValue: weight.flatMap { $0 > 0 ? Format.weight($0) : nil } ?? "")
        _repsText = State(initialValue: reps > 0 ? String(reps) : "")
    }

    var body: some View {
        rowContent
            .background(isDone ? Color.white.opacity(0.015) : Color.clear)
            // Opaque base so the red panel behind only shows once the row has
            // actually slid out of the way.
            .background(Theme.background)
            .offset(x: offset)
            // The delete panel is a BACKGROUND (not a ZStack sibling) so it is
            // sized to the row and can never change its height, and — applied
            // after `.offset`, which is render-only — it stays put while the row
            // content slides over it. Only render it while actually swiping,
            // otherwise a sub-pixel red line flickers at the row edge on tap.
            .background(alignment: .trailing) {
                if offset < 0 { deletePanel }
            }
            .gesture(swipe)
            .onChange(of: weightText) { _, _ in commit() }
            .onChange(of: repsText) { _, _ in commit() }
    }

    private var rowContent: some View {
        HStack(spacing: 0) {
            // Left half toggles the set done; only this half reacts to a tap.
            HStack(spacing: 0) {
                Text("\(number)")
                    .foregroundStyle(Theme.secondary)
                    .font(.system(size: 17, design: .monospaced))
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onToggleDone() }

            // Numbers hug their content on the right, with a small buffer (~0.5rem)
            // so tapping a number never lands on the toggle area on the left.
            value
                .padding(.leading, 8)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Swipe to delete

    /// The red affordance behind the row. As a `.background` it fills the row's
    /// bounds; the row's own opaque background covers it until the row slides
    /// left, revealing the trailing trash icon. Tapping the revealed area deletes.
    private var deletePanel: some View {
        Button(action: onDelete) {
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
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                // Only commit to a swipe once the drag is clearly horizontal, so
                // vertical scrolls and taps on the fields aren't hijacked.
                if !isSwiping {
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    isSwiping = true
                }
                let proposed = openOffset + value.translation.width
                // Left-only, with a little travel past the full-swipe threshold
                // for feedback.
                offset = min(0, max(proposed, -(fullSwipeThreshold + 80)))
            }
            .onEnded { _ in
                isSwiping = false
                let distance = -offset
                if distance > fullSwipeThreshold {
                    onDelete()
                } else if distance > revealWidth / 2 {
                    withAnimation(.snappy) {
                        offset = -revealWidth
                        openOffset = -revealWidth
                    }
                } else {
                    withAnimation(.snappy) {
                        offset = 0
                        openOffset = 0
                    }
                }
            }
    }

    // MARK: - Value fields

    @ViewBuilder
    private var value: some View {
        HStack(spacing: 6) {
            if type == .weightAndReps {
                numberField(text: $weightText, keyboard: .decimalPad, bold: true, color: Theme.primary)
                unit("kg")
                unit("×")
                numberField(text: $repsText, keyboard: .numberPad, bold: false, color: Theme.secondary)
            } else {
                numberField(text: $repsText, keyboard: .numberPad, bold: true, color: Theme.primary)
            }
        }
    }

    private func numberField(text: Binding<String>, keyboard: UIKeyboardType, bold: Bool, color: Color) -> some View {
        NumberField(
            text: text,
            placeholder: "0",
            keyboard: keyboard,
            font: .monospacedSystemFont(ofSize: 17, weight: bold ? .bold : .regular),
            textColor: UIColor(color),
            placeholderColor: UIColor(Theme.secondary),
            tint: UIColor(Theme.accent)
        )
        .fixedSize()
        .frame(minWidth: 22)
        .padding(.horizontal, 4)
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
