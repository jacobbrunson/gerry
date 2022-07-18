//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation

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
                print(await self.screenCaptureController.stopRecording())
                self.transition(to: .saving)
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