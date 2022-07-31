//
// Created by Jacob Brunson on 7/17/22.
//

import AppKit

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem

    public var clickHandler: (() async -> ())?

    init() {
        statusBar = NSStatusBar.init()
        statusItem = statusBar.statusItem(withLength: 28.0)

        if let statusBarButton = statusItem.button {
            setStatusBarButtonImage(imageLiteralResourceName: getIconName(.idle))
            statusBarButton.action = #selector(onClick(sender:))
            statusBarButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            statusBarButton.target = self
        }
    }

    func updateIcon(_ state: GerryState) {
        setStatusBarButtonImage(imageLiteralResourceName: getIconName(state))
    }

    private func getIconName(_ state: GerryState) -> String  {
        switch (state) {
        case .idle:
            return "G.png"
        case .loading:
            return "G.png"
        case.recording:
            return "stop.png"
        case.saving:
            return "G.png"
        }
    }

    @objc private func onClick(sender: AnyObject)  {
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.leftMouseUp {
            if clickHandler != nil && statusItem.menu == nil {
                Task {
                    await clickHandler!()
                }
            }
        } else {
            constructMenu()
            statusItem.button?.performClick(nil)
        }
    }

    private func setStatusBarButtonImage(imageLiteralResourceName: String) {
        if let statusBarButton = statusItem.button {
            statusItem.button?.image = NSImage(imageLiteralResourceName: imageLiteralResourceName)
            statusItem.button?.image?.size = NSSize(width: 18.0, height: 18.0)
            statusBarButton.image?.isTemplate = true
        }
    }

    func constructMenu() {
        let menu = GerryMenu()
        menu.addItem(NSMenuItem(title: "Quit Gerry", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.delegate = menu
        menu.statusItem = statusItem
        statusItem.menu = menu
    }
}

class GerryMenu: NSMenu, NSMenuDelegate {
    var statusItem: NSStatusItem?

    @objc
    func menuDidClose(_ menu: NSMenu) {
        statusItem?.menu = nil
    }
}