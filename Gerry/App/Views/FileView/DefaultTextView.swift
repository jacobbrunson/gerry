//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct DefaultTextField: View {
    @Binding var value: String
    let defaultValue: String
    let clearDefaultOnFocus: Bool

    init(value: Binding<String>, defaultValue: String, clearDefaultOnFocus: Bool = true) {
        self._value = value
        self.defaultValue = defaultValue
        self.clearDefaultOnFocus = clearDefaultOnFocus
    }

    @FocusState private var isFocused: Bool

    var body: some View {
        let valueBinding = Binding<String>(get: {
            if !value.isEmpty || (isFocused && clearDefaultOnFocus) {
                return value
            }
            return defaultValue
        }, set: {
            if isFocused {
                value = $0
            }
        })

        TextField("", text: valueBinding).focused($isFocused).onChange(of: isFocused) { _ in }
    }
}