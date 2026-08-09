//
//  NumberField.swift
//  Reps
//

import SwiftUI
import UIKit

/// A numeric text field backed by `UITextField` so that tapping it places the
/// cursor at the END of the value (SwiftUI's `TextField` drops the cursor where
/// you tap). Used for the inline weight/reps entry on logged sets.
struct NumberField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "0"
    var keyboard: UIKeyboardType = .numberPad
    var font: UIFont
    var textColor: UIColor
    var placeholderColor: UIColor
    var tint: UIColor

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.keyboardType = keyboard
        field.tintColor = tint
        field.textAlignment = .left
        field.setContentHuggingPriority(.required, for: .horizontal)
        field.setContentCompressionResistancePriority(.required, for: .horizontal)
        field.addTarget(context.coordinator,
                        action: #selector(Coordinator.editingChanged(_:)),
                        for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        if field.text != text { field.text = text }
        field.font = font
        field.textColor = textColor
        field.tintColor = tint
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor, .font: font]
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) { _text = text }

        @objc func editingChanged(_ field: UITextField) {
            text = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ field: UITextField) {
            // Move the caret to the end when the field gains focus.
            DispatchQueue.main.async {
                let end = field.endOfDocument
                field.selectedTextRange = field.textRange(from: end, to: end)
            }
        }
    }
}
