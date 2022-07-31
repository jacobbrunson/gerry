//
//  SaveWindowContentViewModel.swift
//  Gerry
//
//  Created by Jacob Brunson on 7/31/22.
//

import Foundation
import AVFoundation

extension SaveWindowContentView {
    class ViewModel: ObservableObject {
        @Published private var avPlayer: AVPlayer?

        @Published var cropRect: CGRect?
        @Published var startT = 0.0
        @Published var endT = 1.0

        @Published var saveProgress: Double?

        var assetURL: URL {
            get { (avPlayer!.currentItem!.asset as! AVURLAsset).url }
            set {
                if newValue == nil {
                    avPlayer = nil
                } else {
                    let player = AVPlayer(url: newValue)
                    player.isMuted = true
                    player.allowsExternalPlayback = false

                    avPlayer = player
                    player.play()
                }
            }
        }

        var player: AVPlayer { avPlayer! }
    }
}