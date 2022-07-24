//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI
import AVFoundation

struct FileView: View {
    let videoURL: URL
    let cropRect: CGRect
    let startT: CGFloat
    let endT: CGFloat

    @State private var outputFolder = UserDefaults.standard.url(forKey: "outputFolder")
    @State private var name = ""

    var body: some View {
        HStack {
            FileNameView(outputFolder: $outputFolder, name: $name)
            FileQualityView()
            FileSaveView(videoURL: videoURL, outputFolder: outputFolder!, name: name, cropRect: cropRect, startT: startT, endT: endT)
        }
    }
}
