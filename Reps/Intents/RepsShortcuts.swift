//
//  RepsShortcuts.swift
//  Reps
//

import AppIntents

/// Exposes Reps intents to the Shortcuts app and Spotlight. Each saved
/// shortcut carries its own routine name, so users can pin one per routine to
/// the Action Button.
struct RepsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenRoutineIntent(),
            phrases: [
                "Open \(\.$routine) in \(.applicationName)",
                "Start \(\.$routine) in \(.applicationName)",
                "\(.applicationName) \(\.$routine)"
            ],
            shortTitle: "Open Routine",
            systemImageName: "figure.strengthtraining.traditional"
        )
    }
}
