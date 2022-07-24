//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct FileNameView: View {
    @ObservedObject var viewModel: FileView.ViewModel

    var body: some View {
        VStack {
            HStack {
                Text("Output folder").frame(width: 90, alignment: .leading)
                HighlightTextField(text: $viewModel.outputFolderPath)
                Button(action: {
                    Task {
                        viewModel.outputFolder = await selectFolder()
                        // Todo: this should be set at a different point in flow
                        UserDefaults.standard.set(viewModel.outputFolder, forKey: "outputFolder")
                    }
                }) {
                    Text("Browse...")
                }
                Spacer()
            }
            HStack {
                Text("File name").frame(width: 90, alignment: .leading)
                HighlightTextField(text: $viewModel.fileName)
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
