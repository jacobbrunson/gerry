//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI
import AppKit
import AVKit

struct PlayerCropperView: NSViewControllerRepresentable {
    let player: AVPlayer

    func makeNSViewController(context: Context) -> PlayerCropperViewController {
        let viewController = PlayerCropperViewController()
        viewController.player = player
        return viewController
    }

    func updateNSViewController(_ viewController: PlayerCropperViewController, context: Context) {
        viewController.player = player
    }
}

class PlayerCropperViewController: NSViewController {
    var player = AVPlayer()

    let playerView = AVPlayerView()
    let cropperView = CropperView()

    override func loadView() {
        playerView.controlsStyle = .none
        playerView.player = player

        view = NSView()
        view.subviews = [playerView, cropperView]
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        playerView.frame = view.bounds
        cropperView.frame = view.bounds
        cropperView.videoSize = player.currentItem!.asset.tracks[0].naturalSize
        cropperView.addTrackingArea(NSTrackingArea(rect: view.bounds, options: [.activeAlways, .mouseMoved], owner: cropperView, userInfo: nil))
    }
}

let yellow = CGColor(red: 1, green: 0.8, blue: 0, alpha: 1)
let lineWidth = 2.0
let handleWidth = lineWidth * 2
let handleLength = lineWidth * 9


class CropperView: NSView {
    private var _videoSize = CGSize.zero
    var videoSize: CGSize {
        get { _videoSize }
        set {
            _videoSize = newValue
            start = constrainToVideoViewport(CGPoint.zero)
            end = constrainToVideoViewport(CGPoint(x: CGFloat.infinity, y: CGFloat.infinity))
        }
    }

    var start = CGPoint.zero
    var end = CGPoint.zero
    var handle: CropHandle?

    var handles: [CropHandle] = [
        VertexCropHandle(.topLeft),
        EdgeCropHandle(.top),
        VertexCropHandle(.topRight),
        EdgeCropHandle(.right),
        VertexCropHandle(.bottomLeft),
        EdgeCropHandle(.bottom),
        VertexCropHandle(.bottomRight),
        EdgeCropHandle(.left)
    ]

    var rect: CGRect {
        CGRect(
                x: start.x,
                y: start.y,
                width: end.x - start.x,
                height: end.y - start.y
        )
    }

    func constrain(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        let x = min(max(rect.minX, point.x), rect.maxX)
        let y = min(max(rect.minY, point.y), rect.maxY)
        return CGPoint(x: x, y: y)
    }

    func constrainToVideoViewport(_ point: CGPoint) -> CGPoint {
        let aspectRatio = videoSize.width / videoSize.height
        let actualHeight = bounds.height
        let actualWidth = aspectRatio * actualHeight

        let minX = bounds.midX - actualWidth / 2
        let maxX = bounds.midX + actualWidth / 2
        let minY = 0.0
        let maxY = frame.maxY

        return constrain(point, to: CGRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
        ))
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.saveGState()
        context.clear(bounds)
        let trueRect = rect
        let displayRect = CGRect(x: trueRect.minX + lineWidth / 2, y: trueRect.minY + lineWidth / 2, width: trueRect.width - lineWidth, height: trueRect.height - lineWidth)

        context.addRects([
            CGRect(
                    x: 0,
                    y: displayRect.maxY,
                    width: frame.width,
                    height: frame.height - displayRect.maxY
            ),
            CGRect(
                    x: displayRect.maxX,
                    y: 0,
                    width: frame.width - displayRect.maxX,
                    height: frame.height
            ),
            CGRect(
                    x: 0,
                    y: 0,
                    width: frame.width,
                    height: displayRect.minY
            ),
            CGRect(
                    x: 0,
                    y: 0,
                    width: displayRect.minX,
                    height: frame.height
            ),
        ])
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        context.drawPath(using: .fill)

        context.addRect(displayRect)
        context.setStrokeColor(yellow)
        context.setLineWidth(lineWidth)
        context.drawPath(using: .stroke)

        for i in 0..<handles.count {
            var handle = handles[i]
            handle.rect = displayRect
            handle.draw(context)
        }

        context.restoreGState()
    }

    override func mouseDown(with event: NSEvent) {
        let mouseLocation = convert(event.locationInWindow, from: nil)

        handle = nil
        for candidateHandle in handles {
            if testGrab(pointA: mouseLocation, pointB: candidateHandle.point) {
                handle = candidateHandle
                addTrackingArea(NSTrackingArea(rect: candidateHandle.rect, owner: self))
                break
            }
        }

        if handle == nil {
            start = constrainToVideoViewport(mouseLocation)
            end = constrainToVideoViewport(mouseLocation)
        }

        setNeedsDisplay(bounds)
    }

    override func mouseUp(with event: NSEvent) {
//        onSelect!(getRect())
    }

    override func mouseDragged(with event: NSEvent) {
        if handle == nil {
            end.x += event.deltaX
            end.y -= event.deltaY
        } else {
            (start, end) = handle!.update(start: start, end: end, deltaX: event.deltaX, deltaY: event.deltaY)
        }

        start = constrainToVideoViewport(start)
        end = constrainToVideoViewport(end)

        setNeedsDisplay(bounds)
    }

    override func mouseMoved(with event: NSEvent) {
        discardCursorRects()

        let mouseLocation = convert(event.locationInWindow, from: nil)

        for candidateHandle in handles {
            if testGrab(pointA: mouseLocation, pointB: candidateHandle.point) {
                addCursorRect(bounds, cursor: candidateHandle.cursor)
                return
            }
        }

        if mouseLocation.equalTo(constrainToVideoViewport(mouseLocation)) {
            addCursorRect(bounds, cursor: NSCursor.crosshair)
        } else {
            addCursorRect(bounds, cursor: NSCursor.arrow)
        }
    }

    private func testGrab(pointA: CGPoint, pointB: CGPoint) -> Bool {
        pow(pointA.x - pointB.x, 2) + pow(pointA.y - pointB.y, 2) < pow(handleLength, 2)
    }
}
