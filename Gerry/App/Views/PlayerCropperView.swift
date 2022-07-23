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
    }
}

let yellow = CGColor(red: 1, green: 0.8, blue: 0, alpha: 1)
let lineWidth = 2.0
let handleWidth = lineWidth * 2
let handleLength = lineWidth * 9

protocol Handle {
    var cursor: NSCursor { get }
    var rect: CGRect { get set }
    var point: CGPoint { get }
    func draw(_ context: CGContext) -> ()
    func update(start: CGPoint, end: CGPoint, deltaX: CGFloat, deltaY: CGFloat) -> (CGPoint, CGPoint)
}

class CornerHandle: Handle {
    let corner: Corner
    var rect: CGRect = CGRect.zero

    init(_ corner: Corner) {
        self.corner = corner
    }

    func update(start: CGPoint, end: CGPoint, deltaX: CGFloat, deltaY: CGFloat) -> (CGPoint, CGPoint) {
        if isTop && start.y > end.y || !isTop && start.y < end.y {
            if isLeft && start.x < end.x || !isLeft && start.x > end.x {
                return (CGPoint(x: start.x + deltaX, y: start.y - deltaY), end)
            } else {
                return (CGPoint(x: start.x, y: start.y - deltaY), CGPoint(x: end.x + deltaX, y: end.y))
            }
        } else {
            if isLeft && start.x < end.x || !isLeft && start.x > end.x {
                return (CGPoint(x: start.x + deltaX, y: start.y), CGPoint(x: end.x, y: end.y - deltaY))
            } else {
                return (start, CGPoint(x: end.x + deltaX, y: end.y - deltaY))
            }
        }
    }

    func draw(_ context: CGContext) {
        context.addRects([
            CGRect(
                    x: point.x + handleWidth * (isLeft ? -1 : 1),
                    y: point.y - (isTop ? 0 : handleWidth),
                    width: handleLength * (isLeft ? 1 : -1),
                    height: handleWidth
            ),
            CGRect(
                    x: point.x - (isLeft ? handleWidth : 0),
                    y: point.y + handleWidth * (isTop ? 1 : -1),
                    width: handleWidth,
                    height: handleLength * (isTop ? -1 : 1)
            )
        ])
        context.setFillColor(yellow)
        context.drawPath(using: .fill)
    }

    var point: CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .topRight:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottomLeft:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .bottomRight:
            return CGPoint(x: rect.maxX, y: rect.minY)
        }
    }

    var cursor = NSCursor.pointingHand

    private var isTop: Bool {
        corner == .topLeft || corner == .topRight
    }

    private var isLeft: Bool {
        corner == .topLeft || corner == .bottomLeft
    }
}

enum Corner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

class SideHandle: Handle {
    let side: Side
    var rect = CGRect.zero

    init(_ side: Side) {
        self.side = side
    }

    func update(start: CGPoint, end: CGPoint, deltaX: CGFloat, deltaY: CGFloat) -> (CGPoint, CGPoint) {
        if isVertical {
            if side == .left && start.x < end.x || side == .right && start.x > end.x {
                return (CGPoint(x: start.x + deltaX, y: start.y), end)
            } else {
                return (start, CGPoint(x: end.x + deltaX, y: end.y))
            }
        } else {
            if side == .top && start.y > end.y || side == .bottom && start.y < end.y {
                return (CGPoint(x: start.x, y: start.y - deltaY), end)
            } else {
                return (start, CGPoint(x: end.x, y: end.y - deltaY))
            }
        }
    }

    func draw(_ context: CGContext) {
        if isVertical {
            context.addRect(CGRect(
                    x: point.x - (side == .left ? 0 : handleWidth),
                    y: point.y - handleLength / 2,
                    width: handleWidth,
                    height: handleLength
            ))
        } else {
            context.addRect(CGRect(
                    x: point.x - handleLength / 2,
                    y: point.y - (side == .bottom ? 0 : handleWidth),
                    width: handleLength,
                    height: handleWidth
            ))
        }
        context.setFillColor(yellow)
        context.drawPath(using: .fill)
    }

    var point: CGPoint {
        switch side {
        case .top:
            return CGPoint(x: rect.midX, y: rect.maxY)
        case .right:
            return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottom:
            return CGPoint(x: rect.midX, y: rect.minY)
        case .left:
            return CGPoint(x: rect.minX, y: rect.midY)
        }
    }

    var cursor: NSCursor {
        if isVertical {
            return NSCursor.resizeUpDown
        } else {
            return NSCursor.resizeLeftRight
        }
    }

    private var isVertical: Bool {
        side == .left || side == .right
    }
}

enum Side {
    case top
    case right
    case bottom
    case left
}

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
    var handle: Handle?

    var handles: [Handle] = [
        CornerHandle(.topLeft),
        SideHandle(.top),
        CornerHandle(.topRight),
        SideHandle(.right),
        CornerHandle(.bottomLeft),
        SideHandle(.bottom),
        CornerHandle(.bottomRight),
        SideHandle(.left)
    ]

    var rect: CGRect {
        CGRect(
                x: start.x,
                y: start.y,
                width: end.x - start.x,
                height: end.y - start.y
        )
    }

    func constrainToVideoViewport(_ point: CGPoint) -> CGPoint {
        let aspectRatio = videoSize.width / videoSize.height
        let actualHeight = bounds.height
        let actualWidth = aspectRatio * actualHeight

        let minX = bounds.midX - actualWidth / 2
        let maxX = bounds.midX + actualWidth / 2
        let minY = 0.0
        let maxY = frame.maxY

        let x = min(max(minX, point.x), maxX)
        let y = min(max(minY, point.y), maxY)
        return CGPoint(x: x, y: y)
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
        print("moved!")
        let mouseLocation = convert(event.locationInWindow, from: nil)

        for candidateHandle in handles {
            if testGrab(pointA: mouseLocation, pointB: candidateHandle.point) {
                candidateHandle.cursor.set()
                return
            }
        }

        NSCursor.arrow.set()
    }

    private func testGrab(pointA: CGPoint, pointB: CGPoint) -> Bool {
        pow(pointA.x - pointB.x, 2) + pow(pointA.y - pointB.y, 2) < pow(handleLength, 2)
    }
}
