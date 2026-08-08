//
//  ActiveRoutineView.swift
//  Reps
//
//  Screen 2 — the logging screen for one routine.
//

import SwiftUI
import SwiftData

struct ActiveRoutineView: View {
    @Bindable var routine: Routine
    @Environment(RestTimerController.self) private var timer
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var isAddingExercise = false
    @State private var showEndFlow = false

    var body: some View {
        // We render the routine name inside the scroll content rather than as the
        // system large title: the `.safeAreaInset` rest bar collapses SwiftUI's
        // large `.navigationTitle`, so the title would vanish while resting. The
        // inline title below is always visible, resting or not.
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(routine.name)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // More breathing room below the pinned rest bar so the
                        // title doesn't crowd it while resting.
                        .padding(.top, timer.isRunning ? 28 : 8)
                        .padding(.bottom, 20)

                    ForEach(routine.orderedExercises) { exercise in
                        ExerciseSectionView(exercise: exercise, routineName: routine.name)
                    }

                    if isAddingExercise {
                        InlineAddExerciseRow(routine: routine, onDone: { isAddingExercise = false })
                    } else {
                        newExerciseRow
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .top)
                // Tapping empty area dismisses the keyboard so blur-commit fires.
                // The gesture lives on a background layer behind the content so
                // interactive rows/fields keep their own taps; only gaps land here.
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { dismissKeyboard() }
                )
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            if timer.isRunning {
                RestingHeaderView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: timer.isRunning)
        .background(Theme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEndFlow = true
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.background)
                        .frame(width: 32, height: 32)
                        .background(Theme.accent, in: Circle())
                }
                .accessibilityLabel("End workout")
            }
        }
        .fullScreenCover(isPresented: $showEndFlow) {
            EndWorkoutFlowView(routine: routine, onFinish: finishWorkout)
        }
    }

    private var newExerciseRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().overlay(Theme.divider)
            Text("+ New Exercise")
                .font(.system(size: 17))
                .foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
                .onTapGesture { isAddingExercise = true }
        }
    }

    /// Resigns first responder so any editing field commits on blur. Scoped to
    /// this struct on purpose — no global/extension helper, to avoid a symbol
    /// clash with helpers other views may define.
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Ends the workout and returns to Screen 1. Logged sets stay saved to the
    /// routine — they are not cleared.
    private func finishWorkout() {
        timer.stop()
        showEndFlow = false
        dismiss()
    }
}
