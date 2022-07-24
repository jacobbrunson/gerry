//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AVKit

class EdgeCropHandle: CropHandle {
    let edge: CropEdge
    var rect = CGRect.zero

    init(_ edge: CropEdge) {
        self.edge = edge
    }

    func update(start: CGPoint, end: CGPoint, deltaX: CGFloat, deltaY: CGFloat) -> (CGPoint, CGPoint) {
        if isVertical {
            if edge == .left && start.x < end.x || edge == .right && start.x > end.x {
                return (CGPoint(x: start.x + deltaX, y: start.y), end)
            } else {
                return (start, CGPoint(x: end.x + deltaX, y: end.y))
            }
        } else {
            if edge == .top && start.y > end.y || edge == .bottom && start.y < end.y {
                return (CGPoint(x: start.x, y: start.y - deltaY), end)
            } else {
                return (start, CGPoint(x: end.x, y: end.y - deltaY))
            }
        }
    }

    func draw(_ context: CGContext) {
        if isVertical {
            context.addRect(CGRect(
                    x: point.x - (edge == .left ? 0 : handleWidth),
                    y: point.y - handleLength / 2,
                    width: handleWidth,
                    height: handleLength
            ))
        } else {
            context.addRect(CGRect(
                    x: point.x - handleLength / 2,
                    y: point.y - (edge == .bottom ? 0 : handleWidth),
                    width: handleLength,
                    height: handleWidth
            ))
        }
        context.setFillColor(NSColor(named: "Yellow")!.cgColor)
        context.drawPath(using: .fill)
    }

    var point: CGPoint {
        switch edge {
        case .top:
            return CGPoint(x: rect.midX, y: rect.maxY)
        case .right:
            return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottom:
            return CGPoint(x: rect.midX, y: rect.minY)
        case .left:
            return CGPoint(x: rect.minX, y: rect.midY)
        }
    }

    var cursor: NSCursor {
        if isVertical {
            return NSCursor.resizeLeftRight
        } else {
            return NSCursor.resizeUpDown
        }
    }

    private var isVertical: Bool {
        edge == .left || edge == .right
    }
}

enum CropEdge {
    case top
    case right
    case bottom
    case left
}