//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI
import AVFoundation

struct FileSaveView: View {
    @ObservedObject var viewModel: FileView.ViewModel

    let videoURL: URL
    let cropRect: CGRect?
    let startT: CGFloat
    let endT: CGFloat

    var body: some View {
        HStack {
            Button(action: {
                Task {
                    let result = await GifExporter().export(
                            videoAt: videoURL,
                            toFolder: viewModel.outputFolder!,
                            withName: viewModel.fileName,
                            croppingTo: cropRect,
                            startingAt: startT,
                            endingAt: endT,
                            withScale: 1.0/viewModel.scaleDivisor,
                            withFrameRate: CGFloat(viewModel.frameRate)
                    )
                    print(result)
                }
            }) {
                if viewModel.frameRate > 30 {
                    VStack {
                        Text("gif").font(.title)
                        Text("30 fps").font(.footnote)
                    }
                            .frame(width: 66, height: 48)
                            .background(Color("Yellow"))
                } else {
                    Text("gif").font(.title)
                            .frame(width: 66, height: 48)
                            .background(Color("Yellow"))

                }

            }
                    .buttonStyle(PlainButtonStyle())
                    .cornerRadius(10)
                    .foregroundColor(Color("DarkText"))

            Button(action: {

            }) {
                Text("mp4")
                        .font(.title)
                        .frame(width: 66, height: 48)
                        .background(Color("Yellow"))
                        .foregroundColor(Color("DarkText"))
                        .cornerRadius(10)
            }.buttonStyle(PlainButtonStyle())
        }.padding()
    }
}