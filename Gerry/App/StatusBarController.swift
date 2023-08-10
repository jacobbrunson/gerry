//
// Created by Jacob Brunson on 7/17/22.
//

import AppKit

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem

    public var onOpen: ((_ url: URL) -> ())?
    public var onRecord: (() -> ())?
    public var onStop: (() -> ())?
    
    public var hasPermission = false

    private var _isRecording = false
    public var isRecording: Bool {
        get { _isRecording }
        set {
            _isRecording = newValue
            updateIcon()
        }
    }

    init() {
        statusBar = NSStatusBar.init()
        statusItem = statusBar.statusItem(withLength: 28.0)

        if let statusBarButton = statusItem.button {
            setStatusBarButtonImage(imageLiteralResourceName: iconName)
            statusBarButton.action = #selector(onClick(sender:))
            statusBarButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            statusBarButton.target = self
        }
    }

    private func updateIcon() {
        setStatusBarButtonImage(imageLiteralResourceName: iconName)
    }

    private var iconName: String  {
        isRecording ? "stop.png" : "G.png"
    }

    @objc private func onClick(sender: AnyObject)  {
        let event = NSApp.currentEvent!

        let oneClickEnabled = (UserDefaults.standard.value(forKey: "oneClickRecording") as? Bool) == true
        let isPrimaryButton = event.type == NSEvent.EventType.leftMouseUp && oneClickEnabled

        if isRecording {
            onStop?()
            return
        }

        if isPrimaryButton {
            if hasPermission {
                guard onRecord != nil, statusItem.menu == nil else { return }
                onRecord!()
            } else {
                // One-click recording is enabled, but they didn't give permission
                permissionHelp()
            }
        } else {
            constructMenu()
            statusItem.button?.performClick(nil)
        }
    }

    private func setStatusBarButtonImage(imageLiteralResourceName: String) {
        DispatchQueue.main.async { [weak statusItem] in
            guard let statusBarButton = statusItem?.button else { return }
            statusBarButton.image = NSImage(imageLiteralResourceName: imageLiteralResourceName)
            statusBarButton.image!.size = NSSize(width: 18.0, height: 18.0)
            statusBarButton.image!.isTemplate = true
        }
    }

    func constructMenu() {
        let menu = GerryMenu()
        menu.delegate = menu
        menu.statusItem = statusItem
        menu.onOpen = onOpen
        menu.onRecord = onRecord
        menu.autoenablesItems = false

        statusItem.menu = menu
        
        if hasPermission {
            let recordItem = NSMenuItem(title: "Start recording", action: #selector(GerryMenu.recordVideo), keyEquivalent: "r")
            recordItem.target = menu
            menu.addItem(recordItem)
        } else {
            let permissionItem = NSMenuItem(title: "Allow Gerry to record your screen...", action: #selector(GerryMenu._permissionHelp), keyEquivalent: "")
            permissionItem.target = menu
            menu.addItem(permissionItem)
        }

        menu.addItem(NSMenuItem.separator())

        let openItem = NSMenuItem(title: "Open video file...", action: #selector(GerryMenu.openVideo), keyEquivalent: "o")
        openItem.target = menu
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(PreferenceMenuItem(
                title: "One-click recording",
                preferenceKey: "oneClickRecording",
                isBoolean: true,
                onEnable: {
                    let alert = NSAlert()
                    alert.messageText = "Enable one-click recording?"
                    alert.informativeText = "Left-click will begin recording. Right-click will open the menu."
                    alert.addButton(withTitle: "Enable")
                    alert.addButton(withTitle: "Cancel")
                    
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    
                    let shouldEnable = alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
                    return shouldEnable
                }
        ))
        menu.addItem(PreferenceMenuItem(
            title: "Highlight mouse clicks",
            preferenceKey: "highlightClicks",
            isBoolean: true,
            onEnable: { true }
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(PreferenceMenuItem(title: "Auto-close window after exporting", preferenceKey: "autoClose", isBoolean: true, onEnable: { true }))
        
        menu.addItem(PreferenceMenuItem(
                title: "Show \"unsaved video\" warnings",
                preferenceKey: "unsavedVideoAction"
        ))
        menu.addItem(PreferenceMenuItem(
                title: "Show \"open save window\" warnings",
                preferenceKey: "openWindowsAction"
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit Gerry", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
}

class PreferenceMenuItem: NSMenuItem, NSMenuDelegate {
    var preferenceKey = ""
    var isBoolean = false
    var onEnable = { false }

    init(title: String, preferenceKey: String, isBoolean: Bool, onEnable: (() -> Bool)?) {
        self.preferenceKey = preferenceKey
        self.isBoolean = isBoolean
        if onEnable != nil {
            self.onEnable = onEnable!
        }
        super.init(title: title, action: #selector(PreferenceMenuItem.onClick), keyEquivalent: "")
        target = self

        let isOn = isBoolean ? savedPreference as? Bool == true : savedPreference == nil
        state = isOn ? .on : .off

        if !isBoolean && isOn {
            isEnabled = false
        }
    }

    convenience init(title: String, preferenceKey: String) {
        self.init(title: title, preferenceKey: preferenceKey, isBoolean: false, onEnable: nil)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    var savedPreference: Any? { UserDefaults.standard.value(forKey: preferenceKey) }

    @objc func onClick() {
        if isBoolean {
            let wasEnabled = savedPreference as? Bool == true
            
            if wasEnabled {
                UserDefaults.standard.set(false, forKey: preferenceKey)
            } else if onEnable() != false {
                UserDefaults.standard.set(true, forKey: preferenceKey)
            }

        } else {
            UserDefaults.standard.removeObject(forKey: preferenceKey)
        }
    }
}

class GerryMenu: NSMenu, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var onOpen: ((_ url: URL) -> ())?
    var onRecord: (() -> ())?

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

    @objc func recordVideo() {
        onRecord?()
    }
    
    @objc func _permissionHelp() {
        permissionHelp()
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

func permissionHelp() {
    let alert = NSAlert()
    alert.messageText = "Gerry needs permission to record your screen"
    alert.informativeText = "You may grant permission to Gerry by enabling the option in System Settings > Privacy & Security > Screen recording and then restarting the app."
    alert.addButton(withTitle: "Ok")
    
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
    
    alert.runModal()
}
