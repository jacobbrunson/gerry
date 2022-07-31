//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI

extension View {
    func openNewWindow(title: String, contentRect: CGRect) -> GerryWindowController {
        let window = NSWindow(
                contentRect: contentRect,
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
        window.isReleasedWhenClosed = true
        window.title = title
        window.contentView = NSHostingView(rootView: self)
        window.center()

        let windowController = GerryWindowController(window: window)
        windowController.windowFrameAutosaveName = "GerrySaveWindowFrame"
        window.delegate = windowController

        windowController.showWindow(self)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        return windowController
    }
}

class GerryWindowController: NSWindowController, NSWindowDelegate {
    var shouldClose: ((_ windowController: GerryWindowController) -> Bool)?

    func windowShouldClose(_ sender: NSWindow) -> Bool {
       shouldClose == nil ? true : shouldClose!(self)
    }
    
    var onClose: ((_ windowController: GerryWindowController) -> ())?

    @objc func windowWillClose(_ notification: Notification) {
        window?.contentView = nil
        onClose?(self)
    }
}
