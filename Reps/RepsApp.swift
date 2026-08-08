//
//  RepsApp.swift
//  Reps
//
//  A product by Levo Studio.
//

import SwiftUI
import SwiftData

@main
struct RepsApp: App {
    /// The current open workout session (in-memory logged sets).
    @State private var session = WorkoutSession()
    /// The shared rest-timer controller.
    @State private var timer = RestTimerController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(timer)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(RepsModelContainer.shared)
    }
}
