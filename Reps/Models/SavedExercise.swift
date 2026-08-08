//
//  SavedExercise.swift
//  Reps
//

import Foundation
import SwiftData

/// A user-defined exercise learned on device. Custom names the user creates or
/// renames to (with their chosen type) are saved here so they show up in
/// autocomplete suggestions and their type is auto-detected next time.
@Model
final class SavedExercise {
    @Attribute(.unique) var name: String
    var typeRaw: String

    var type: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .weightAndReps }
        set { typeRaw = newValue.rawValue }
    }

    init(name: String, type: ExerciseType) {
        self.name = name
        self.typeRaw = type.rawValue
    }
}
