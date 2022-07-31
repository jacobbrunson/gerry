//
// Created by Jacob Brunson on 7/18/22.
//

import Foundation
import SwiftUI
import AppKit
import AVFoundation

struct TrimmerView: NSViewControllerRepresentable {
    @ObservedObject var viewModel: SaveWindowContentView.ViewModel

    let onUpdate: (CGFloat, TrimmerHandlePosition) -> ()

    init(viewModel: SaveWindowContentView.ViewModel, onUpdate: @escaping (CGFloat, TrimmerHandlePosition) -> ()) {
        self.viewModel = viewModel
        self.onUpdate = onUpdate
    }

    func makeNSViewController(context: Context) -> TrimmerViewController {
        let viewController = TrimmerViewController()
        viewController.mediaURL = viewModel.assetURL
        viewController.cropRect = viewModel.cropRect
        viewController.player = viewModel.player
        viewController.onUpdate = onUpdate
        return viewController
    }

    func updateNSViewController(_ nsViewController: TrimmerViewController, context: Context) {
        nsViewController.update(cropRect: viewModel.cropRect)
    }
}

class TrimmerViewController: NSViewController {
    let leftHandleView = TrimmerHandleView()
    let rightHandleView = TrimmerHandleView()
    let timelineView = TimelineView()
    let playheadView = PlayheadView()
    var mediaURL = URL(string: "/")!
    var onUpdate: ((CGFloat, TrimmerHandlePosition) -> ())?
    var asset: AVAsset?
    var thumbnailController: ThumbnailController?
    var hasRequestedThumbnails = false
    var cropRect: CGRect?
    var player: AVPlayer?

    var timeObserverToken: Any?

    func update(cropRect: CGRect?) {
        if self.cropRect != cropRect {
            self.cropRect = cropRect
            thumbnailController!.requestThumbnails(frameSize: timelineView.frame.size, cropRect: cropRect, shouldDebounce: true)
        }
    }

    override func loadView() {
        playheadView.player = player
        timeObserverToken = player?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 1.0/60.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                queue: .main) { [weak self] time in
                    guard let playheadView = self?.playheadView else { return }
                    guard let leftHandleView = self?.leftHandleView else { return }
                    guard let rightHandleView = self?.rightHandleView else { return }
                    guard let timelineView = self?.timelineView else { return }
                    guard let player = self?.player else { return }

                    let duration = player.currentItem!.duration.seconds
                    let startTime = leftHandleView.t * duration
                    let endTime = rightHandleView.t * duration
                    let currentTime = player.currentTime().seconds

                    if currentTime >= endTime {
                        player.seek(
                                to: CMTime(seconds: startTime, preferredTimescale: 1000),
                                toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero
                        )
                    }
                    player.play()

                    playheadView.setNeedsDisplay(timelineView.frame)
                }

        leftHandleView.t = 0
        leftHandleView.position = .left
        leftHandleView.onUpdate = { [weak self] t in
            guard let rightHandleView = self?.rightHandleView else { return }
            let offset = TrimmerHandleView.width * 2 / rightHandleView.superview!.frame.width
            if t > rightHandleView.t - offset {
                rightHandleView.t = t + offset
            }
            self?.onUpdate?(t, .left)
        }

        rightHandleView.t = 1
        rightHandleView.position = .right
        rightHandleView.onUpdate = { [weak self] t in
            guard let leftHandleView = self?.leftHandleView else { return }
            let offset = TrimmerHandleView.width * 2 / leftHandleView.superview!.frame.width
            if t < leftHandleView.t + offset {
                leftHandleView.t = t - offset
            }
            self?.onUpdate?(t, .right)
        }

        timelineView.leftHandleView = leftHandleView
        timelineView.rightHandleView = rightHandleView
        timelineView.playheadView = playheadView
        timelineView.subviews = [leftHandleView, rightHandleView, playheadView]

        asset = AVAsset(url: mediaURL)
        thumbnailController = ThumbnailController(
                asset: asset!,
                onThumbReady: nil,
                onComplete: { [weak self] thumbs in
                    guard let timelineView = self?.timelineView else { return }
                    timelineView.thumbs = thumbs
                    timelineView.setNeedsDisplay(timelineView.frame)
                }
        )

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




