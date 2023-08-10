//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import ScreenCaptureKit
import AVFoundation
import SwiftUI

class ScreenCaptureController: NSObject, SCStreamDelegate, SCStreamOutput {

    private var stream: SCStream?
    private let sampleHandlerQueue = DispatchQueue(label: "me.brunson.Gerry.SampleHandlerQueue")
    private var scale: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }

    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var adapter: AVAssetWriterInputPixelBufferAdaptor?
    private var ciContext: CIContext?
    
    private var mouseIsDown = false
    private var mouseLocation = CGPoint()
    private var clickListener: GlobalMouseListener?

    private var hasSession = false
    private var isRecording = false
    
    private var isWarm = false

    func beginRecording() async -> Bool {
        if isRecording {
            return true
        }
        isRecording = true
        
        if clickListener == nil {
            clickListener = GlobalMouseListener(handler: { event in
                if event?.type == .leftMouseDown {
                    self.mouseIsDown = true
                } else if event?.type == .leftMouseUp {
                    self.mouseIsDown = false
                }
                self.mouseLocation = event!.locationInWindow
            })
        }
        
        if ciContext == nil {
            ciContext = CIContext()
        }
        
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false,
                                                                               onScreenWindowsOnly: false)
            
            let display = content.displays.first!
            let filter = getFilter(display: display, availableApps: content.applications)
            let configuration = getConfiguration(display)
            
            beginWriting(width: display.width * scale, height: display.height * scale)
            
            stream = SCStream(filter: filter, configuration: configuration, delegate: self)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleHandlerQueue)
            try await stream?.startCapture()
                
            if UserDefaults.standard.value(forKey: "highlightClicks") as? Bool == true {
                clickListener?.start()
            }
            
            return stream != nil
        } catch {
            return false
        }
    }

    func stopRecording() async -> URL {
        try! await stream?.stopCapture()
        clickListener?.stop()
        await writer!.finishWriting()
        hasSession = false
        isRecording = false
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
        
        let attachmentses = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                createIfNecessary: false) as? [[SCStreamFrameInfo: Any]]
        let attachments = attachmentses?.first
        let status = attachments?[.status]
        

        if let rawStatus = status as? Int,
           let status = SCFrameStatus(rawValue: rawStatus),
                status == .complete,
           input!.isReadyForMoreMediaData  {
            
            
            if mouseIsDown || !isWarm {
                isWarm = true
                
                let image = CIImage(cvImageBuffer: sampleBuffer.imageBuffer!)
                
                let scale = NSScreen.main?.backingScaleFactor ?? 1.0
                let newImage = image.overlayCircle(center: CGPoint(x: mouseLocation.x * scale, y: mouseLocation.y * scale), radius: 50.0, outlineWidth: 8.0, color: CIColor(color: NSColor(Color("Yellow")))!)
                ciContext!.render(newImage!, to: image.pixelBuffer!)
                
                adapter!.append(image.pixelBuffer!, withPresentationTime: sampleBuffer.presentationTimeStamp)
            } else {
                input!.append(sampleBuffer)
            }
        }
    }

    private func beginWriting(width: Int, height: Int) {
        let directory = FileManager.default.temporaryDirectory
        let fileName = NSUUID().uuidString
        let outputURL = directory.appendingPathComponent(fileName).appendingPathExtension("mp4")
        print(width, height, fileName, outputURL)
        writer = try! AVAssetWriter(outputURL: outputURL, fileType: .mov);
        let outputSettings = [AVVideoCodecKey: AVVideoCodecType.h264,
                              AVVideoWidthKey: NSNumber(value: width),
                              AVVideoHeightKey: NSNumber(value: height)] as [String : Any]
        input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        input?.expectsMediaDataInRealTime = true;
        
        self.adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input!)
        

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
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let status = attachments[.status],
              let idk = attachments[.contentScale],
              let idk2 = attachments[.displayTime]
        else {
            return (0, 0)
        }
        print(contentRect, status, idk, idk2)
        return (contentRect.width, contentRect.height)
    }
}


extension CIImage {
    func overlayCircle(center: CGPoint, radius: CGFloat, outlineWidth: CGFloat, color: CIColor) -> CIImage? {
         let innerRadius = radius - outlineWidth
         let outerRadius = radius

         // Outer circle
         let outerGradient = CIFilter(name: "CIRadialGradient",
                                     parameters: ["inputRadius0": outerRadius - 1,
                                                  "inputRadius1": outerRadius,
                                                  "inputColor0": color,
                                                  "inputColor1": CIColor.clear,
                                                  "inputCenter": CIVector(x: center.x, y: center.y)])?.outputImage

         // Inner circle
         let innerGradient = CIFilter(name: "CIRadialGradient",
                                     parameters: ["inputRadius0": innerRadius - 1,
                                                  "inputRadius1": innerRadius,
                                                  "inputColor0": color,
                                                  "inputColor1": CIColor.clear,
                                                  "inputCenter": CIVector(x: center.x, y: center.y)])?.outputImage

         // Subtract the inner circle from the outer circle to create the outline
         let subtractFilter = CIFilter(name: "CISubtractBlendMode",
                                      parameters: ["inputImage": outerGradient!,
                                                   "inputBackgroundImage": innerGradient!])?.outputImage

        
        // Composite on top of screen recording
        let compositeFilter = CIFilter(name: "CIScreenBlendMode", parameters: ["inputImage": subtractFilter!, "inputBackgroundImage": self])?.outputImage
        

        return compositeFilter
    }
}
