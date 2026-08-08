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

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.exercise)
    var sets: [SetEntry]

    var type: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .weightAndReps }
        set { typeRaw = newValue.rawValue }
    }

    /// Logged sets in their display order.
    var orderedSets: [SetEntry] {
        sets.sorted { $0.order < $1.order }
    }

    /// The next order index to assign when appending a set.
    var nextSetOrder: Int {
        (sets.map(\.order).max() ?? -1) + 1
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
        self.sets = []
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
