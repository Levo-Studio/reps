//
//  WorkoutSession.swift
//  Reps
//

import Foundation
import Observation

/// A set logged during the current open session. Never persisted — it only
/// feeds the live view and the end-of-workout summary.
struct LoggedSet: Identifiable, Equatable {
    let id = UUID()
    var exerciseId: UUID
    var weight: Double?
    var reps: Int
    var order: Int
    /// Whether the user has marked this set complete. In-memory only, never
    /// persisted — it drives the row highlight and the rest timer.
    var isDone: Bool = false
}

/// Holds all sets logged since the routine was opened. Lives for exactly one
/// open session and is cleared when the workout ends. Weight/reps of any set
/// stay editable; edits re-evaluate each exercise's best baseline.
@Observable
final class WorkoutSession {
    /// Logged sets keyed by exercise id, each ordered by `order`.
    private(set) var setsByExercise: [UUID: [LoggedSet]] = [:]

    /// Sets logged for the given exercise, in log order.
    func sets(for exerciseId: UUID) -> [LoggedSet] {
        setsByExercise[exerciseId] ?? []
    }

    /// Appends a new set and returns it.
    @discardableResult
    func addSet(exerciseId: UUID, weight: Double?, reps: Int) -> LoggedSet {
        var sets = setsByExercise[exerciseId] ?? []
        let set = LoggedSet(exerciseId: exerciseId, weight: weight, reps: reps, order: sets.count)
        sets.append(set)
        setsByExercise[exerciseId] = sets
        return set
    }

    /// Updates an existing logged set's weight/reps in place.
    func update(_ set: LoggedSet, weight: Double?, reps: Int) {
        guard var sets = setsByExercise[set.exerciseId],
              let index = sets.firstIndex(where: { $0.id == set.id }) else { return }
        sets[index].weight = weight
        sets[index].reps = reps
        setsByExercise[set.exerciseId] = sets
    }

    /// Marks an existing logged set done/undone in place.
    func setDone(_ set: LoggedSet, _ done: Bool) {
        guard var sets = setsByExercise[set.exerciseId],
              let index = sets.firstIndex(where: { $0.id == set.id }) else { return }
        sets[index].isDone = done
        setsByExercise[set.exerciseId] = sets
    }

    /// Removes all logged sets, ending the session.
    func reset() {
        setsByExercise.removeAll()
    }

    var allSets: [LoggedSet] {
        setsByExercise.values.flatMap { $0 }
    }

    /// Sum of weight × reps across every logged set this session.
    var totalVolume: Double {
        allSets.reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps) }
    }

    var totalSets: Int { allSets.count }

    var totalReps: Int { allSets.reduce(0) { $0 + $1.reps } }

    /// Whether any set has been logged this session.
    var isEmpty: Bool { allSets.isEmpty }
}
