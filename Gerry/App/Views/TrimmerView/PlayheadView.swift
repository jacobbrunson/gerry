//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AppKit

class PlayheadView: NSView {
    let width: CGFloat = 4

    var t: CGFloat = 0

    func update(t: CGFloat) {
        self.t = t
        setNeedsDisplay(superview!.frame)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        let x = t * superview!.frame.width - width / 2
        frame = CGRect(x: x, y: 0, width: width, height: superview!.frame.height)

        context.saveGState()
        context.addRect(CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        context.setFillColor(CGColor(red: 1, green: 0.8, blue: 0, alpha: 1))
        context.drawPath(using: .fill)
        context.restoreGState()
    }
}