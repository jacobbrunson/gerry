//
// Created by Jacob Brunson on 7/17/22.
//

import AppKit

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem

    public var onClick: (() async -> ())?
    public var onOpen: ((_ url: URL) -> ())?

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
            guard onClick != nil, statusItem.menu == nil else { return }
            Task {
                await onClick!()
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
        menu.delegate = menu
        menu.statusItem = statusItem
        menu.onOpen = onOpen
        menu.autoenablesItems = false
        statusItem.menu = menu

        let openItem = NSMenuItem(title: "Open video file...", action: #selector(GerryMenu.openVideo), keyEquivalent: "o")
        openItem.target = menu
        menu.addItem(openItem)

        menu.addItem(NSMenuItem(title: "Quit Gerry", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
}

class GerryMenu: NSMenu, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var onOpen: ((_ url: URL) -> ())?

    @objc
    func menuDidClose(_ menu: NSMenu) {
        statusItem?.menu = nil
    }

    @objc func openVideo() {
        Task {
            let url = await selectFile()
            onOpen?(url)
        }
    }

    @MainActor
    func selectFile() async -> URL {
        let folderChooserPoint = CGPoint(x: 0, y: 0)
        let folderChooserSize = CGSize(width: 500, height: 600)
        let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
        let folderPicker = NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)

        folderPicker.canChooseDirectories = false
        folderPicker.canChooseFiles = true
        folderPicker.allowsMultipleSelection = false
        folderPicker.allowedContentTypes = [.video, .movie]

        return await withCheckedContinuation{ continuation in
            folderPicker.begin { response in
                if response == .OK {
                    continuation.resume(returning: folderPicker.urls.first!)
                }
            }
        }
    }
}