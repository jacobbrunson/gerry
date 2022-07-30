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
    var cropRect: Binding<CGRect?>
    let onUpdate: (CGFloat, TrimmerHandlePosition) -> ()

    init(mediaURL: URL, currentTime: CMTime, cropRect: Binding<CGRect?>, onUpdate: @escaping (CGFloat, TrimmerHandlePosition) -> ()) {
        self.mediaURL = mediaURL
        self.currentTime = currentTime
        self.cropRect = cropRect
        self.onUpdate = onUpdate
    }

    func makeNSViewController(context: Context) -> TrimmerViewController {
        let viewController = TrimmerViewController()
        viewController.mediaURL = mediaURL
        viewController.cropRect = cropRect.wrappedValue
        viewController.onUpdate = onUpdate
        viewController.delegate = context.coordinator
        return viewController
    }

    func makeCoordinator() -> TrimmerViewCoordinator {
        TrimmerViewCoordinator()
    }

    func updateNSViewController(_ nsViewController: TrimmerViewController, context: Context) {
        nsViewController.update(currentTime: currentTime, cropRect: cropRect.wrappedValue)
    }
}

class TrimmerViewCoordinator: NSObject {
    func doTheThing() {

    }
}

class TrimmerViewController: NSViewController {
    let leftHandleView = TrimmerHandleView()
    let rightHandleView = TrimmerHandleView()
    let timelineView = TimelineView()
    let playheadView = PlayheadView()
    var mediaURL = URL(string: "/")!
    var onUpdate: ((CGFloat, TrimmerHandlePosition) -> ())?
    var delegate: TrimmerViewCoordinator?
    var asset: AVAsset?
    var thumbnailController: ThumbnailController?
    var hasRequestedThumbnails = false
    var cropRect: CGRect?

    func update(currentTime: CMTime, cropRect: CGRect?) {
        playheadView.update(t: min(1, currentTime.seconds / asset!.duration.seconds))
        if self.cropRect != cropRect {
            self.cropRect = cropRect
            thumbnailController!.requestThumbnails(frameSize: timelineView.frame.size, cropRect: cropRect, shouldDebounce: true)
        }
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
        thumbnailController = ThumbnailController(asset: asset!, onThumbReady: nil, onComplete: {
            print("thumbs complete", self.thumbnailController?.thumbs.count)
            self.timelineView.thumbs = self.thumbnailController!.thumbs
            self.timelineView.setNeedsDisplay(self.timelineView.frame)
        })

        view = timelineView
    }

    override func viewWillAppear() {
        super.viewWillAppear()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        timelineView.thumbs = timelineView.thumbs.isEmpty ? [] : [timelineView.thumbs.first!]
        timelineView.setNeedsDisplay(timelineView.frame)

        thumbnailController!.requestThumbnails(
                frameSize: timelineView.frame.size,
                cropRect: cropRect,
                shouldDebounce: hasRequestedThumbnails
        )
        hasRequestedThumbnails = true
    }
}




