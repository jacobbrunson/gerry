//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AVFoundation

class Mp4Exporter: Exporter {
    func getUrl(forOutputFolder outputFolder: URL, withFileName fileName: String) -> URL {
        outputFolder.appendingPathComponent(fileName).appendingPathExtension("mp4")
    }

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
        print("Exporting mp4 to", outputFolder.path, fileName)

        let asset = AVURLAsset(url: url)
        let clipVideoTrack = asset.tracks.first!
        let assetDuration = clipVideoTrack.timeRange.duration

        let size = asset.tracks[0].naturalSize;
        let rect = maybeRect ?? CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let scaledRect = CGRect(x: rect.minX * scale, y: size.height * scale - rect.minY * scale, width: rect.width * scale, height: rect.height * scale)

        var videoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: Int32(desiredFrameRate))
        videoComposition.renderSize = CGSize(width: scaledRect.width, height: scaledRect.height)

        var instruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = clipVideoTrack.timeRange

        var transformer: AVMutableVideoCompositionLayerInstruction =
                AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)

        var transform: CGAffineTransform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: -rect.minX, y: rect.maxY - size.height)

        transformer.setTransform(transform, at: .zero)

        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        try? FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        let outputURL = getUrl(forOutputFolder: outputFolder, withFileName: fileName)

        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.videoComposition = videoComposition
        exportSession.timeRange = CMTimeRange(
                start: CMTime(seconds: assetDuration.seconds * startT, preferredTimescale: Int32(NSEC_PER_SEC)),
                end: CMTime(seconds: assetDuration.seconds * endT, preferredTimescale: Int32(NSEC_PER_SEC))
        )
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            onProgress(CGFloat(exportSession.progress))
        }

        return await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                print("done exporting mp4!")
                timer.invalidate()
                onProgress(1)
                continuation.resume(returning: outputURL)
            }
        }

    }

}
