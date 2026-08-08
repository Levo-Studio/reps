//
//  RoutineEntity.swift
//  Reps
//

import AppIntents
import SwiftData
import Foundation

/// Exposes a routine to App Intents so it can be picked once and baked into a
/// saved shortcut — no runtime parameter picker when the shortcut runs.
struct RoutineEntity: AppEntity, Identifiable {
    let id: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Routine" }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    static var defaultQuery = RoutineEntityQuery()
}

/// Resolves `RoutineEntity` values from the shared SwiftData store.
struct RoutineEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [RoutineEntity] {
        fetchAll().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [RoutineEntity] {
        fetchAll()
    }

    @MainActor
    private func fetchAll() -> [RoutineEntity] {
        let context = RepsModelContainer.shared.mainContext
        let descriptor = FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.sortIndex)])
        let routines = (try? context.fetch(descriptor)) ?? []
        return routines.map { RoutineEntity(id: $0.id, name: $0.name) }
    }
}
