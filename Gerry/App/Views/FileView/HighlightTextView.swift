//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct HighlightTextField: NSViewRepresentable {

    @Binding var text: String

    func makeNSView(context: Context) -> HighlightNSTextField {
        let field = HighlightNSTextField()
        field.delegate = context.coordinator
        return field
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func updateNSView(_ textField: HighlightNSTextField, context: Context) {
        textField.stringValue = text
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: HighlightTextField

        init(parent: HighlightTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
           let text = (notification.object as! NSTextField).stringValue
            parent.text = text
        }
    }

    class HighlightNSTextField: NSTextField {
        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            currentEditor()?.selectAll(self)
        }
    }
}