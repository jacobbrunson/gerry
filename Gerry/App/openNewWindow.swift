//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI

extension View {
    func openNewWindow(title: String, contentRect: CGRect) {
        let window = NSWindow(
                contentRect: contentRect,
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.contentView = NSHostingView(rootView: self)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
