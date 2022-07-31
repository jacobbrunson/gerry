//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI
import AppKit
import AVKit

struct PlayerCropperView: NSViewControllerRepresentable {
    let viewModel: SaveWindowContentView.ViewModel

    func makeNSViewController(context: Context) -> PlayerCropperViewController {
        let viewController = PlayerCropperViewController()
        viewController.player = viewModel.player
        viewController.cropRect = viewModel.cropRect
        viewController.onSelect = { [weak viewModel, weak viewController] rawRect in
            guard let currentItem = viewModel?.player.currentItem else { return }
            guard viewController != nil else { return }

            let videoViewport = viewController!.videoViewport

            let naturalSize = currentItem.asset.tracks[0].naturalSize
            let scale = naturalSize.width / videoViewport.width

            let x1 = (rawRect.minX - videoViewport.minX) * scale
            let x2 = (rawRect.maxX - videoViewport.minX) * scale
            let y1 = (rawRect.minY - videoViewport.minY) * scale
            let y2 = (rawRect.maxY - videoViewport.minY) * scale

            let minX = min(x1, x2)
            let maxX = max(x1, x2)
            let minY = min(y1, y2)
            let maxY = max(y1, y2)

            viewModel!.cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        return viewController
    }

    func updateNSViewController(_ viewController: PlayerCropperViewController, context: Context) {
        viewController.player = viewModel.player
        viewController.cropRect = viewModel.cropRect
    }
}

class PlayerCropperViewController: NSViewController {
    var player = AVPlayer()
    var onSelect: ((CGRect) -> ())?
    var cropRect: CGRect?

    let playerView = AVPlayerView()
    let cropperView = CropperView()

    override func loadView() {
        playerView.controlsStyle = .none
        playerView.player = player

        cropperView.onSelect = onSelect

        view = NSView()
        view.subviews = [playerView, cropperView]
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        onSelect?(videoViewport)
    }

    override func viewWillLayout() {
        super.viewWillLayout()
        playerView.frame = videoViewport
        cropperView.frame = view.bounds
        cropperView.videoViewport = videoViewport
        cropperView.addTrackingArea(NSTrackingArea(rect: view.bounds, options: [.activeAlways, .mouseMoved], owner: cropperView, userInfo: nil))
        if cropRect != nil {
            let naturalSize = player.currentItem!.asset.tracks[0].naturalSize
            let scale = videoViewport.width / naturalSize.width
            cropperView.start = CGPoint(x: videoViewport.minX + cropRect!.minX * scale, y: videoViewport.minY + cropRect!.minY * scale)
            cropperView.end = CGPoint(x: videoViewport.minX + cropRect!.maxX * scale, y: videoViewport.minY + cropRect!.maxY * scale)
        }
    }

    var videoViewport: CGRect {
        let videoSize = player.currentItem!.asset.tracks[0].naturalSize
        let aspectRatio = videoSize.width / videoSize.height
        let actualHeight = view.bounds.height
        let actualWidth = aspectRatio * actualHeight

        let minX = view.bounds.midX - actualWidth / 2
        let maxX = view.bounds.midX + actualWidth / 2
        let minY = 0.0
        let maxY = view.bounds.maxY

        return CGRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
        )
    }
}

let lineWidth = 2.0
let handleWidth = lineWidth * 2
let handleLength = lineWidth * 9

class CropperView: NSView {
    var onSelect: ((CGRect) -> ())?

    var start = CGPoint.zero
    var end = CGPoint.zero

    private var _videoViewport = CGRect.zero
    var videoViewport: CGRect {
        get { _videoViewport }
        set {
            _videoViewport = newValue
            start = constrainToVideoViewport(CGPoint.zero)
            end = constrainToVideoViewport(CGPoint(x: CGFloat.infinity, y: CGFloat.infinity))
        }
    }

    var isDragging = false
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
        constrain(point, to: videoViewport)
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
                    x: videoViewport.minX,
                    y: displayRect.maxY,
                    width: videoViewport.width,
                    height: videoViewport.height - displayRect.maxY
            ),
            CGRect(
                    x: displayRect.maxX,
                    y: videoViewport.minY,
                    width: videoViewport.maxX - displayRect.maxX,
                    height: videoViewport.height
            ),
            CGRect(
                    x: videoViewport.minX,
                    y: videoViewport.minY,
                    width: videoViewport.width,
                    height: displayRect.minY
            ),
            CGRect(
                    x: videoViewport.minX,
                    y: videoViewport.minY,
                    width:  displayRect.minX - videoViewport.minX,
                    height: videoViewport.height
            ),
        ])
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        context.drawPath(using: .fill)

        context.addRect(displayRect)
        context.setStrokeColor(NSColor(named: "Yellow")!.cgColor)
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
                //addTrackingArea(NSTrackingArea(rect: candidateHandle.rect, owner: self))
                isDragging = true
                break
            }
        }

        if handle == nil {
            let constrainedLocation = constrainToVideoViewport(mouseLocation)

            // Clicked really far outside video viewport? Don't even register.
            if pow(constrainedLocation.x - mouseLocation.x, 2) + pow(constrainedLocation.y - mouseLocation.y, 2) > 500 {
                return
            }

            isDragging = true
            start = constrainedLocation
            end = constrainedLocation
        }

        setNeedsDisplay(bounds)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        onSelect?(rect)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }

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
