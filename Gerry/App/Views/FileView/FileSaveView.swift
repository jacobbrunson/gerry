//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct FileSaveView: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Text("gif")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color("Yellow"))
                        .foregroundColor(Color("DarkText"))
            }.buttonStyle(PlainButtonStyle())
            Button(action: {}) {
                Text("mp4")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color("Yellow"))
                        .foregroundColor(Color("DarkText"))
            }.buttonStyle(PlainButtonStyle())
        }.padding()
    }
}