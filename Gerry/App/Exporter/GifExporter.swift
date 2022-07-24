//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AVFoundation

class GifExporter: Exporter {
    func export(videoAt url: URL, toFolder outputFolder: URL, withName fileName: String, croppingTo maybeRect: CGRect?, startingAt startT: CGFloat, endingAt endT: CGFloat, withScale scale: CGFloat, withFPS frameRate: CGFloat) async -> URL {
        print("Exporting gif to", outputFolder.path, fileName)
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)

        let duration: TimeInterval = asset.duration.seconds * (endT - startT)
        print("Duration:", duration)
        let totalFrames = Int(duration * TimeInterval(frameRate))
        let delayBetweenFrames: TimeInterval = 1.0 / TimeInterval(frameRate)

        var timeValues: [NSValue] = []

        for frameNumber in 0 ..< totalFrames {
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

        return try! await withCheckedThrowingContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: timeValues) { (requestedTime, resultingImage, actualTime, result, error) in
                framesProcessed += 1

                guard let resultingImage = resultingImage else { print("Frame", framesProcessed, "/", totalFrames, "failed"); return }

                print("Processed frame", framesProcessed, "/", totalFrames);

                CGImageDestinationAddImage(imageDestination, resultingImage.cropping(to: scaledRect)!, frameProperties as CFDictionary)

                if framesProcessed == totalFrames {
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    print("Done converting to gif. Processed: \(framesProcessed) in \(timeElapsed) s")
                    print("Finalizing...")

                    let result = CGImageDestinationFinalize(imageDestination)

                    let outputURL = outputFolder.appendingPathComponent(fileName).appendingPathExtension("gif")


                    let usingSecurityScope = outputFolder.startAccessingSecurityScopedResource()

                    try? FileManager.default.removeItem(at: outputURL);
                    try! FileManager.default.moveItem(at: tempURL, to: outputURL)

                    if usingSecurityScope {
                        outputFolder.stopAccessingSecurityScopedResource()
                    }

                    if result {
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
