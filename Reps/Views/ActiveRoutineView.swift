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

    @State private var showAddExercise = false
    @State private var showRestView = false
    @State private var showEndFlow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(routine.orderedExercises) { exercise in
                    ExerciseSectionView(exercise: exercise, routineName: routine.name)
                }

                newExerciseRow
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
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
        .fullScreenCover(isPresented: $showAddExercise) {
            AddExerciseView(routine: routine)
        }
        .fullScreenCover(isPresented: $showRestView) {
            RestTimerView(routine: routine)
        }
        .fullScreenCover(isPresented: $showEndFlow) {
            EndWorkoutFlowView(routine: routine, onFinish: finishWorkout)
        }
        .onChange(of: timer.isRunning) { _, running in
            if running { showRestView = true }
            else { showRestView = false }
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
                .onTapGesture { showAddExercise = true }
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
