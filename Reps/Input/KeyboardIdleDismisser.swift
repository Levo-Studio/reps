//
//  KeyboardIdleDismisser.swift
//  Reps
//

import UIKit

/// Dismisses the keyboard after a few seconds without typing. One app-wide
/// observer covers every field — the UIKit-backed `NumberField` and all SwiftUI
/// `TextField`s alike — because they all post the same text-change notifications.
///
/// The countdown starts when the keyboard appears and resets on every keystroke,
/// so an idle field (whether the user paused typing or never started) is closed
/// after `idleInterval` seconds.
final class KeyboardIdleDismisser: NSObject {
    static let shared = KeyboardIdleDismisser()

    /// Idle time before the keyboard is dismissed.
    private let idleInterval: TimeInterval = 3

    private var timer: Timer?
    private var active = false

    private override init() { super.init() }

    /// Starts observing keyboard and typing activity. Safe to call once at launch.
    func activate() {
        guard !active else { return }
        active = true
        let center = NotificationCenter.default
        // Any keystroke in any field resets the idle countdown.
        center.addObserver(self, selector: #selector(bump),
                           name: UITextField.textDidChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(bump),
                           name: UITextView.textDidChangeNotification, object: nil)
        // Showing the keyboard — even without typing — starts the countdown.
        center.addObserver(self, selector: #selector(bump),
                           name: UIResponder.keyboardDidShowNotification, object: nil)
        // Once it's gone, stop counting.
        center.addObserver(self, selector: #selector(cancel),
                           name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func bump() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: idleInterval, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    @objc private func cancel() {
        timer?.invalidate()
        timer = nil
    }

    private func dismiss() {
        timer = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
