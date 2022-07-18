//
// Created by Jacob Brunson on 7/17/22.
//

import Foundation
import SwiftUI

struct SavingView: View {

    let videoURL: URL

    init(videoURL: URL) {
        self.videoURL = videoURL
    }

    var body: some View {
        VStack {
            Text("Hello world")
            PlayerCropperView(url: videoURL)
            Text("trimmer video")
        }
    }
}
