//
//  CompletionStore.swift
//  Reps
//

import Foundation
import Observation

/// Tracks which sets are marked done during the current run. In-memory and
/// observable — completion is never persisted, so every routine is entered with
/// zero completion, and toggling updates the UI live.
@MainActor
@Observable
final class CompletionStore {
    private var doneIDs: Set<UUID> = []

    func isDone(_ id: UUID) -> Bool {
        doneIDs.contains(id)
    }

    /// Flips the done state for a set and returns the new value.
    @discardableResult
    func toggle(_ id: UUID) -> Bool {
        if doneIDs.contains(id) {
            doneIDs.remove(id)
            return false
        } else {
            doneIDs.insert(id)
            return true
        }
    }

    /// Clears all completion — used when a workout ends.
    func reset() {
        doneIDs.removeAll()
    }
}
