//
//  RestActivityAttributes.swift
//  Reps
//
//  Shared between the app and the widget extension. When you create the
//  Widget Extension target, add this file to its target membership so both
//  sides compile against the same ActivityAttributes definition.
//

import ActivityKit
import Foundation

/// Describes the rest-timer Live Activity shown on the Lock Screen.
struct RestActivityAttributes: ActivityAttributes {
    /// Values that change while the timer runs.
    struct ContentState: Codable, Hashable {
        /// The moment the current rest ends — drives the native countdown.
        var endDate: Date
        /// The full rest duration, used to render the progress ring.
        var duration: TimeInterval
    }

    /// The routine being trained, e.g. "Monday — Push".
    var routineName: String
    /// The exercise the next set belongs to.
    var nextExercise: String
    /// The 1-based set number that starts after this rest.
    var nextSetNumber: Int
}
