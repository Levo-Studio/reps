//
//  Routine.swift
//  Reps
//

import Foundation
import SwiftData

/// A named workout routine (e.g. "Monday — Push") holding an ordered list of
/// exercises. Persisted locally via SwiftData — no history, only the routine
/// definition and each exercise's best baseline are stored.
@Model
final class Routine {
    var id: UUID
    var name: String
    var sortIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \Exercise.routine)
    var exercises: [Exercise]

    init(id: UUID = UUID(), name: String, sortIndex: Int, exercises: [Exercise] = []) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.exercises = exercises
    }

    /// Exercises in their stored display order.
    var orderedExercises: [Exercise] {
        exercises.sorted { $0.sortIndex < $1.sortIndex }
    }

    /// The next sort index to assign when appending an exercise.
    var nextExerciseSortIndex: Int {
        (exercises.map(\.sortIndex).max() ?? -1) + 1
    }
}
