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
    let onUpdate: (CGFloat, TrimmerHandlePosition) -> ()

    init(mediaURL: URL, currentTime: CMTime, onUpdate: @escaping (CGFloat, TrimmerHandlePosition) -> ()) {
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
    let leftHandleView = TrimmerHandleView()
    let rightHandleView = TrimmerHandleView()
    let timelineView = TimelineView()
    let playheadView = PlayheadView()
    var mediaURL = URL(string: "/")!
    var onUpdate: ((CGFloat, TrimmerHandlePosition) -> ())?
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




