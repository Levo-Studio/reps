//
//  SharedRoutines.swift
//  Reps
//

import Foundation
import WidgetKit

/// Bridges routine names into the shared App Group so the Home Screen widget can
/// display them. The widget can't read the app's SwiftData store directly, so
/// the app publishes a lightweight list here and reloads the widget timelines.
enum SharedRoutines {
    static let appGroup = "group.levo-studio.reps"
    static let key = "routineNames"

    /// Writes the current routine names to shared storage and refreshes widgets.
    static func publish(_ names: [String]) {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return }
        defaults.set(names, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
