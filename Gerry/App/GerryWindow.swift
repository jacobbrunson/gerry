//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI

extension View {
    func openNewWindow(title: String, contentRect: CGRect) -> GerryWindow {
        let window = GerryWindow(
                contentRect: contentRect,
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.contentView = NSHostingView(rootView: self)
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        return window
    }
}


class GerryWindow: NSWindow, NSWindowDelegate {
    var shouldClose: (() -> Bool)?
    var onClose: (() -> ())?

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        shouldClose == nil ? true : shouldClose!()
    }

    @objc func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
