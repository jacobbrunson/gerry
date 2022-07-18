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
        statusBarController.clickHandler = { [self]
            if self.state == .idle {
                self.transition(to: .loading)
                await self.screenCaptureController.beginRecording()
                self.transition(to: .recording)
            } else if self.state == .recording {
                let videoURL = await self.screenCaptureController.stopRecording()
                self.transition(to: .saving)
                DispatchQueue.main.async {
                    SavingView(videoURL: videoURL).openNewWindow(with: "test")
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