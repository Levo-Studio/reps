//
//  RepsQuickWidget.swift
//  RepsWidget
//
//  A minimal Home Screen widget. Small/medium show the Reps mark; the large
//  family also lists up to three routines on the right (read from the shared
//  App Group the app publishes to). Tapping the widget opens the app.
//

import WidgetKit
import SwiftUI

// MARK: - Shared storage

private enum Shared {
    static let appGroup = "group.Julius-Grimm.Reps"
    static let key = "routineNames"

    static func routineNames() -> [String] {
        UserDefaults(suiteName: appGroup)?.stringArray(forKey: key) ?? []
    }
}

// MARK: - Timeline

private struct RepsEntry: TimelineEntry {
    let date: Date
    let routines: [String]
}

private struct RepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RepsEntry {
        RepsEntry(date: .now, routines: ["Monday — Push", "Wednesday — Pull", "Friday — Legs"])
    }

    func getSnapshot(in context: Context, completion: @escaping (RepsEntry) -> Void) {
        completion(RepsEntry(date: .now, routines: Shared.routineNames()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RepsEntry>) -> Void) {
        completion(Timeline(entries: [RepsEntry(date: .now, routines: Shared.routineNames())], policy: .never))
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

private enum Palette {
    static let background = Color(hex: 0x141416)
    static let primary = Color.white
    static let secondary = Color(hex: 0x8E8E93)
    static let accent = Color(hex: 0x2EE59D)
    static let divider = Color.white.opacity(0.0824)
}

// MARK: - Views

/// The accent diagonal bar from the app icon.
private struct Mark: View {
    var height: CGFloat = 30
    var body: some View {
        Capsule()
            .fill(Palette.accent)
            .frame(width: height * 0.4, height: height)
            .rotationEffect(.degrees(20))
    }
}

private struct BrandingColumn: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Mark()
            Spacer(minLength: 8)
            Text("Reps")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Palette.primary)
        }
    }
}

private struct RepsQuickWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let routines: [String]

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) { Palette.background }
    }

    @ViewBuilder
    private var content: some View {
        if family == .systemLarge {
            HStack(alignment: .top, spacing: 20) {
                BrandingColumn()
                    .frame(maxWidth: .infinity, alignment: .leading)
                routineList
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            BrandingColumn()
        }
    }

    /// Up to three routines, listed on the right.
    private var routineList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if routines.isEmpty {
                Text("Open Reps to add routines")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(routines.prefix(3).enumerated()), id: \.offset) { index, name in
                    if index > 0 {
                        Divider().overlay(Palette.divider)
                    }
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Widget

/// A Home Screen widget that opens Reps; the large size also lists routines.
struct RepsQuickWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RepsQuickWidget", provider: RepsProvider()) { entry in
            RepsQuickWidgetView(routines: entry.routines)
        }
        .configurationDisplayName("Reps")
        .description("Open Reps and see your routines.")
        // Xcode's widget preview requests systemMedium; all three families are
        // supported so the host can always render it.
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
