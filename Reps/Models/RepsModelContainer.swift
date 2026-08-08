//
//  RepsModelContainer.swift
//  Reps
//

import SwiftData

/// A single shared SwiftData container used by both the app and the App
/// Intents that deep-link into routines, so they read the same local store.
enum RepsModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: Routine.self, Exercise.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
