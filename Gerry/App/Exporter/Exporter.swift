//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation

protocol Exporter {
    func export(videoAt: URL, toFolder: URL, withName: String, croppingTo: CGRect?, startingAt: CGFloat, endingAt: CGFloat, withScale: CGFloat, withFPS: CGFloat) async -> URL
}

enum ExportError: Error {
    case notPermitted
    case failed
}
