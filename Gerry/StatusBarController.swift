//
// Created by Jacob Brunson on 7/17/22.
//

import AppKit

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem

    let TEMP = ScreenCaptureController()

    init() {
        statusBar = NSStatusBar.init()
        // Creating a status bar item having a fixed length
        statusItem = statusBar.statusItem(withLength: 28.0)

        if let statusBarButton = statusItem.button {
            setStatusBarButtonImage(imageLiteralResourceName: "G.png")
            statusBarButton.action = #selector(onClick(sender:))
            statusBarButton.target = self
        }
    }

    @objc func onClick(sender: AnyObject)  {
        print("clicked!")
        setStatusBarButtonImage(imageLiteralResourceName: "stop.png")
        Task {
            await TEMP.beginRecording()
            try! await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
            print(await TEMP.stopRecording())
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
