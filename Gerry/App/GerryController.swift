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

    init() {
        DispatchQueue.main.async {
            Task {
                let display = await self.screenCaptureController.getDisplay()
                FinishingView(videoURL: URL(string: "file:///var/folders/p3/rnrgknms7c72zcxt79p8dw440000gn/T/me.brunson.Gerry/0198E00D-1B07-43A8-A252-90CB6C0EE9B1.mp4")!).openNewWindow(title: "Gerry - Save", contentRect: CGRect(x: 0, y: 0, width: display.width, height: display.height-400))
            }
        }
        statusBarController.clickHandler = { [self]
            if self.state == .idle {
                self.transition(to: .loading)
                await self.screenCaptureController.beginRecording()
                self.transition(to: .recording)
            } else if self.state == .recording {
                let videoURL = await self.screenCaptureController.stopRecording()
                print(videoURL)
                self.transition(to: .saving)
                DispatchQueue.main.async {
                    Task {
                        let display = await self.screenCaptureController.getDisplay()
                        FinishingView(videoURL: videoURL).openNewWindow(title: "Gerry - Save", contentRect: CGRect(x: 0, y: 0, width: display.width, height: display.height))
                    }
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