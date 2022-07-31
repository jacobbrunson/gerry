//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI
import AVFoundation

struct FileSaveView: View {
    @ObservedObject var fileViewModel: FileView.ViewModel
    @ObservedObject var saveWindowViewModel: SaveWindowContentView.ViewModel

    let onExport: () -> ()

    private func export(using exporter: Exporter) async {
        let outputFolder = fileViewModel.outputFolder!
        let fileName = fileViewModel.fileName
        let outputURL = exporter.getUrl(forOutputFolder: outputFolder, withFileName: fileName)

        let fileExists = FileManager.default.fileExists(atPath: outputURL.path)


        if fileExists {
            let fileExistsAction = UserDefaults.standard.value(forKey: "fileExistsAction") as? String

            if fileExistsAction == "cancel" {
                saveWindowViewModel.saveProgress = nil
                return
            }

            if fileExistsAction == nil {
                let alert = NSAlert()
                alert.messageText = "Overwrite file?"
                alert.informativeText = "A file named \"\(outputURL.lastPathComponent)\" already exists. Would you like to replace it?"
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "Overwrite")
                alert.alertStyle = .critical
                alert.showsSuppressionButton = true

                let shouldCancel = alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn

                if alert.suppressionButton?.state.rawValue == 1 {
                    UserDefaults.standard.set(shouldCancel ? "cancel" : "overwrite", forKey: "fileExistsAction")
                }

                if shouldCancel  {
                    saveWindowViewModel.saveProgress = nil
                    return
                }
            }
        }

        saveWindowViewModel.saveProgress = 0
        fileViewModel.regenerateDefaultFileName()

        let result = await exporter.export(
                videoAt: saveWindowViewModel.assetURL,
                toFolder: outputFolder,
                withName: fileName,
                croppingTo: saveWindowViewModel.cropRect,
                startingAt: saveWindowViewModel.startT,
                endingAt: saveWindowViewModel.endT,
                withScale: 1.0/fileViewModel.scaleDivisor,
                withFrameRate: CGFloat(fileViewModel.frameRate),
                onProgress: { if saveWindowViewModel.saveProgress != nil { saveWindowViewModel.saveProgress = $0 } }
        )
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in saveWindowViewModel.saveProgress = nil }
        onExport()
        print(result)
    }

    var body: some View {
        HStack {
            Button(action: {
                Task {
                    await export(using: GifExporter())
                }
            }) {
                if fileViewModel.frameRate > 30 {
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
                    .disabled(saveWindowViewModel.saveProgress != nil)
                    .buttonStyle(PlainButtonStyle())
                    .cornerRadius(10)
                    .foregroundColor(Color("DarkText"))

            Button(action: {
                Task {
                    await export(using: Mp4Exporter())
                }
            }) {
                Text("mp4")
                        .font(.title)
                        .frame(width: 66, height: 48)
                        .background(Color("Yellow"))
                        .foregroundColor(Color("DarkText"))
                        .cornerRadius(10)
            }.disabled(saveWindowViewModel.saveProgress != nil).buttonStyle(PlainButtonStyle())
        }.padding()
    }
}