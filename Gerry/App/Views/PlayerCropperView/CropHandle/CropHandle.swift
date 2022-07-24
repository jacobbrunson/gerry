//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AppKit

protocol CropHandle {
    var cursor: NSCursor { get }
    var rect: CGRect { get set }
    var point: CGPoint { get }
    func draw(_ context: CGContext) -> ()
    func update(start: CGPoint, end: CGPoint, deltaX: CGFloat, deltaY: CGFloat) -> (CGPoint, CGPoint)
}


