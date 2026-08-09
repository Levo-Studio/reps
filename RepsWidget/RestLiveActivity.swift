//
//  RestLiveActivity.swift
//  RepsWidget
//
//  Lock Screen / Dynamic Island presentation for the rest-timer Live Activity.
//  This file references the shared `RestActivityAttributes` (defined in the app
//  target and added to this extension's target membership) — it does not
//  redefine it.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Design Tokens

private enum RepsTheme {
    static let background = Color(hex: 0x141416)
    static let surface = Color(hex: 0x1C1C1E)
    static let primary = Color(hex: 0xFFFFFF)
    static let secondary = Color(hex: 0x8E8E93)
    static let accent = Color(hex: 0x2EE59D)
}

// MARK: - Color(hex:) helper

private extension Color {
    /// Builds a color from a 24-bit RGB integer literal, e.g. `0x2EE59D`.
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

// MARK: - Shared subviews

/// The app icon mark: the dark rounded square with the accent diagonal bar.
/// Drawn directly (rather than loaded from an asset) so it renders reliably in
/// the Live Activity, which tints asset images.
private struct LogoMark: View {
    var side: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
            .fill(RepsTheme.background)
            .frame(width: side, height: side)
            .overlay(
                Capsule()
                    .fill(RepsTheme.accent)
                    .frame(width: side * 0.24, height: side * 0.6)
                    .rotationEffect(.degrees(20))
            )
    }
}

/// Native countdown text. Ticks on its own without pushed content updates.
///
/// The frame is constrained and right-aligned so the glyphs don't jitter as the
/// digit widths change, and it can shrink to still fit a large remaining time.
private struct CountdownText: View {
    let endDate: Date
    var font: Font = .system(size: 34, weight: .semibold, design: .rounded)

    var body: some View {
        Text(timerInterval: Date.now...endDate, countsDown: true)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(RepsTheme.accent)
            .lineLimit(1)
    }
}

// MARK: - Live Activity

/// The rest-timer Live Activity: a Lock Screen banner plus Dynamic Island
/// presentations, all driven by the shared `RestActivityAttributes`.
@available(iOS 16.2, *)
struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            LockScreenView(context: context)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        LogoMark(side: 20)
                        Text("Reps")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RepsTheme.primary)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Rest Timer")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(RepsTheme.secondary)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Routine + next set on the left, the timer vertically
                    // centered against them on the right.
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.routineName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(RepsTheme.primary)
                                .lineLimit(1)
                            Text("Next: \(context.attributes.nextExercise) • Set \(context.attributes.nextSetNumber)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(RepsTheme.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }

                        Spacer(minLength: 8)

                        if context.state.endDate <= Date() {
                            Text("Rest over")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(RepsTheme.accent)
                        } else {
                            CountdownText(
                                endDate: context.state.endDate,
                                font: .system(size: 30, weight: .semibold, design: .rounded)
                            )
                            .frame(width: 74, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
                }
            } compactLeading: {
                LogoMark(side: 15)
            } compactTrailing: {
                // `Text(timerInterval:)` is greedy and fills the trailing width,
                // which stretched the pill wide. Cap it so the time hugs the
                // camera and the pill stays narrow, like a normal timer.
                CountdownText(
                    endDate: context.state.endDate,
                    font: .system(size: 15, weight: .semibold, design: .rounded)
                )
                .frame(maxWidth: 44)
            } minimal: {
                CountdownText(
                    endDate: context.state.endDate,
                    font: .system(size: 13, weight: .semibold, design: .rounded)
                )
                .frame(maxWidth: 40)
            }
            .keylineTint(RepsTheme.accent)
        }
    }
}

// MARK: - Lock Screen presentation

/// The Lock Screen / banner layout. Uses the default system rendering — no
/// solid background is applied to the root so it composites over the system
/// material as a native Live Activity.
@available(iOS 16.2, *)
private struct LockScreenView: View {
    let context: ActivityViewContext<RestActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top line: logo + app name (leading) · "Rest Timer" (trailing)
            HStack(spacing: 6) {
                LogoMark(side: 20)
                Text("Reps")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RepsTheme.primary)

                Spacer(minLength: 8)

                Text("Rest Timer")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(RepsTheme.secondary)
            }

            // Second line: routine/"Rest over" + next set (leading) · countdown
            // pinned hard right (trailing).
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(isOver ? "Rest over" : context.attributes.routineName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(isOver ? RepsTheme.accent : RepsTheme.primary)
                        .lineLimit(1)
                    Text("Next: \(context.attributes.nextExercise) • Set \(context.attributes.nextSetNumber)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(RepsTheme.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isOver {
                    CountdownText(
                        endDate: context.state.endDate,
                        font: .system(size: 32, weight: .semibold, design: .rounded)
                    )
                    .frame(width: 72, alignment: .trailing)
                }
            }
        }
    }

    /// Whether the rest has elapsed — the view re-renders around the end date.
    private var isOver: Bool { context.state.endDate <= Date() }
}
