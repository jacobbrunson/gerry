//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI
import AVFoundation

struct FileView: View {
    let videoURL: URL
    let cropRect: CGRect?
    let startT: CGFloat
    let endT: CGFloat
    @Binding var saveProgress: Double?

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        HStack {
            FileNameView(viewModel: viewModel)
            FileQualityView(viewModel: viewModel, cropRect: cropRect)
            FileSaveView(viewModel: viewModel, videoURL: videoURL, cropRect: cropRect, startT: startT, endT: endT, saveProgress: $saveProgress)
        }
    }
}
