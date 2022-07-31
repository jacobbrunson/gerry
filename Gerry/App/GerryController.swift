//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import AppKit
import SwiftUI

class GerryController {
    let screenCaptureController = ScreenCaptureController()
    let statusBarController = StatusBarController()

    var state = GerryState.idle

    var openWindows = 0

    var unsavedVideos: Set<URL> = []

    var windowControllers: Set<NSWindowController> = []

    init() {
        NSApp.setActivationPolicy(.accessory)
        statusBarController.onClick = { [unowned self] in
            if state == .idle {
                await openWindowsDialog()
                transition(to: .loading)
                await screenCaptureController.beginRecording()
                transition(to: .recording)
            } else if state == .recording {
                let videoURL = await screenCaptureController.stopRecording()
                transition(to: .idle)
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
                })
                let windowController = view.openNewWindow(title: "Gerry - Save", contentRect: CGRect(x: 0, y: 0, width: 1920, height: 1080))
                self.openWindows += 1
                self.windowControllers.insert(windowController)
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
                    self!.windowControllers.remove(windowController)
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

    private func transition(to: GerryState) {
        state = to
        statusBarController.updateIcon(state)
    }
}

enum GerryState {
    case idle
    case loading
    case recording
    case saving
}
