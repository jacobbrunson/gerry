//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI
import AVKit

struct PlayerCropperView: View {
    let player: AVPlayer

    var mouseLocation: NSPoint { NSEvent.mouseLocation }
    @State var overPlayer = false

    @State var isDragging = false
    @State var start = CGPoint.zero
    @State var end = CGPoint.zero

    init(player: AVPlayer) {
        self.player = player
    }

    var body: some View {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        print(minY, maxY)
        return ZStack {
            AVPlayerControllerRepresented(player: player)
                    .onAppear {
                        player.play()
                    }
            Text("").frame(maxWidth: .infinity, maxHeight: .infinity).edgesIgnoringSafeArea(.all).contentShape(Rectangle())
                    .onHover { over in
                        overPlayer = over
                    }
                    .onAppear(perform: {
                        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) {
                            if isDragging {
                                end = mouseLocation
                            }
                            return $0
                        }
                        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) {
                            if overPlayer {
                                isDragging = true
                                start = mouseLocation
                            }
                            return $0
                        }
                        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) {
                            isDragging = false
                            end = mouseLocation
                            print("up")
                            return $0
                        }
            })
            GeometryReader { geo in
                Rectangle().frame(width: maxX - minX, height: maxY - minY).position(x: (minX + maxX) / 2, y: NSScreen.main!.frame.height-(minY + maxY) / 2).onAppear {
                    print(NSScreen.main!.frame.height)
                }
            }
        }

    }
}
//
//struct Idk: NSViewRepresentable {
//    func makeNSView(context: Context) ->
//
//}

struct AVPlayerControllerRepresented : NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player

        return view
    }

    func updateNSView(_ view: AVPlayerView, context: Context) {
        view.player
    }
}
