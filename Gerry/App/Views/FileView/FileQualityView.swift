//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct FileQualityView: View {
    @State private var rate: Int = 60
    @State private var scaleFactor: Int = 1

    var body: some View {
        VStack {
            HStack {
                Picker(selection: $rate, label: Text("Frame rate").frame(width: 70)) {
                    Text("60 FPS").tag(60)
                    Text("30 FPS").tag(30)
                    Text("24 FPS").tag(24)
                    Text("16 FPS").tag(16)
                    Text("10 FPS").tag(10)
                }
            }
            HStack {
                Picker(selection: $scaleFactor, label: Text("Resolution").frame(width: 70)) {
                    Text("1x (1920x1080)").tag(1)
                    Text("0.5x (1920x1080)").tag(2)
                    Text("0.25x (1920x1080)").tag(4)
                    Text("0.125x (1920x1080)").tag(8)
                }
            }
        }.padding()
    }
}