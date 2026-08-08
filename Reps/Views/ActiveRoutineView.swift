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
    @Environment(WorkoutSession.self) private var session
    @Environment(RestTimerController.self) private var timer
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var isAddingExercise = false
    @State private var showEndFlow = false

    var body: some View {
        VStack(spacing: 0) {
            // Rest timer lives as a pinned bar above the list — the exercise
            // list stays stationary while the bar animates in and out.
            if timer.isRunning {
                RestingHeaderView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
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
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(.easeInOut, value: timer.isRunning)
        .background(Theme.background)
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.large)
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

    /// Ends the workout: clears the session and returns to Screen 1.
    private func finishWorkout() {
        timer.stop()
        session.reset()
        showEndFlow = false
        dismiss()
    }
}
