//
//  SetEntry.swift
//  Reps
//

import Foundation
import SwiftData

/// A logged set, persisted locally as part of its exercise. Sets and their
/// weight/reps are saved permanently and carry over between sessions.
@Model
final class SetEntry {
    var id: UUID
    var weight: Double?
    var reps: Int
    var order: Int
    /// Whether the user has marked this set complete — drives the row highlight
    /// and the rest timer.
    var isDone: Bool

    var exercise: Exercise?

    init(id: UUID = UUID(), weight: Double?, reps: Int, order: Int, isDone: Bool = false) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.order = order
        self.isDone = isDone
    }
}
