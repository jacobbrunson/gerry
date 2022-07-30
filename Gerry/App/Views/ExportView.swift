//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI
import AVFoundation
import AppKit

struct ExportView: View {
    let videoURL: URL
    let onExport: () -> ()
    let player: AVPlayer

    @State private var currentTime: CMTime = CMTime.zero

    @State private var cropRect: CGRect?
    @State private var startT = 0.0
    @State private var endT = 1.0

    @State private var saveProgress: Double?

    init(videoURL: URL, onExport: @escaping () -> ()) {
        self.videoURL = videoURL
        self.onExport = onExport
        player = AVPlayer(url: videoURL)
    }

    var body: some View {
        VStack {
            PlayerCropperView(player: player, cropRect: $cropRect).onAppear { player.play() }
            Spacer(minLength: 24)
            TrimmerView(mediaURL: videoURL, currentTime: currentTime, cropRect: $cropRect) { t, position in
                if position == .left {
                    startT = t
                } else {
                    endT = t
                }
                player.seek(to: CMTime(seconds: player.currentItem!.duration.seconds * t * 0.999999, preferredTimescale: 10000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                player.play()
            }.frame(height: 100)
            GeometryReader { geometry in
                let availableWidth = geometry.frame(in: .local).width
                let image = Image("Gerry").resizable().padding(.leading, availableWidth >= 1500 ? 12 : 0)
                let fileView = FileView(videoURL: videoURL, cropRect: cropRect, startT: startT, endT: endT, saveProgress: $saveProgress, onExport: onExport).frame(height: 100).frame(maxWidth: 900)

                ZStack(alignment: .bottomLeading) {
                    if availableWidth >= 1500 {
                        ZStack {
                            HStack {
                                image.frame(width: 200, height: 75)
                                Spacer()
                            }
                            fileView
                        }.frame(height: 100)
                    } else if availableWidth >= 1100 {
                        HStack {
                            Spacer()
                            image.frame(width: 200, height: 75)
                            fileView
                            Spacer()
                        }
                    } else if availableWidth >= 750 {
                        let width = 200 * (availableWidth - 750) / 350
                        HStack {
                            image.frame(width: width, height: width * 0.375).padding(.leading)
                            fileView
                        }
                    } else {
                        fileView
                    }
                    if saveProgress != nil {
                        Rectangle().fill(Color("Yellow")).frame(width: availableWidth * saveProgress!, height: 4).animation(.easeOut)
                    }
                }

            }.frame(height: 100)
        }.onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0/60, repeats: true) { [self] timer in
                let duration = player.currentItem!.duration.seconds
                let startTime = startT * duration
                let endTime = endT * duration
                let currentTime = player.currentTime()
                self.currentTime = currentTime
                if currentTime.seconds >= endTime {
                    player.seek(to: CMTime(seconds: startTime, preferredTimescale: 1000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                }
                player.play()
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
