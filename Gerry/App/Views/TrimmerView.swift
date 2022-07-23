//
// Created by Jacob Brunson on 7/18/22.
//

import Foundation
import SwiftUI
import AppKit
import AVFoundation

struct TrimmerView: NSViewControllerRepresentable {
    let mediaURL: URL
    let currentTime: CMTime
    let onUpdate: (CGFloat, HandlePosition) -> ()

    init(mediaURL: URL, currentTime: CMTime, onUpdate: @escaping (CGFloat, HandlePosition) -> ()) {
        self.mediaURL = mediaURL
        self.currentTime = currentTime
        self.onUpdate = onUpdate
    }

    func makeNSViewController(context: Context) -> TrimmerViewController {
        let viewController = TrimmerViewController()
        viewController.mediaURL = mediaURL
        viewController.onUpdate = onUpdate
        viewController.delegate = context.coordinator
        return viewController
    }

    func makeCoordinator() -> TrimmerViewCoordinator {
        TrimmerViewCoordinator()
    }

    func updateNSViewController(_ nsViewController: TrimmerViewController, context: Context) {
        nsViewController.update(currentTime: currentTime)
    }
}

class TrimmerViewCoordinator: NSObject {
    func doTheThing() {

    }
}

class TrimmerViewController: NSViewController {
    let leftHandleView = HandleView()
    let rightHandleView = HandleView()
    let timelineView = TimelineView()
    let playheadView = PlayheadView()
    var mediaURL = URL(string: "/")!
    var onUpdate: ((CGFloat, HandlePosition) -> ())?
    var delegate: TrimmerViewCoordinator?
    var asset: AVAsset?

    func update(currentTime: CMTime) {
        playheadView.update(t: min(1, currentTime.seconds / asset!.duration.seconds))
    }

    override func loadView() {
        leftHandleView.t = 0
        leftHandleView.position = .left
        leftHandleView.onUpdate = { t in
            self.leftHandleView.t = t
            let offset = self.leftHandleView.widthT*2
            if t > self.rightHandleView.t - offset {
                self.rightHandleView.t = t + offset
            }
            self.onUpdate!(t, .left)
        }

        rightHandleView.t = 1
        rightHandleView.position = .right
        rightHandleView.onUpdate = { t in
            self.rightHandleView.t = t
            let offset = self.rightHandleView.widthT * 2
            if t < self.leftHandleView.t + offset {
                self.leftHandleView.t = t - offset
            }
            self.onUpdate!(t, .right)
        }

        timelineView.leftHandleView = leftHandleView
        timelineView.rightHandleView = rightHandleView
        timelineView.subviews = [leftHandleView, rightHandleView, playheadView]

        asset = AVAsset(url: mediaURL)

        Task {
            print("Generating thumbs")
            var i = 0
            for await thumb in generateThumbs(asset: asset!) {
                timelineView.thumbs[i] = thumb
                timelineView.setNeedsDisplay(timelineView.frame)
                i += 1
            }
        }

        view = timelineView
    }

    private func generateThumbs(asset: AVAsset) -> AsyncStream<CGImage> {
        let videoSize = asset.tracks[0].naturalSize
        let height = timelineView.frame.height
        let width = videoSize.width / videoSize.height * height

        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: width, height: height)

        let thumbCount = Int(ceil(timelineView.frame.width / width))
        let times = getTimeValues(count: thumbCount, duration: asset.duration)

        var i = 0
        var prevImage: CGImage?
        return AsyncStream { continuation in
            generator.generateCGImagesAsynchronously(forTimes: times) { _, image, _, _, _ in
                i += 1
                if image != nil {
                    continuation.yield(image!)
                    prevImage = image
                } else if prevImage != nil {
                    continuation.yield(prevImage!)
                }

                if i == thumbCount {
                    continuation.finish()
                }
            }
        }
    }

    private func getTimeValues(count: Int, duration: CMTime) -> [NSValue] {
        let frameDuration = duration.seconds / Double(count)
        var timeValues: [NSValue] = []

        for frameNumber in 0 ..< count {
            let seconds = TimeInterval(frameDuration) * TimeInterval(frameNumber)
            let time = CMTime(seconds: seconds, preferredTimescale: Int32(NSEC_PER_SEC))
            timeValues.append(NSValue(time: time))
        }

        return timeValues
    }

    override func viewWillAppear() {
        super.viewWillAppear()
    }
}

class TimelineView: NSView {
    var leftHandleView: HandleView?
    var rightHandleView: HandleView?
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

enum HandlePosition {
    case left
    case right
}

class HandleView: NSView {
    let width: CGFloat = 12

    var position: HandlePosition = .left
    var t: CGFloat = 0
    var onUpdate: (CGFloat) -> () = { _ in }

    var widthT: CGFloat {
        superview == nil ? 0 : width / superview!.frame.width
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        let x = t * superview!.frame.width + (position == .right ? -width : 0)
        frame = CGRect(x: x, y: 0, width: width, height: superview!.frame.height)

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

        let t = min(max(lowerBound, t + deltaT), upperBound)
        onUpdate(t)
        superview!.setNeedsDisplay(superview!.frame)
    }
}

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
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.drawPath(using: .fill)
        context.restoreGState()
    }
}