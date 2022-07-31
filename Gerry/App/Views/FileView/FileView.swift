//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI
import AVFoundation

struct FileView: View {
    @ObservedObject var saveWindowViewModel: SaveWindowContentView.ViewModel
    let onExport: () -> ()

    @StateObject private var fileViewModel = ViewModel()


    var body: some View {
        HStack {
            FileNameView(fileViewModel: fileViewModel)
            FileQualityView(fileViewModel: fileViewModel, saveWindowViewModel: saveWindowViewModel)
            FileSaveView(fileViewModel: fileViewModel, saveWindowViewModel: saveWindowViewModel, onExport: onExport)
        }
    }
}
