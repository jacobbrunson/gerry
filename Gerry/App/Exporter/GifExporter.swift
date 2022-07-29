//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AVFoundation

class GifExporter: Exporter {
    func export(
            videoAt url: URL,
            toFolder outputFolder: URL,
            withName fileName: String,
            croppingTo maybeRect: CGRect?,
            startingAt startT: CGFloat,
            endingAt endT: CGFloat,
            withScale scale: CGFloat,
            withFrameRate desiredFrameRate: CGFloat,
            onProgress: @escaping (CGFloat) -> ()
    ) async -> URL {
        print("Exporting gif to", outputFolder.path, fileName)

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)


        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.appliesPreferredTrackTransform = true


        let totalDuration = asset.duration.seconds
        let frameRate = min(desiredFrameRate, 30)
        let totalFrames = Int(totalDuration * TimeInterval(frameRate))

        let duration = totalDuration * (endT - startT)


        var timeValues: [NSValue] = []

        let startFrame = Int(CGFloat(totalFrames)*startT)
        let endFrame = Int(CGFloat(totalFrames)*endT)
        let frameCount = endFrame - startFrame
        let delayBetweenFrames: TimeInterval = 1.0 / TimeInterval(frameRate)

        for frameNumber in startFrame ..< endFrame {
            let seconds = TimeInterval(delayBetweenFrames) * TimeInterval(frameNumber)
            let time = CMTime(seconds: seconds, preferredTimescale: Int32(NSEC_PER_SEC))
            timeValues.append(NSValue(time: time))
        }

        let size = asset.tracks[0].naturalSize;
        let rect = maybeRect ?? CGRect(x: 0, y: 0, width: size.width, height: size.height)
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

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString).appendingPathExtension("gif")
        let imageDestination = CGImageDestinationCreateWithURL(tempURL as CFURL, kUTTypeGIF, totalFrames, nil)!
        CGImageDestinationSetProperties(imageDestination, fileProperties as CFDictionary)

        print("Converting to gif...")
        var framesProcessed = 0
        let startTime = CFAbsoluteTimeGetCurrent()

        var actualProgress = 0.0
        var desiredProgress = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            desiredProgress = framesProcessed == frameCount ? desiredProgress + (1 - desiredProgress) * 0.01 : CGFloat(framesProcessed) / CGFloat(frameCount) * 0.5
            actualProgress += (desiredProgress - actualProgress) * 0.01
            onProgress(actualProgress)
        }

        return try! await withCheckedThrowingContinuation { continuation in
            var prevFrame: CGImage?
            generator.generateCGImagesAsynchronously(forTimes: timeValues) { (requestedTime, resultingImage, actualTime, result, error) in
                framesProcessed += 1

                if resultingImage == nil {
                    print("Frame", framesProcessed, "/", frameCount, "failed")
                    print(requestedTime.seconds, actualTime.seconds, result.rawValue, error)
                    if prevFrame != nil {
                        CGImageDestinationAddImage(imageDestination, prevFrame!.cropping(to: scaledRect)!, frameProperties as CFDictionary)
                    }
                } else {
                    print("Processed frame \(framesProcessed)/\(frameCount) (\(startFrame)-\(endFrame), \(totalFrames) total)")
                    print(requestedTime.seconds, actualTime.seconds, result.rawValue, error)
                    CGImageDestinationAddImage(imageDestination, resultingImage!.cropping(to: scaledRect)!, frameProperties as CFDictionary)
                    prevFrame = resultingImage
                }

                if framesProcessed == frameCount {
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    print("Done converting to gif. Processed: \(framesProcessed) in \(timeElapsed) s")
                    print("Finalizing...")

                    let result = CGImageDestinationFinalize(imageDestination)

                    timer.invalidate()
                    onProgress(1)

                    let outputURL = outputFolder.appendingPathComponent(fileName).appendingPathExtension("gif")


                    let usingSecurityScope = outputFolder.startAccessingSecurityScopedResource()

                    try? FileManager.default.removeItem(at: outputURL);
                    try! FileManager.default.moveItem(at: tempURL, to: outputURL)

                    if usingSecurityScope {
                        outputFolder.stopAccessingSecurityScopedResource()
                    }

                    if result {
                        print("in a weird part of the night")
                        continuation.resume(returning: outputURL)
                    } else {
                        print("Gif export failed")
                        continuation.resume(throwing: ExportError.failed)
                    }
                }
            }
        }
    }

}
