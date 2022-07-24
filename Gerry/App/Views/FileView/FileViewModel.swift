//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation

extension FileView {
    @MainActor
    class ViewModel: ObservableObject {
        @Published private var selectedOutputFolder: URL?
        private let defaultOutputFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        @Published private var selectedFileName: String?
        @Published private var defaultFileName = "Gerry-" + UUID().uuidString.split(separator: "-")[0]

        var outputFolder: URL? {
            get { selectedOutputFolder ?? UserDefaults.standard.url(forKey: "outputFolder") ?? defaultOutputFolder }
            set { selectedOutputFolder = newValue }
        }

        var outputFolderPath: String {
            get { outputFolder?.path ?? "" }
            set { outputFolder = newValue.isEmpty ? nil : URL(string: newValue) }
        }

        var fileName: String {
            get { selectedFileName ?? defaultFileName }
            set { selectedFileName = newValue.isEmpty ? nil : newValue }
        }
    }
}