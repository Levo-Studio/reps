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
    /// The shared rest-timer controller.
    @State private var timer = RestTimerController()
    /// In-memory set completion for the current run.
    @State private var completion = CompletionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(timer)
                .environment(completion)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(RepsModelContainer.shared)
    }
}
