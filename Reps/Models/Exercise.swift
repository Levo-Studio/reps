//
//  Exercise.swift
//  Reps
//

import Foundation
import SwiftData

/// Whether an exercise is logged with weight or reps only.
enum ExerciseType: String, Codable, CaseIterable {
    case repsOnly
    case weightAndReps

    /// The badge label shown on the Add Exercise screen.
    var badge: String {
        switch self {
        case .repsOnly: return "REPS"
        case .weightAndReps: return "WEIGHT + REPS"
        }
    }
}

/// A single exercise inside a routine.
///
/// `bestWeight`/`bestReps` are the only workout numbers that survive beyond a
/// session — they act as the baseline pre-filled when logging the next set.
@Model
final class Exercise {
    var id: UUID
    var name: String
    var typeRaw: String
    var sortIndex: Int
    var bestWeight: Double?
    var bestReps: Int

    var routine: Routine?

    var type: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .weightAndReps }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: ExerciseType,
        sortIndex: Int,
        bestWeight: Double? = nil,
        bestReps: Int = 0
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.sortIndex = sortIndex
        self.bestWeight = bestWeight
        self.bestReps = bestReps
    }

    /// Updates the persisted baseline if the given set beats the current best.
    ///
    /// A set beats the best when its weight is heavier, or — at equal weight —
    /// when it has more reps. Reps-only exercises compare on reps alone.
    func recordIfBest(weight: Double?, reps: Int) {
        switch type {
        case .repsOnly:
            if reps > bestReps { bestReps = reps }
        case .weightAndReps:
            let newWeight = weight ?? 0
            let currentBest = bestWeight ?? 0
            if newWeight > currentBest || (newWeight == currentBest && reps > bestReps) {
                bestWeight = newWeight
                bestReps = reps
            }
        }
    }
}
