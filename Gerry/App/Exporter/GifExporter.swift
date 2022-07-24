//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AVFoundation

class GifExporter: Exporter {
    func export(videoAt url: URL, toFolder folder: URL, withName name: String, croppingTo rect: CGRect, startingAt: CGFloat, endingAt: CGFloat) async -> URL {
        print("Exporting gif to", folder.path, name)
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)

        let frameRate: Int = 30
        let duration: TimeInterval = asset.duration.seconds
        print("Duration:", duration)
        let totalFrames = Int(duration * TimeInterval(frameRate))
        let delayBetweenFrames: TimeInterval = 1.0 / TimeInterval(frameRate)

        var timeValues: [NSValue] = []

        for frameNumber in 0 ..< totalFrames {
            let seconds = TimeInterval(delayBetweenFrames) * TimeInterval(frameNumber)
            let time = CMTime(seconds: seconds, preferredTimescale: Int32(NSEC_PER_SEC))
            timeValues.append(NSValue(time: time))
        }

        let scale = 1.0
        let size = asset.tracks[0].naturalSize;
        let scaledRect = CGRect(x: rect.minX * scale, y: size.height * scale - rect.minY * scale, width: rect.width * scale, height: -rect.height * scale)
        generator.maximumSize = CGSize(width: size.width * scale, height: size.height * scale)

        // Set up resulting image
        let fileProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]

        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime: delayBetweenFrames
            ]
        ]

        let resultingFilename = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "html5gif.gif")
        let resultingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(resultingFilename)
        let destination = CGImageDestinationCreateWithURL(resultingFileURL as CFURL, kUTTypeGIF, totalFrames, nil)!
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        print("Converting to GIF…")
        var framesProcessed = 0
        let startTime = CFAbsoluteTimeGetCurrent()

        return await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: timeValues) { (requestedTime, resultingImage, actualTime, result, error) in
                framesProcessed += 1

                guard let resultingImage = resultingImage else { print("Frame", framesProcessed, "/", totalFrames, "failed"); return }

                print("Processed frame", framesProcessed, "/", totalFrames);

                CGImageDestinationAddImage(destination, resultingImage.cropping(to: scaledRect)!, frameProperties as CFDictionary)

                if framesProcessed == totalFrames {
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    print("Done converting to GIF! Frames processed: \(framesProcessed) • Total time: \(timeElapsed) s.")

                    // Save to Photos just to check…
                    let result = CGImageDestinationFinalize(destination)
                    print("Did it succeed?", result)

                    if result {
                        print("Saving...")
                        let outputURL = URL(string: "idk.gif")!//url.deletingPathExtension().appendingPathExtension("gif");
//                        try! FileManager.default.removeItem(at: outputURL);
//                        try! FileManager.default.copyItem(at: resultingFileURL, to: outputURL);
                        continuation.resume(returning: outputURL)
                    }
                }
            }
        }
    }

}
