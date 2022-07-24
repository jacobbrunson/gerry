//
// Created by Jacob Brunson on 7/24/22.
//

import Foundation
import AppKit

class VertexCropHandle: CropHandle {
    let vertex: CropVertex
    var rect: CGRect = CGRect.zero

    init(_ vertex: CropVertex) {
        self.vertex = vertex
    }

    func update(start: CGPoint, end: CGPoint, deltaX: CGFloat, deltaY: CGFloat) -> (CGPoint, CGPoint) {
        if isTop && start.y > end.y || !isTop && start.y < end.y {
            if isLeft && start.x < end.x || !isLeft && start.x > end.x {
                return (CGPoint(x: start.x + deltaX, y: start.y - deltaY), end)
            } else {
                return (CGPoint(x: start.x, y: start.y - deltaY), CGPoint(x: end.x + deltaX, y: end.y))
            }
        } else {
            if isLeft && start.x < end.x || !isLeft && start.x > end.x {
                return (CGPoint(x: start.x + deltaX, y: start.y), CGPoint(x: end.x, y: end.y - deltaY))
            } else {
                return (start, CGPoint(x: end.x + deltaX, y: end.y - deltaY))
            }
        }
    }

    func draw(_ context: CGContext) {
        context.addRects([
            CGRect(
                    x: point.x + handleWidth * (isLeft ? -1 : 1),
                    y: point.y - (isTop ? 0 : handleWidth),
                    width: handleLength * (isLeft ? 1 : -1),
                    height: handleWidth
            ),
            CGRect(
                    x: point.x - (isLeft ? handleWidth : 0),
                    y: point.y + handleWidth * (isTop ? 1 : -1),
                    width: handleWidth,
                    height: handleLength * (isTop ? -1 : 1)
            )
        ])
        context.setFillColor(yellow)
        context.drawPath(using: .fill)
    }

    var point: CGPoint {
        switch vertex {
        case .topLeft:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .topRight:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottomLeft:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .bottomRight:
            return CGPoint(x: rect.maxX, y: rect.minY)
        }
    }

    var cursor = NSCursor.pointingHand

    private var isTop: Bool {
        vertex == .topLeft || vertex == .topRight
    }

    private var isLeft: Bool {
        vertex == .topLeft || vertex == .bottomLeft
    }
}

enum CropVertex {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}