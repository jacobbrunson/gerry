//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AppKit
import AVFoundation

class TimelineView: NSView {
    var leftHandleView: TrimmerHandleView?
    var rightHandleView: TrimmerHandleView?
    var thumbs: [Int:CGImage] = [:]
    var currentTime = CMTime.zero
    var duration = CMTime.zero

    func update(currentTime: CMTime, duration: CMTime) {
        self.currentTime = currentTime
        self.duration = duration
        setNeedsDisplay(frame)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.saveGState()
        context.clear(CGRect(x: 0, y: 0, width: frame.width, height: frame.height))

        // Background
        context.addRect(CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.drawPath(using: .fill)

        // Thumbnails
        for (i, thumb) in thumbs {
            let rect = CGRect(x: thumb.width * i, y: 0, width: thumb.width, height: thumb.height)
            //if rect.intersects(dirtyRect) {
            context.draw(thumb, in: rect)
            //}
        }

        // Handles
        subviews.forEach({ $0.draw(dirtyRect) })

        // Top/bottom selection borders
        let thickness = 4.0
        let minX = leftHandleView!.frame.maxX
        let minY = leftHandleView!.frame.minY
        let maxX = rightHandleView!.frame.minX
        let maxY = rightHandleView!.frame.maxY
        context.addRect(CGRect(x: minX, y: minY, width: maxX - minX, height: thickness))
        context.addRect(CGRect(x: minX, y: maxY - thickness, width: maxX - minX, height: thickness))
        context.setFillColor(CGColor(red: 1, green: 0.8, blue: 0, alpha: 1))
        context.drawPath(using: .fill)

        // Dark overlays
        context.addRect(CGRect(x: 0, y: 0, width: leftHandleView!.frame.minX, height: frame.height ))
        context.addRect(CGRect(x: rightHandleView!.frame.maxX, y: 0, width: frame.width - rightHandleView!.frame.maxX, height: frame.height ))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
        context.drawPath(using: .fill)

        context.restoreGState()
    }
}