//
//  RepsWidgetBundle.swift
//  RepsWidget
//
//  Entry point for the Reps Widget Extension. Register additional widgets
//  and Live Activities here as they are added.
//

import WidgetKit
import SwiftUI

/// The widget bundle exposed by the Reps Widget Extension.
@main
struct RepsWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestLiveActivity()
        RepsQuickWidget()
    }
}
