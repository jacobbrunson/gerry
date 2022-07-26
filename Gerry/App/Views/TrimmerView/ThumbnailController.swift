//
// Created by Jacob Brunson on 7/25/22.
//

import Foundation
import AVFoundation

class ThumbnailController {
    var isGenerating = false
    var thumbs: [CGImage] { isGenerating ? prevThumbs: currentThumbs }

    private let asset: AVAsset
    private let onThumbReady: ((CGImage, CGRect) -> ())?
    private let onComplete: (() -> ())?

    private var prevThumbs: [CGImage] = []
    private var currentThumbs: [CGImage] = []
    private var generator: AVAssetImageGenerator
    private var generationTimer: Timer?

    init(asset: AVAsset, onThumbReady: ((CGImage, CGRect) -> ())?, onComplete: (() -> ())?) {
        self.asset = asset
        self.onThumbReady = onThumbReady
        self.onComplete = onComplete
        generator = AVAssetImageGenerator(asset: asset)
    }

    func requestThumbnails(frameSize: CGSize, shouldDebounce: Bool) {
        print("requesting thumb generation")

        generationTimer?.invalidate()
        generator.cancelAllCGImageGeneration()

        if shouldDebounce {
            // Somehow, using an interval of 0 achieves the desired effect of "generation doesn't begin until the user
            // stops resizing the browser and lets go of the left mouse button."
            // It seems like the timer doesn't execute while a window UI interaction is occurring?
            // TODO: figure out how the hell swift and appkit works
            generationTimer = Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
                self.generate(frameSize: frameSize)
            }
        } else {
            generate(frameSize: frameSize)
        }
    }

    private func generate(frameSize: CGSize) {
        print("beginning thumb generation")

        prevThumbs = currentThumbs
        if isGenerating && !currentThumbs.isEmpty {
            currentThumbs = [thumbs.first!]
        } else {
            currentThumbs = []
            isGenerating = true
        }

        let videoSize = asset.tracks[0].naturalSize
        let thumbSize = CGSize(
                width: videoSize.width / videoSize.height * frameSize.height,
                height: frameSize.height
        )
        generator.maximumSize = thumbSize

        let tolerance = CMTime(seconds: 0.1, preferredTimescale: 10000)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let thumbCount = Int(ceil(frameSize.width / thumbSize.width))
        let times = getTimeValues(count: thumbCount, duration: asset.duration, needsFirstFrame: currentThumbs.isEmpty)

        var i = 0
        var prevImage: CGImage?

        generator.generateCGImagesAsynchronously(forTimes: times) { _, image, _, result, _ in
            if result == .cancelled {
                return
            }

            if image != nil {
                self.currentThumbs.append(image!)
                prevImage = image
            } else if prevImage != nil {
                self.currentThumbs.append(prevImage!)
            }

            i += 1
            if i == thumbCount {
                self.isGenerating = false
                DispatchQueue.main.async {
                    self.onComplete?()
                }
            }
        }
    }

    private func getTimeValues(count: Int, duration: CMTime, needsFirstFrame: Bool) -> [NSValue] {
        let frameDuration = duration.seconds / Double(count)
        var timeValues: [NSValue] = []
        let startIndex = needsFirstFrame ? 0 : 1

        for frameNumber in startIndex ..< count {
            let seconds = TimeInterval(frameDuration) * TimeInterval(frameNumber)
            let time = CMTime(seconds: seconds, preferredTimescale: Int32(NSEC_PER_SEC))
            timeValues.append(NSValue(time: time))
        }

        return timeValues
    }
}
