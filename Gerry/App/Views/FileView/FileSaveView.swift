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
    @Binding var saveProgress: Double?

    private func export(using exporter: Exporter) async {
        let outputFolder = viewModel.outputFolder!
        let fileName = viewModel.fileName
        let outputURL = exporter.getUrl(forOutputFolder: outputFolder, withFileName: fileName)

        let fileExists = FileManager.default.fileExists(atPath: outputURL.path)


        if fileExists {
            let fileExistsAction = UserDefaults.standard.value(forKey: "fileExistsAction") as? String

            if fileExistsAction == "cancel" {
                saveProgress = nil
                return
            }

            if fileExistsAction != "overwrite" {
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
                    saveProgress = nil
                    return
                }
            }
        }

        let result = await exporter.export(
                videoAt: videoURL,
                toFolder: outputFolder,
                withName: fileName,
                croppingTo: cropRect,
                startingAt: startT,
                endingAt: endT,
                withScale: 1.0/viewModel.scaleDivisor,
                withFrameRate: CGFloat(viewModel.frameRate),
                onProgress: { if saveProgress != nil { saveProgress = $0 } }
        )
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in saveProgress = nil }
        print(result)
    }

    var body: some View {
        HStack {
            Button(action: {
                saveProgress = 0
                viewModel.regenerateDefaultFileName()
                Task {
                    await export(using: GifExporter())
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
                    .disabled(saveProgress != nil)
                    .buttonStyle(PlainButtonStyle())
                    .cornerRadius(10)
                    .foregroundColor(Color("DarkText"))

            Button(action: {
                saveProgress = 0
                viewModel.regenerateDefaultFileName()
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
            }.disabled(saveProgress != nil).buttonStyle(PlainButtonStyle())
        }.padding()
    }
}