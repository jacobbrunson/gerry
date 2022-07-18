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
        if clickHandler != nil {
            Task {
                await clickHandler!()
            }
        }
    }

    private func setStatusBarButtonImage(imageLiteralResourceName: String) {
        if let statusBarButton = statusItem.button {
            statusItem.button?.image = NSImage(imageLiteralResourceName: imageLiteralResourceName)
            statusItem.button?.image?.size = NSSize(width: 18.0, height: 18.0)
            statusBarButton.image?.isTemplate = true
        }
    }
}
