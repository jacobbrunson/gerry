//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct FileNameView: View {
    @Binding var outputFolder: URL?
    @Binding var name: String

    @State private var defaultOutputFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    @State private var defaultName: String = "Gerry-" + UUID().uuidString.split(separator: "-")[0]

    var body: some View {
        let outputFolderBinding = Binding<String>(get: {
            outputFolder?.path ?? ""
        }, set: {
            outputFolder = URL(string: $0)!
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