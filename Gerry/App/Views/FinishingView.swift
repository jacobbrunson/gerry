//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI
import AVFoundation

struct FinishingView: View {
    let tolerance = CMTime(value: 1, timescale: 1000)

    let videoURL: URL
    let player: AVPlayer

    @State private var currentTime: CMTime = CMTime.zero
    @State private var startT = 0.0
    @State private var stopT = 1.0

    init(videoURL: URL) {
        self.videoURL = videoURL
        player = AVPlayer(url: videoURL)
    }

    var body: some View {
        VStack {
            PlayerCropperView(player: player).onAppear { print("play"); player.play(); print("plaedy"); }
            TrimmerView(mediaURL: videoURL, currentTime: currentTime) { t, position in
                if position == .left {
                    startT = t
                } else {
                    stopT = t
                }
            }.frame(height: 50)
            HStack {
                Divider()
                NamingView()
                Divider()
                QualityView()
                Divider()
                SavingView()
                Divider()
            }.frame(height: 100).frame(maxWidth: 900)
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
                }
    }
}




struct NamingView: View {
    @State private var defaultName: String = UUID().uuidString

    @State private var folder: String = ""
    @State private var name: String = ""

    @FocusState private var isFocused: Bool

    var body: some View {
        let nameBinding = Binding<String>(get: {
            name.isEmpty && !isFocused ? defaultName : name
        }, set: {
            if isFocused {
                name = $0
            }
        })

        return VStack {
            HStack {
                Text("Output folder").frame(width: 90, alignment: .leading)
                TextField("", text: $folder)
                        .frame(width: 260)
                Button(action: {}) {
                    Text("Browse...")
                }
                Spacer()
            }
            HStack {
                Text("File name").frame(width: 90, alignment: .leading)
                TextField("", text: nameBinding).frame(width: 120).focused($isFocused).onChange(of: isFocused) { isFocused in
                    print(isFocused, name, name.isEmpty)
                }
                Spacer()
            }
        }.padding().frame(width: 477)
    }
}

struct QualityView: View {
    @State private var rate: Int = 60
    @State private var scaleFactor: Int = 1

    var body: some View {
        VStack {
            HStack {
                Picker(selection: $rate, label: Text("Frame rate").frame(width: 70)) {
                    Text("60 FPS").tag(60)
                    Text("30 FPS").tag(30)
                    Text("24 FPS").tag(24)
                    Text("16 FPS").tag(16)
                    Text("10 FPS").tag(10)
                }
            }
            HStack {
                Picker(selection: $scaleFactor, label: Text("Resolution").frame(width: 70)) {
                    Text("1x (1920x1080)").tag(1)
                    Text("0.5x (1920x1080)").tag(2)
                    Text("0.25x (1920x1080)").tag(4)
                    Text("0.125x (1920x1080)").tag(8)
                }
            }
        }.padding()
    }
}

struct SavingView: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Text("gif")
            }
            Button(action: {}) {
                Text("mp4")
            }
        }.padding()
    }
}

