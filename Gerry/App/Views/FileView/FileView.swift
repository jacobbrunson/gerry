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

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        HStack {
            FileNameView(viewModel: viewModel)
            FileQualityView()
            FileSaveView(videoURL: videoURL, outputFolder: viewModel.outputFolder, name: viewModel.fileName, cropRect: cropRect, startT: startT, endT: endT)
        }
    }
}
