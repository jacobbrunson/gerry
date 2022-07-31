//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct FileNameView: View {
    @ObservedObject var fileViewModel: FileView.ViewModel

    var body: some View {
        VStack {
            HStack {
                Text("Output folder").frame(width: 90, alignment: .leading)
                TextField("", text: $fileViewModel.outputFolderPath).disabled(true)
                Button(action: {
                    Task {
                        let selectedURL =  await selectFolder()
                        fileViewModel.outputFolder = selectedURL

                        // Persist this URL and its associated security data in a "bookmark"
                        if let bookmark = try? selectedURL.bookmarkData(
                                options: .withSecurityScope,
                                includingResourceValuesForKeys: nil,
                                relativeTo: nil
                        ) {
                            UserDefaults.standard.set(bookmark, forKey: "outputFolder")
                        }
                    }
                }) {
                    Text("Browse...")
                }
                Spacer()
            }
            HStack {
                Text("File name").frame(width: 90, alignment: .leading)
                HighlightTextField(text: $fileViewModel.fileName)
                Spacer()
            }
        }.padding().frame(width: 400)
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
                if response == .OK {
                    continuation.resume(returning: folderPicker.urls.first!)
                }
            }
        }
    }
}
