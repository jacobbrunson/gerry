//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import SwiftUI

struct FileView: View {
    var body: some View {
        HStack {
            FileNameView()
            FileQualityView()
            FileSaveView()
        }
    }
}
