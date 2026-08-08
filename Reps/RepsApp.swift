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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(timer)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(RepsModelContainer.shared)
    }
}
