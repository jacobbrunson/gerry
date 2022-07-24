//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI
import AVFoundation

struct FileSaveView: View {
    let videoURL: URL
    let outputFolder: URL
    let name: String
    let cropRect: CGRect?
    let startT: CGFloat
    let endT: CGFloat

    var body: some View {
        HStack {
            Button(action: {
                Task {
                    let result = await GifExporter().export(
                            videoAt: videoURL,
                            toFolder: outputFolder,
                            withName: name,
                            croppingTo: cropRect,
                            startingAt: startT,
                            endingAt: endT,
                            withScale: 1.0,
                            withFPS: 30
                    )
                    print(result)
                }
            }) {
                Text("gif")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color("Yellow"))
                        .foregroundColor(Color("DarkText"))
            }.buttonStyle(PlainButtonStyle())
            Button(action: {

            }) {
                Text("mp4")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color("Yellow"))
                        .foregroundColor(Color("DarkText"))
            }.buttonStyle(PlainButtonStyle())
        }.padding()
    }
}