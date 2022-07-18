//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI
import AVKit

struct PlayerCropperView: View {
    let player: AVPlayer

    init(url: URL) {
        player = AVPlayer(url: url)
    }

    var body: some View {
        AVPlayerControllerRepresented(player: player)
                .onAppear {
                    player.play()
                }
                .frame(height: 400)
    }
}

struct AVPlayerControllerRepresented : NSViewRepresentable {
    var player : AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        // loop the player
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [self] _ in
            player.seek(to: CMTime.zero)
            player.play()
        }
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {

    }
}
