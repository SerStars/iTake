import AppKit
import SwiftUI

struct Annotation: Identifiable {
    enum Shape {
        case arrow(start: CGPoint, end: CGPoint)
        case rectangle(rect: CGRect)
        case ellipse(rect: CGRect)
        case freehand(points: [CGPoint])
        case text(position: CGPoint, string: String)
        case step(position: CGPoint, number: Int)
        case highlighter(rect: CGRect)
        case blur(rect: CGRect)
    }

    let id = UUID()
    var shape: Shape
    var color: Color
    var lineWidth: CGFloat
}

extension Annotation {
    static func textFontSize(for lineWidth: CGFloat) -> CGFloat {
        10 + lineWidth * 3
    }

    static func stepDiameter(for lineWidth: CGFloat) -> CGFloat {
        16 + lineWidth * 4
    }

    var boundingRect: CGRect {
        switch shape {
        case .arrow(let start, let end):
            return CGRect(
                x: min(start.x, end.x), y: min(start.y, end.y),
                width: abs(end.x - start.x), height: abs(end.y - start.y))
        case .rectangle(let rect), .ellipse(let rect), .highlighter(let rect), .blur(let rect):
            return rect
        case .freehand(let points):
            guard let first = points.first else { return .zero }
            var minX = first.x
            var minY = first.y
            var maxX = first.x
            var maxY = first.y
            for point in points {
                minX = min(minX, point.x)
                minY = min(minY, point.y)
                maxX = max(maxX, point.x)
                maxY = max(maxY, point.y)
            }
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        case .text(let position, let string):
            let fontSize = Annotation.textFontSize(for: lineWidth)
            let size = (string as NSString).size(
                withAttributes: [.font: NSFont.systemFont(ofSize: fontSize, weight: .semibold)])
            return CGRect(
                x: position.x, y: position.y, width: max(size.width, 10),
                height: max(size.height, 10))
        case .step(let position, _):
            let diameter = Annotation.stepDiameter(for: lineWidth)
            return CGRect(
                x: position.x - diameter / 2, y: position.y - diameter / 2, width: diameter,
                height: diameter)
        }
    }
}

extension Annotation.Shape {
    func translated(by delta: CGPoint) -> Annotation.Shape {
        switch self {
        case .arrow(let start, let end):
            return .arrow(start: start.offsetBy(delta), end: end.offsetBy(delta))
        case .rectangle(let rect):
            return .rectangle(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .ellipse(let rect):
            return .ellipse(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .freehand(let points):
            return .freehand(points: points.map { $0.offsetBy(delta) })
        case .text(let position, let string):
            return .text(position: position.offsetBy(delta), string: string)
        case .step(let position, let number):
            return .step(position: position.offsetBy(delta), number: number)
        case .highlighter(let rect):
            return .highlighter(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .blur(let rect):
            return .blur(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        }
    }
}

extension CGPoint {
    func offsetBy(_ delta: CGPoint) -> CGPoint {
        CGPoint(x: x + delta.x, y: y + delta.y)
    }
}
