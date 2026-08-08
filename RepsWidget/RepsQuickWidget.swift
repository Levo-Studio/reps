//
//  RepsQuickWidget.swift
//  RepsWidget
//
//  A minimal Home Screen widget — just the Reps mark and name, tapping it opens
//  the app. Its main job is to give the extension a regular widget so the widget
//  host has something to render (a Live-Activity-only bundle otherwise makes
//  Xcode log a "Failed to show Widget" error on run).
//

import WidgetKit
import SwiftUI

// MARK: - Timeline

private struct RepsEntry: TimelineEntry {
    let date: Date
}

private struct RepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RepsEntry { RepsEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (RepsEntry) -> Void) {
        completion(RepsEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RepsEntry>) -> Void) {
        completion(Timeline(entries: [RepsEntry(date: .now)], policy: .never))
    }
}

// MARK: - Color helper

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

// MARK: - View

private struct RepsQuickWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // The app icon mark: accent diagonal bar.
            Capsule()
                .fill(Color(hex: 0x2EE59D))
                .frame(width: 12, height: 30)
                .rotationEffect(.degrees(20))
            Spacer()
            Text("Reps")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color(hex: 0x141416) }
    }
}

// MARK: - Widget

/// A small Home Screen widget that simply opens Reps when tapped.
struct RepsQuickWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RepsQuickWidget", provider: RepsProvider()) { _ in
            RepsQuickWidgetView()
        }
        .configurationDisplayName("Reps")
        .description("Open Reps.")
        .supportedFamilies([.systemSmall])
    }
}
