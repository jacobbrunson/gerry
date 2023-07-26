//
//  SaveWindowContentView.swift
//  Gerry
//
//  Created by Jacob Brunson on 7/31/22.
//

import SwiftUI
import AVFoundation

struct SaveWindowContentView: View {
    @ObservedObject private var viewModel = ViewModel()
    let onExport: () -> ()


    init(assetURL: URL, onExport: @escaping () -> ()) {
        self.onExport = onExport
        viewModel.assetURL = assetURL
    }

    var body: some View {
        VStack {
            PlayerCropperView(viewModel: viewModel)
            Spacer(minLength: 24)
            TrimmerView(viewModel: viewModel, onUpdate: { t, position in
                if position == .left {
                    viewModel.startT = t
                } else {
                    viewModel.endT = t
                }
                viewModel.player.seek(to: CMTime(seconds: viewModel.player.currentItem!.duration.seconds * t * 0.999999, preferredTimescale: 10000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                viewModel.player.play()
            }).frame(height: 100)
            ResponsiveLogoAndFile(viewModel: viewModel, onExport: onExport).frame(height: 130)
        }.background(GerryBackground(material: NSVisualEffectView.Material.underWindowBackground, blendingMode: .behindWindow, isEmphasized: true))
    }
}

struct ResponsiveLogoAndFile: View {
    @ObservedObject var viewModel: SaveWindowContentView.ViewModel
    let onExport: () -> ()

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.frame(in: .local).width
            let image = Image("Gerry").resizable().padding(.leading, availableWidth >= 1500 ? 12 : 0)
            let fileView = FileView(saveWindowViewModel: viewModel, onExport: onExport).frame(height: 130).frame(maxWidth: 900)
            
            
            VStack(alignment: .leading) {
                if availableWidth >= 1500 {
                    ZStack {
                        HStack {
                            image.frame(width: 267, height: 100).padding(.top, 30)
                            Spacer()
                        }
                        fileView
                    }.frame(height: 100)
                } else if availableWidth >= 1100 {
                    HStack {
                        Spacer()
                        image.frame(width: 267, height: 100).padding(.top, 30)
                        fileView
                        Spacer()
                    }.frame(height: 100)
                } else if availableWidth >= 750 {
                    let width = 200 * (availableWidth - 750) / 350
                    HStack {
                        image.frame(width: width, height: width * 0.375).padding(.leading).padding(.top, 30)
                        fileView
                    }.frame(height: 100)
                } else {
                    fileView
                }
                if viewModel.saveProgress != nil {
                    VStack {
                        withAnimation(.easeOut) {
                            Rectangle().fill(Color("Yellow")).frame(width: availableWidth * viewModel.saveProgress!, height: 4)
                        }
                    }.frame(height:34)
                }
            }

        }
    }
}

struct GerryBackground: NSViewRepresentable {
    private let material: NSVisualEffectView.Material
    private let blendingMode: NSVisualEffectView.BlendingMode
    private let isEmphasized: Bool

    init(
            material: NSVisualEffectView.Material,
            blendingMode: NSVisualEffectView.BlendingMode,
            isEmphasized: Bool) {
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = isEmphasized
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.autoresizingMask = [.width, .height]
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = isEmphasized
    }
}
