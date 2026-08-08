//
//  OpenRoutineIntent.swift
//  Reps
//

import AppIntents

/// Deep-links straight into a routine's logging screen (Screen 2).
///
/// The `routine` parameter is baked into each saved shortcut, so a routine
/// pinned to the Action Button opens with no runtime parameter picker.
struct OpenRoutineIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Routine"
    static var description = IntentDescription("Opens a Reps routine and starts logging.")
    static var openAppWhenRun = true

    @Parameter(title: "Routine")
    var routine: RoutineEntity

    init() {}

    init(routine: RoutineEntity) {
        self.routine = routine
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.requestOpen(routineID: routine.id)
        return .result()
    }
}
