//
//  Seeder.swift
//  Reps
//

import Foundation
import SwiftData

/// Seeds a set of starter routines the first time the app runs so the empty
/// store isn't blank (there is no onboarding or empty-state screen). Runs only
/// when no routines exist yet; everything here is freely editable afterwards.
enum Seeder {
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0
        guard existing == 0 else { return }

        let routines: [(String, [(String, ExerciseType, Double?, Int)])] = [
            ("Monday — Push", [
                ("Bench Press", .weightAndReps, 80, 8),
                ("Incline DB Press", .weightAndReps, 30, 12),
                ("Cable Flyes", .weightAndReps, 15, 15),
                ("Tricep Pushdown", .weightAndReps, 30, 12),
            ]),
            ("Wednesday — Pull", [
                ("Lat Pulldown", .weightAndReps, 55, 10),
                ("Barbell Row", .weightAndReps, 60, 10),
                ("Pull Ups", .repsOnly, nil, 8),
                ("Bicep Curl", .weightAndReps, 15, 12),
            ]),
            ("Friday — Legs", [
                ("Squat", .weightAndReps, 100, 6),
                ("Romanian Deadlift", .weightAndReps, 80, 8),
                ("Leg Press", .weightAndReps, 160, 10),
                ("Calf Raise", .weightAndReps, 40, 15),
            ]),
        ]

        for (routineIndex, entry) in routines.enumerated() {
            let routine = Routine(name: entry.0, sortIndex: routineIndex)
            context.insert(routine)
            for (exerciseIndex, ex) in entry.1.enumerated() {
                let exercise = Exercise(
                    name: ex.0,
                    type: ex.1,
                    sortIndex: exerciseIndex,
                    bestWeight: ex.2,
                    bestReps: ex.3
                )
                exercise.routine = routine
                routine.exercises.append(exercise)
            }
        }
        try? context.save()
    }
}
