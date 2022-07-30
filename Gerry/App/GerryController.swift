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
    var windowVideos: [NSWindow: URL] = [:]

    init() {
        NSApp.setActivationPolicy(.accessory)
        statusBarController.clickHandler = {
            if self.state == .idle {
                await self.openWindowsDialog()
                self.transition(to: .loading)
                await self.screenCaptureController.beginRecording()
                self.transition(to: .recording)
            } else if self.state == .recording {
                let videoURL = await self.screenCaptureController.stopRecording()
                self.transition(to: .idle)
                self.openSaveWindow(videoURL: videoURL)
            }
        }
    }

    private func openSaveWindow(videoURL: URL) {
        DispatchQueue.main.async {
            Task {
                let display = await self.screenCaptureController.getDisplay()
                let window = ExportView(videoURL: videoURL, onExport: {
                    self.unsavedVideos.remove(videoURL)
                }).openNewWindow(title: "Gerry - Save", contentRect: CGRect(x: 0, y: 0, width: display.width, height: display.height))
                self.openWindows += 1
                self.unsavedVideos.insert(videoURL)
                window.shouldClose = {
                    if self.unsavedVideos.contains(videoURL) {
                        self.unsavedVideoDialog(window: window)
                        return false
                    }
                    return true
                }
                window.onClose = {
                    self.openWindows -= 1
                    self.unsavedVideos.remove(videoURL)
                    if self.openWindows == 0 {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
                NotificationCenter.default.addObserver(window, selector: #selector(GerryWindow.windowWillClose), name: NSWindow.willCloseNotification, object: window)
            }
        }
    }

    private func unsavedVideoDialog(window: NSWindow) {
        let unsavedVideoAction = UserDefaults.standard.value(forKey: "unsavedVideoAction") as? String

        if unsavedVideoAction == "close" {
            window.close()
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
                    window.close()
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
                        alert.addButton(withTitle: "Don't close")
                        alert.addButton(withTitle: "Close \(self.openWindows) Gerry window\(self.openWindows > 1 ? "s" : "")")
                        alert.alertStyle = .warning
                        alert.showsSuppressionButton = true

                        let shouldClose = alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn

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
