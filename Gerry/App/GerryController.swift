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

    init() {
        openEditorWindow(videoURL: URL(string: "file:///var/folders/p3/rnrgknms7c72zcxt79p8dw440000gn/T/me.brunson.Gerry/FF3FD846-2B63-408F-B989-4430EF3235C7.mp4")!)
        statusBarController.clickHandler = {
            if self.state == .idle {
                await self.openWindowsDialog()
                self.transition(to: .loading)
                await self.screenCaptureController.beginRecording()
                self.transition(to: .recording)
            } else if self.state == .recording {
                let videoURL = await self.screenCaptureController.stopRecording()
                self.transition(to: .idle)
                self.openEditorWindow(videoURL: videoURL)
            }
        }
    }

    private func openEditorWindow(videoURL: URL) {
        DispatchQueue.main.async {
            Task {
                let display = await self.screenCaptureController.getDisplay()
                let window = ExportView(videoURL: videoURL).openNewWindow(title: "Gerry - Save", contentRect: CGRect(x: 0, y: 0, width: display.width, height: display.height))
                self.openWindows += 1
                window.onClose = {
                    self.openWindows -= 1
                    if self.openWindows == 0 {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
                NotificationCenter.default.addObserver(window, selector: #selector(GerryWindow.windowWillClose), name: NSWindow.willCloseNotification, object: window)
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
                    $0.close()
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
