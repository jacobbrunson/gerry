//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AppKit
import AVFoundation

class PlayheadView: NSView {
    private static let width: CGFloat = 4

    var player: AVPlayer?

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        let currentTime = player?.currentTime().seconds ?? 0
        let maybeDuration = player?.currentItem?.duration.seconds
        let duration = maybeDuration == nil || maybeDuration!.isNaN || maybeDuration! <= 0 ? 1 : maybeDuration!
        let t = currentTime / duration

        let x = t * superview!.frame.width - PlayheadView.width / 2
        frame = CGRect(x: x, y: 0, width: PlayheadView.width, height: superview!.frame.height)

        context.saveGState()
        context.addRect(CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        context.setFillColor(CGColor(red: 1, green: 0.8, blue: 0, alpha: 1))
        context.drawPath(using: .fill)
        context.restoreGState()
    }
}