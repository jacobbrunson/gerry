//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI
import AVFoundation
import AppKit

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
            PlayerCropperView(player: player).onAppear { player.play() }
            Spacer(minLength: 24)
            TrimmerView(mediaURL: videoURL, currentTime: currentTime) { t, position in
                if position == .left {
                    startT = t
                } else {
                    stopT = t
                }
                player.seek(to: CMTime(seconds: player.currentItem!.duration.seconds * t, preferredTimescale: 10000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            }.frame(height: 100)
            HStack {
                NamingView()
                QualityView()
                SavingView()
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
        }.background(VisualEffectBackground(material: NSVisualEffectView.Material.underWindowBackground, blendingMode: .behindWindow, isEmphasized: true))
    }
}


struct DefaultTextField: View {
    @Binding var value: String
    let defaultValue: String
    let clearDefaultOnFocus: Bool

    init(value: Binding<String>, defaultValue: String, clearDefaultOnFocus: Bool = true) {
        self._value = value
        self.defaultValue = defaultValue
        self.clearDefaultOnFocus = clearDefaultOnFocus
    }

    @FocusState private var isFocused: Bool

    var body: some View {
        let valueBinding = Binding<String>(get: {
            if !value.isEmpty || (isFocused && clearDefaultOnFocus) {
                return value
            }
            return defaultValue
        }, set: {
            if isFocused {
                value = $0
            }
        })

        TextField("", text: valueBinding).focused($isFocused).onChange(of: isFocused) { _ in }
    }
}

struct NamingView: View {
    @State private var defaultOutputFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    @State private var defaultName: String = "Gerry-" + UUID().uuidString.split(separator: "-")[0]

    @State private var outputFolder = UserDefaults.standard.url(forKey: "outputFolder")
    @State private var name = ""

    @FocusState private var isFocused: Bool

    var body: some View {
        let outputFolderBinding = Binding<String>(get: {
            outputFolder?.path ?? ""
        }, set: {
            outputFolder = URL(string: $0)
        })

        VStack {
            HStack {
                Text("Output folder").frame(width: 90, alignment: .leading)
                DefaultTextField(value: outputFolderBinding, defaultValue: defaultOutputFolder.path, clearDefaultOnFocus: false).frame(width: 260)
                Button(action: {
                    Task {
                        outputFolder = await selectFolder()
                        // Todo: this should be set at a different point in flow
                        UserDefaults.standard.set(outputFolder, forKey: "outputFolder")
                    }
                }) {
                    Text("Browse...")
                }
                Spacer()
            }
            HStack {
                Text("File name").frame(width: 90, alignment: .leading)
                DefaultTextField(value: $name, defaultValue: defaultName).frame(width: 120)
                Spacer()
            }
        }.padding().frame(width: 477)
    }

    @MainActor
    func selectFolder() async -> URL {
        let folderChooserPoint = CGPoint(x: 0, y: 0)
        let folderChooserSize = CGSize(width: 500, height: 600)
        let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
        let folderPicker = NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)

        folderPicker.canChooseDirectories = true
        folderPicker.canChooseFiles = false
        folderPicker.allowsMultipleSelection = false

        return await withCheckedContinuation{ continuation in
            folderPicker.begin { response in
                if response == .OK && folderPicker.url != nil {
                    continuation.resume(returning: folderPicker.url!)
                }
            }
        }
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
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color("Yellow"))
                        .foregroundColor(Color("DarkText"))
            }.buttonStyle(PlainButtonStyle())
            Button(action: {}) {
                Text("mp4")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color("Yellow"))
                        .foregroundColor(Color("DarkText"))
            }.buttonStyle(PlainButtonStyle())
        }.padding()
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
