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

    @Query(sort: \Routine.sortIndex) private var routines: [Routine]
    @State private var path: [Routine] = []
    private let router = AppRouter.shared

    var body: some View {
        NavigationStack(path: $path) {
            RoutinesOverviewView()
                .navigationDestination(for: Routine.self) { routine in
                    ActiveRoutineView(routine: routine)
                }
        }
        .task {
            timer.requestAuthorization()
            openPendingRoutine()
        }
        .onChange(of: router.pendingRoutineID) { _, _ in
            openPendingRoutine()
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
