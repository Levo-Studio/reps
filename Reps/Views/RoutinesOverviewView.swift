//
//  RoutinesOverviewView.swift
//  Reps
//
//  Screen 1 — app root. Flat list of routines with an inline add row.
//

import SwiftUI
import SwiftData

struct RoutinesOverviewView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.sortIndex) private var routines: [Routine]

    @State private var isAddingRoutine = false
    @State private var newRoutineName = ""
    @FocusState private var addFieldFocused: Bool

    // The routine the user has asked to delete, awaiting confirmation. Deleting
    // is never immediate: a swipe or context-menu action stores the routine here
    // and the confirmation dialog performs the actual removal on confirm.
    @State private var routinePendingDelete: Routine?

    var body: some View {
        ScrollView {
            GeometryReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    Text("Reps")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .padding(.top, 12)
                        .padding(.bottom, 28)

                    ForEach(routines) { routine in
                        RoutineRow(routine: routine) {
                            requestDelete(routine)
                        }
                    }

                    if isAddingRoutine {
                        addRoutineField
                    } else {
                        Button {
                            beginAddingRoutine()
                        } label: {
                            routineRow("+ New Routine", color: Theme.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .background(
                    // Behind the rows so NavigationLinks stay tappable; only
                    // taps on empty space fall through and dismiss the keyboard.
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { dismissKeyboard() }
                )
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            routinePendingDelete.map { "Delete “\($0.name)”?" } ?? "",
            isPresented: Binding(
                get: { routinePendingDelete != nil },
                set: { presented in if !presented { routinePendingDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: routinePendingDelete
        ) { routine in
            Button("Delete", role: .destructive) {
                delete(routine)
                routinePendingDelete = nil
            }
            Button("Cancel", role: .cancel) { routinePendingDelete = nil }
        }
    }

    private func routineRow(_ title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
            Divider().overlay(Theme.divider)
        }
        .contentShape(Rectangle())
    }

    private var addRoutineField: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("", text: $newRoutineName)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Theme.primary)
                .tint(Theme.accent)
                .focused($addFieldFocused)
                .submitLabel(.done)
                .onSubmit { commitNewRoutine() }
                .onChange(of: addFieldFocused) { _, focused in
                    if !focused { commitNewRoutine() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
            Divider().overlay(Theme.divider)
        }
    }

    private func beginAddingRoutine() {
        newRoutineName = ""
        isAddingRoutine = true
        addFieldFocused = true
    }

    private func commitNewRoutine() {
        guard isAddingRoutine else { return }
        let name = newRoutineName.trimmingCharacters(in: .whitespacesAndNewlines)
        isAddingRoutine = false
        newRoutineName = ""
        guard !name.isEmpty else { return }
        let routine = Routine(name: name, sortIndex: (routines.map(\.sortIndex).max() ?? -1) + 1)
        context.insert(routine)
        try? context.save()
    }

    /// Records the routine the user wants to remove so the confirmation dialog
    /// can present. The actual delete only happens once they confirm.
    private func requestDelete(_ routine: Routine) {
        routinePendingDelete = routine
    }

    private func delete(_ routine: Routine) {
        context.delete(routine)
        try? context.save()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// A single routine row that navigates on tap and reveals a red "Delete" panel
/// on a left swipe. It owns only its swipe state; the actual deletion is
/// deferred to the parent via `onRequestDelete`, which surfaces a confirmation
/// dialog. Mirrors the hand-rolled swipe in `LoggedSetRow` since these rows live
/// in a `ScrollView`/`VStack` where `.swipeActions` isn't available.
private struct RoutineRow: View {
    let routine: Routine
    /// Called when the user swipes far enough to delete, or taps the revealed
    /// red panel, or picks Delete from the context menu.
    let onRequestDelete: () -> Void

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

    var body: some View {
        NavigationLink(value: routine) {
            rowLabel
        }
        .buttonStyle(.plain)
        // Opaque base so the red panel behind only shows once the row has
        // actually slid out of the way.
        .background(Theme.background)
        .offset(x: offset)
        // The delete panel is a BACKGROUND (not a ZStack sibling) so it is sized
        // to the row and — applied after `.offset`, which is render-only — stays
        // put while the row content slides over it.
        .background(alignment: .trailing) { deletePanel }
        .gesture(swipe)
        .contextMenu {
            Button(role: .destructive) { onRequestDelete() } label: { Text("Delete") }
        }
    }

    private var rowLabel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(routine.name)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Theme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
            Divider().overlay(Theme.divider)
        }
        .contentShape(Rectangle())
    }

    /// The red affordance behind the row. As a `.background` it fills the row's
    /// bounds; the row's own opaque background covers it until the row slides
    /// left, revealing the trailing trash icon. Tapping the revealed area asks
    /// the parent to delete.
    private var deletePanel: some View {
        Button(action: requestDelete) {
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
                // vertical scrolls and taps to navigate aren't hijacked.
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
                    requestDelete()
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

    /// Snaps the row closed and hands off to the parent, which presents the
    /// confirmation dialog before anything is actually removed.
    private func requestDelete() {
        withAnimation(.snappy) {
            offset = 0
            openOffset = 0
        }
        onRequestDelete()
    }
}
