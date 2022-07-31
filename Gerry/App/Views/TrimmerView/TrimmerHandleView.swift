//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AppKit

enum TrimmerHandlePosition {
    case left
    case right
}

class TrimmerHandleView: NSView {
    static let width: CGFloat = 12

    var position: TrimmerHandlePosition = .left
    var t: CGFloat = 0
    var onUpdate: (CGFloat) -> () = { _ in }

    var widthT: CGFloat {
        superview == nil ? 0 : TrimmerHandleView.width / superview!.frame.width
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        let x = t * superview!.frame.width + (position == .right ? -TrimmerHandleView.width : 0)
        frame = CGRect(x: x, y: 0, width: TrimmerHandleView.width, height: superview!.frame.height)

        context.saveGState()
        context.addRect(frame)
        context.setFillColor(CGColor(red: 1, green: 0.8, blue: 0, alpha: 1))
        context.drawPath(using: .fill)
        context.restoreGState()
    }

    override func mouseDragged(with event: NSEvent) {
        let deltaT = event.deltaX / superview!.frame.width

        let lowerBound = position == .left ? 0 : widthT * 2
        let upperBound = position == .left ? 1 - widthT * 2 : 1

        t = min(max(lowerBound, t + deltaT), upperBound)
        onUpdate(t)
        superview!.setNeedsDisplay(superview!.frame)
    }
}
