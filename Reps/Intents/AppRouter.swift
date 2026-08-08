//
//  AppRouter.swift
//  Reps
//

import Foundation
import Observation

/// Bridges deep-link intents into SwiftUI navigation. An intent sets
/// `pendingRoutineID`; the root view observes it, resolves the routine and
/// pushes its logging screen.
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    /// The routine an intent asked to open, consumed by the root view.
    var pendingRoutineID: UUID?

    private init() {}

    func requestOpen(routineID: UUID) {
        pendingRoutineID = routineID
    }
}
