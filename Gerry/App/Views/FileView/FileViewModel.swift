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
            DispatchQueue.main.async {
                self.defaultFileName = "Gerry-" + UUID().uuidString.split(separator: "-")[0]
            }
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
        private let defaultOutputFolder =
                FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Gerry", isDirectory: true)

        private var userDefaultOutputFolder: URL? {
            guard let bookmarkData = UserDefaults.standard.data(forKey: "outputFolder") else { return nil }

            var bookmarkDataIsStale = false;
            let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, bookmarkDataIsStale: &bookmarkDataIsStale)

            guard !bookmarkDataIsStale else { return nil }

            return url
        }

        var outputFolder: URL? {
            get {
                selectedOutputFolder ?? userDefaultOutputFolder ?? defaultOutputFolder
            }
            set { selectedOutputFolder = newValue }
        }

        var outputFolderPath: String {
            get { outputFolder == nil ? "" : friendlyPath(for: outputFolder!)}
            set { }
        }
        
        @Published private var _shouldCopyToClipboard = (UserDefaults.standard.value(forKey: "shouldCopyToClipboard") as? Bool) ?? false;
        var shouldCopyToClipboard: Bool {
            get { _shouldCopyToClipboard }
            set {
                _shouldCopyToClipboard = newValue
                UserDefaults.standard.set(newValue, forKey: "shouldCopyToClipboard")
            }
        }
        
        private static let pathNames: [FileManager.SearchPathDirectory: String] = [
            .moviesDirectory: "Movies",
            .desktopDirectory: "Desktop",
            .downloadsDirectory: "Downloads",
            .documentDirectory: "Documents",
            .picturesDirectory: "Pictures",
        ]
        
        func friendlyPath(for url: URL) -> String {
            for (directory, friendlyName) in ViewModel.pathNames {
                let basePath = FileManager.default.urls(for: directory, in: .userDomainMask)[0].path
                if url.path.contains(basePath) {
                    return url.path.replacingOccurrences(of: basePath, with: "~/\(friendlyName)")
                }
            }
            
            return url.path
        }
    
    }
}
