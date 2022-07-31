//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct FileQualityView: View {

    @ObservedObject var fileViewModel: FileView.ViewModel
    @ObservedObject var saveWindowViewModel: SaveWindowContentView.ViewModel

    var body: some View {
        let cropRect = saveWindowViewModel.cropRect
        let resolution = cropRect == nil ? nil : CGSize(width: cropRect!.width, height: cropRect!.height)
        return VStack {
            HStack {
                Picker(selection: $fileViewModel.frameRate, label: Text("Frame rate").frame(width: 70)) {
                    Text("60 FPS (mp4 only)").tag(60)
                    Text("30 FPS").tag(30)
                    Text("24 FPS").tag(24)
                    Text("16 FPS").tag(16)
                    Text("12 FPS").tag(12)
                }
            }
            HStack {
                Picker(selection: $fileViewModel.scaleDivisor, label: Text("Resolution").frame(width: 70)) {
                    ResolutionTextView(resolution: resolution, divisor: 1.0)
                    ResolutionTextView(resolution: resolution, divisor: 2.0)
                    ResolutionTextView(resolution: resolution, divisor: 4.0)
                    ResolutionTextView(resolution: resolution, divisor: 8.0)
                }
            }
        }.padding()
    }

    struct ResolutionTextView: View {
        let resolution: CGSize?
        let divisor: CGFloat

        var body: some View {
            Text("\(scaleText)\(resolutionText)").tag(divisor)
        }

        private var scaleText: String {
            divisor == 1 ? "Full" : "\(1.0/divisor)x"
        }

        private var resolutionText: String {
            if resolution == nil {
                return ""
            }
            let divisorF = CGFloat(divisor)
            let width = Int(resolution!.width / divisorF)
            let height = Int(resolution!.height / divisorF)
            return " (\(width)x\(height))"
        }
    }
}

