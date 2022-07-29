//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation

protocol Exporter {
    func getUrl(forOutputFolder: URL, withFileName: String) -> URL

    func export(
            videoAt: URL,
            toFolder: URL,
            withName: String,
            croppingTo: CGRect?,
            startingAt: CGFloat,
            endingAt: CGFloat,
            withScale: CGFloat,
            withFrameRate: CGFloat,
            onProgress: @escaping (CGFloat) -> ()
    ) async -> URL
}

enum ExportError: Error {
    case notPermitted
    case failed
}
