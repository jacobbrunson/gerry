//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct HighlightTextField: NSViewRepresentable {

    @Binding var text: String

    func makeNSView(context: Context) -> HighlightNSTextField {
        HighlightNSTextField()
    }

    func updateNSView(_ textField: HighlightNSTextField, context: Context) {
        textField.stringValue = text
    }

    class HighlightNSTextField: NSTextField {
        override func mouseDown(with event: NSEvent) {
            if let textEditor = currentEditor() {
                textEditor.selectAll(self)
            }
        }
    }
}