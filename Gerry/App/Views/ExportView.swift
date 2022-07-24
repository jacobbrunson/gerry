//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI
import AVFoundation
import AppKit

struct ExportView: View {
    let tolerance = CMTime(value: 1, timescale: 1000)

    let videoURL: URL
    let player: AVPlayer

    @State private var cropRect: CGRect?
    @State private var currentTime: CMTime = CMTime.zero
    @State private var startT = 0.0
    @State private var stopT = 1.0

    init(videoURL: URL) {
        self.videoURL = videoURL
        player = AVPlayer(url: videoURL)
    }

    var body: some View {
        VStack {
            PlayerCropperView(player: player, cropRect: $cropRect).onAppear { player.play() }
            Spacer(minLength: 24)
            TrimmerView(mediaURL: videoURL, currentTime: currentTime) { t, position in
                if position == .left {
                    startT = t
                } else {
                    stopT = t
                }
                player.seek(to: CMTime(seconds: player.currentItem!.duration.seconds * t, preferredTimescale: 10000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            }.frame(height: 100)
            FileView(videoURL: videoURL, cropRect: cropRect, startT: 0, endT: 1).frame(height: 100).frame(maxWidth: 900)
        }.onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0/60, repeats: true) { [self] timer in
                let duration = player.currentItem!.duration.seconds
                let startTime = startT * duration
                let stopTime = stopT * duration
                let currentTime = player.currentTime()
                self.currentTime = currentTime
                if currentTime.seconds >= stopTime {
                    player.seek(to: CMTime(seconds: startTime, preferredTimescale: 1000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                    player.play()
                }
            }
        }.background(VisualEffectBackground(material: NSVisualEffectView.Material.underWindowBackground, blendingMode: .behindWindow, isEmphasized: true))
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    private let material: NSVisualEffectView.Material
    private let blendingMode: NSVisualEffectView.BlendingMode
    private let isEmphasized: Bool

    fileprivate init(
            material: NSVisualEffectView.Material,
            blendingMode: NSVisualEffectView.BlendingMode,
            isEmphasized: Bool) {
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = isEmphasized
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        // Not certain how necessary this is
        view.autoresizingMask = [.width, .height]

        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = isEmphasized
    }
}
