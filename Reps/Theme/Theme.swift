//
//  Theme.swift
//  Reps
//
//  Central design tokens. Colours, opacities and the shared numeric
//  formatter live here so every screen stays visually consistent.
//

import SwiftUI

/// Design tokens from the Figma spec. All colours are literal hex values,
/// intentionally not routed through the asset catalog so the palette is
/// visible and reviewable in one place.
enum Theme {
    /// App background (#141416).
    static let background = Color(hex: 0x141416)
    /// One step lighter than the background, used for cards (#1C1C1E).
    static let surface = Color(hex: 0x1C1C1E)
    /// A slightly lighter surface for chips/pills on the review screen.
    static let surfaceRaised = Color(hex: 0x2C2C2E)
    /// Primary text and icons.
    static let primary = Color.white
    /// Secondary text: labels, set numbers, hints, inactive states (#8E8E93).
    static let secondary = Color(hex: 0x8E8E93)
    /// Accent green (#2EE59D).
    static let accent = Color(hex: 0x2EE59D)

    /// Divider lines: white at 8.24% opacity.
    static let divider = Color.white.opacity(0.0824)
    /// Subtle accent highlight at 20%.
    static let accentTint = Color(hex: 0x2EE59D).opacity(0.20)
    /// Subtle accent highlight at 10.2%.
    static let accentTintFaint = Color(hex: 0x2EE59D).opacity(0.102)
}

extension Color {
    /// Creates a colour from a 24-bit RGB hex literal, e.g. `0x141416`.
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

enum Format {
    /// Formats a weight without a trailing `.0` (e.g. `80`, `82.5`).
    nonisolated static func weight(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%g", value)
    }
}
