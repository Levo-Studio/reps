//
//  SetEntry.swift
//  Reps
//

import Foundation
import SwiftData

/// A logged set, persisted locally as part of its exercise. Weight and reps are
/// saved permanently and carry over between sessions; the done state does not.
@Model
final class SetEntry {
    var id: UUID
    var weight: Double?
    var reps: Int
    var order: Int

    var exercise: Exercise?

    /// Whether the user has marked this set complete. In-memory only — never
    /// persisted — so every routine is entered with zero completion. Drives the
    /// row highlight and the rest timer.
    @Transient var isDone: Bool = false

    init(id: UUID = UUID(), weight: Double?, reps: Int, order: Int) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.order = order
    }
}
