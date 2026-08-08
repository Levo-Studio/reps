//
//  SetEntry.swift
//  Reps
//

import Foundation
import SwiftData

/// A logged set, persisted locally as part of its exercise. Weight and reps are
/// saved permanently and carry over between sessions. Completion is tracked
/// separately in `CompletionStore` (in-memory only), not here.
@Model
final class SetEntry {
    var id: UUID
    var weight: Double?
    var reps: Int
    var order: Int

    var exercise: Exercise?

    init(id: UUID = UUID(), weight: Double?, reps: Int, order: Int) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.order = order
    }
}
