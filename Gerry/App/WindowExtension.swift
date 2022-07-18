//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI

extension View {
    private func newWindowInternal(with title: String) -> NSWindow {
        let window = NSWindow(
                contentRect: NSRect(x: 20, y: 20, width: 680, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.makeKeyAndOrderFront(nil)
        return window
    }

    func openNewWindow(with title: String) {
        self.newWindowInternal(with: title).contentView = NSHostingView(rootView: self)
    }
}
