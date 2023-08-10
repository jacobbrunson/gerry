//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import AppKit
import SwiftUI
import CoreGraphics

class GerryController {
    let screenCaptureController = ScreenCaptureController()
    let statusBarController = StatusBarController()

    var openWindows = 0

    var unsavedVideos: Set<URL> = []

    var windowControllers: [URL:NSWindowController] = [:]
    
    
    init() {
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
        } else {
            statusBarController.hasPermission = true
        }
        NSApp.setActivationPolicy(.accessory)
        
        
        statusBarController.onRecord = { [unowned self] in
            Task {
                await openWindowsDialog()
                if await screenCaptureController.beginRecording() {
                    statusBarController.isRecording = true
                } else {
                    statusBarController.isRecording = false
                    statusBarController.hasPermission = false
                    // Handles case where permission is revoked while app is running
                    // Also handles other unexpected failures? Might wanna handle those separately later
                    DispatchQueue.main.async {
                        permissionHelp()
                    }
                }
            }
        }

        statusBarController.onStop = { [unowned self] in
            Task {
                let videoURL = await screenCaptureController.stopRecording()
                statusBarController.isRecording = false
                openSaveWindow(videoURL: videoURL)
            }
        }

        statusBarController.onOpen = { [unowned self] selectedUrl in
            openSaveWindow(videoURL: selectedUrl)
        }
    }

    public func openSaveWindow(videoURL: URL) {
        DispatchQueue.main.async {
            Task {
                let display = await self.screenCaptureController.getDisplay()
                let view = SaveWindowContentView(assetURL: videoURL, onExport: { [weak self] in
                    self?.unsavedVideos.remove(videoURL)
                    if UserDefaults.standard.value(forKey: "autoClose") as? Bool == true {
                        self?.windowControllers[videoURL]?.close()
                    }
                })
                let windowController = view.openNewWindow(title: "Gerry - Save", contentRect: CGRect(x: 0, y: 0, width: display.width, height: display.height))
                self.openWindows += 1
                self.windowControllers[videoURL] = windowController
                self.unsavedVideos.insert(videoURL)
                windowController.shouldClose = { [weak self] windowController in
                    guard let unsavedVideos = self?.unsavedVideos else { return true }
                    if unsavedVideos.contains(videoURL) {
                        self!.unsavedVideoDialog(windowController: windowController)
                        return false
                    }
                    return true
                }
                windowController.onClose = { [weak self] windowController in
                    guard self != nil else { return }
                    self!.windowControllers.removeValue(forKey: videoURL)
                    self!.openWindows -= 1
                    self!.unsavedVideos.remove(videoURL)
                    if self!.openWindows == 0 {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }

            }
        }
    }

    private func unsavedVideoDialog(windowController: GerryWindowController) {
        let unsavedVideoAction = UserDefaults.standard.value(forKey: "unsavedVideoAction") as? String

        if unsavedVideoAction == "close" {
            windowController.close()
        } else if unsavedVideoAction == nil {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Unsaved recording"
                alert.informativeText = "You are about to close a recording without saving. The recording will be lost. Are you sure you wish to do this?"
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "Close without saving")
                alert.alertStyle = .critical
                alert.showsSuppressionButton = true

                let shouldClose = alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn

                if alert.suppressionButton?.state.rawValue == 1 {
                    UserDefaults.standard.set(shouldClose ? "close" : "no-close", forKey: "unsavedVideoAction")
                }

                if shouldClose {
                    windowController.close()
                }
            }
        }
    }

    private func openWindowsDialog() async -> () {
        if openWindows > 0 {
            let openWindowsAction = UserDefaults.standard.value(forKey: "openWindowsAction") as? String

            if openWindowsAction == "close" {
                closeAllSaveWindows()
            } else if openWindowsAction == nil {
                return await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Close Gerry window\(self.openWindows > 1 ? "s" : "")?"
                        alert.informativeText = "You have \(self.openWindows > 1 ? String(self.openWindows) : "a") Gerry save window\(self.openWindows > 1 ? "s" : "") open, which can reduce performance. For the smoothest video, close all Gerry windows."
                        alert.addButton(withTitle: "Close \(self.openWindows) Gerry window\(self.openWindows > 1 ? "s" : "")")
                        alert.addButton(withTitle: "Don't close")
                        alert.alertStyle = .warning
                        alert.showsSuppressionButton = true

                        let shouldClose = alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn

                        if alert.suppressionButton?.state.rawValue == 1 {
                            UserDefaults.standard.set(shouldClose ? "close" : "no-close", forKey: "openWindowsAction")
                        }

                        if shouldClose {
                            self.closeAllSaveWindows()
                        }

                        continuation.resume()
                    }
                }
            }

            return await withCheckedContinuation { continuation in continuation.resume() }
        }


    }

    private func closeAllSaveWindows() {
        DispatchQueue.main.async {
            NSApp!.windows.forEach {
                if $0.title.contains("Save") {
                    $0.performClose(self)
                }
            }
        }
    }
}
