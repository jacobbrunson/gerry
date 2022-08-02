//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import ScreenCaptureKit
import AVFoundation

class ScreenCaptureController: NSObject, SCStreamDelegate, SCStreamOutput {

    private var stream: SCStream?
    private let sampleHandlerQueue = DispatchQueue(label: "me.brunson.Gerry.SampleHandlerQueue")
    private var scale: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }

    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var hasSession = false

    func beginRecording() async {
        let content = try! await SCShareableContent.excludingDesktopWindows(false,
                onScreenWindowsOnly: false)
        let display = content.displays.first!
        let filter = getFilter(display: display, availableApps: content.applications)
        let configuration = getConfiguration(display)

        beginWriting(width: display.width * scale, height: display.height * scale)

        stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try! stream!.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleHandlerQueue)
        try! await stream!.startCapture()
    }

    func stopRecording() async -> URL {
        try! await stream!.stopCapture()
        await writer!.finishWriting()
        hasSession = false
        return writer!.outputURL
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard
                sampleBuffer.isValid,
                outputType == .screen
        else { return }

        if !hasSession {
            writer!.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }

        if input!.isReadyForMoreMediaData {
            input!.append(sampleBuffer)
        } else {
            print("Skipping frame because input is not ready")
        }
    }

    private func beginWriting(width: Int, height: Int) {
        let directory = FileManager.default.temporaryDirectory
        let fileName = NSUUID().uuidString
        let outputURL = directory.appendingPathComponent(fileName).appendingPathExtension("mp4")

        writer = try! AVAssetWriter(outputURL: outputURL, fileType: .mp4);
        let outputSettings = [AVVideoCodecKey: AVVideoCodecType.h264,
                              AVVideoWidthKey: NSNumber(value: width),
                              AVVideoHeightKey: NSNumber(value: height)] as [String : Any]
        input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)

        writer!.add(input!);
        writer!.startWriting()
    }

    public func getDisplay() async -> SCDisplay {
        let content = try! await SCShareableContent.excludingDesktopWindows(false,
                onScreenWindowsOnly: false)
        return content.displays[0];
    }

    private func getFilter(display: SCDisplay, availableApps: [SCRunningApplication]) -> SCContentFilter {
        let excludedApps = availableApps.filter { app in
            Bundle.main.bundleIdentifier == app.bundleIdentifier
        }
        return SCContentFilter(display: display,
                excludingApplications: excludedApps,
                exceptingWindows: [])
    }

    private func getConfiguration(_ display: SCDisplay) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        config.width = display.width * scale
        config.height = display.height * scale
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        config.queueDepth = 6
        return config
    }

    private func getDimensions(from sampleBuffer: CMSampleBuffer) -> (CGFloat, CGFloat) {
        guard let attachmentses = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentses.first, let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary)
        else {
            return (0, 0)
        }

        return (contentRect.width, contentRect.height)
    }
}
