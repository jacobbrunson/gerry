//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AppKit

extension FileView {
    @MainActor
    class ViewModel: ObservableObject {
        // File name
        @Published private var selectedFileName: String?
        @Published private var defaultFileName = ""
        var fileName: String {
            get {
                if defaultFileName.isEmpty {
                    regenerateDefaultFileName()
                }
                return selectedFileName ?? defaultFileName
            }
            set { print("setting file name", newValue); selectedFileName = newValue.isEmpty ? nil : newValue }
        }

        func regenerateDefaultFileName() {
            defaultFileName = "Gerry-" + UUID().uuidString.split(separator: "-")[0]
        }

        // Frame rate
        @Published private var _frameRate: Int  = (UserDefaults.standard.value(forKey: "frameRate") as? Int) ?? 30
        var frameRate: Int {
            get { _frameRate }
            set {
                _frameRate = newValue
                UserDefaults.standard.set(newValue, forKey: "frameRate")
            }
        }

        // Scale
        @Published private var _scaleDivisor: CGFloat = (UserDefaults.standard.value(forKey: "scaleDivisor") as? CGFloat) ?? NSScreen.main?.backingScaleFactor ?? 1
        var scaleDivisor: CGFloat {
            get { _scaleDivisor }
            set {
                _scaleDivisor = newValue
                UserDefaults.standard.set(newValue, forKey: "scaleDivisor")
            }
        }

        // Output folder
        @Published private var selectedOutputFolder: URL?
        private let defaultOutputFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        private var userDefaultOutputFolder: URL? {
            guard let bookmarkData = UserDefaults.standard.data(forKey: "outputFolder") else { return nil }

            var bookmarkDataIsStale = false;
            let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, bookmarkDataIsStale: &bookmarkDataIsStale)

            guard !bookmarkDataIsStale else { return nil }

            return url
        }

        var outputFolder: URL? {
            get { selectedOutputFolder ?? userDefaultOutputFolder ?? defaultOutputFolder }
            set { selectedOutputFolder = newValue }
        }

        var outputFolderPath: String {
            get { outputFolder?.path ?? "" }
            set { }
        }
    }
}