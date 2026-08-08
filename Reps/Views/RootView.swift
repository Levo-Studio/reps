//
//  RootView.swift
//  Reps
//

import SwiftUI
import SwiftData

/// Hosts the navigation stack: routines overview → active routine. Also seeds
/// starter data and handles deep-link intents that open a specific routine.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(RestTimerController.self) private var timer
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \Routine.sortIndex) private var routines: [Routine]
    @State private var path: [Routine] = []
    private let router = AppRouter.shared

    var body: some View {
        NavigationStack(path: $path) {
            RoutinesOverviewView(path: $path)
                .navigationDestination(for: Routine.self) { routine in
                    ActiveRoutineView(routine: routine)
                }
        }
        .task {
            timer.requestAuthorization()
            openPendingRoutine()
            SharedRoutines.publish(routines.map(\.name))
        }
        .onChange(of: router.pendingRoutineID) { _, _ in
            openPendingRoutine()
        }
        .onChange(of: routines.map(\.name)) { _, names in
            SharedRoutines.publish(names)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { SharedRoutines.publish(routines.map(\.name)) }
        }
    }

    /// Resolves a deep-link request into a navigation push.
    private func openPendingRoutine() {
        guard let id = router.pendingRoutineID,
              let routine = routines.first(where: { $0.id == id }) else { return }
        path = [routine]
        router.pendingRoutineID = nil
    }
}
