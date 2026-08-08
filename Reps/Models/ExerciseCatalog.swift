//
//  ExerciseCatalog.swift
//  Reps
//

import Foundation

/// A built-in exercise name with its predefined logging type.
struct CatalogEntry {
    let name: String
    let type: ExerciseType
}

/// The small static list of common exercises that powers autocomplete on the
/// Add Exercise screen. There is no external database — this is the whole set.
enum ExerciseCatalog {
    static let all: [CatalogEntry] = [
        CatalogEntry(name: "Bench Press", type: .weightAndReps),
        CatalogEntry(name: "Incline DB Press", type: .weightAndReps),
        CatalogEntry(name: "Incline Dumbbell Fly", type: .weightAndReps),
        CatalogEntry(name: "Cable Flyes", type: .weightAndReps),
        CatalogEntry(name: "Overhead Press", type: .weightAndReps),
        CatalogEntry(name: "Lateral Raises", type: .weightAndReps),
        CatalogEntry(name: "Tricep Pushdown", type: .weightAndReps),
        CatalogEntry(name: "Squat", type: .weightAndReps),
        CatalogEntry(name: "Front Squat", type: .weightAndReps),
        CatalogEntry(name: "Deadlift", type: .weightAndReps),
        CatalogEntry(name: "Romanian Deadlift", type: .weightAndReps),
        CatalogEntry(name: "Leg Press", type: .weightAndReps),
        CatalogEntry(name: "Leg Curl", type: .weightAndReps),
        CatalogEntry(name: "Leg Extension", type: .weightAndReps),
        CatalogEntry(name: "Calf Raise", type: .weightAndReps),
        CatalogEntry(name: "Lat Pulldown", type: .weightAndReps),
        CatalogEntry(name: "Barbell Row", type: .weightAndReps),
        CatalogEntry(name: "Seated Cable Row", type: .weightAndReps),
        CatalogEntry(name: "Bicep Curl", type: .weightAndReps),
        CatalogEntry(name: "Hammer Curl", type: .weightAndReps),
        CatalogEntry(name: "Face Pull", type: .weightAndReps),
        CatalogEntry(name: "Shrugs", type: .weightAndReps),
        CatalogEntry(name: "Pull Ups", type: .repsOnly),
        CatalogEntry(name: "Chin Ups", type: .repsOnly),
        CatalogEntry(name: "Dips", type: .repsOnly),
        CatalogEntry(name: "Push Ups", type: .repsOnly),
        CatalogEntry(name: "Hanging Leg Raise", type: .repsOnly),
    ]

    /// Returns the first catalog entry whose name begins with `prefix`
    /// (case-insensitive). `extra` holds user-learned exercises, searched after
    /// the built-in list.
    static func firstMatch(for prefix: String, extra: [CatalogEntry] = []) -> CatalogEntry? {
        let trimmed = prefix.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()
        return (all + extra).first { $0.name.lowercased().hasPrefix(lower) }
    }

    /// Resolves the type for a finished name — matched entries (built-in or
    /// learned) keep their type, fully custom names default to `.weightAndReps`.
    static func type(for name: String, extra: [CatalogEntry] = []) -> ExerciseType {
        let trimmed = name.trimmingCharacters(in: .whitespaces).lowercased()
        return (all + extra).first { $0.name.lowercased() == trimmed }?.type ?? .weightAndReps
    }

    /// Whether a name is part of the built-in list (so it need not be learned).
    static func isBuiltIn(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces).lowercased()
        return all.contains { $0.name.lowercased() == trimmed }
    }
}
