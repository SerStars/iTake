import AppKit
import SwiftUI

struct Annotation: Identifiable {
    enum Shape {
        case arrow(start: CGPoint, end: CGPoint)
        case line(start: CGPoint, end: CGPoint)
        case rectangle(rect: CGRect)
        case ellipse(rect: CGRect)
        case triangle(rect: CGRect)
        case star(rect: CGRect)
        case roundedRectangle(rect: CGRect)
        case speechBubble(rect: CGRect)
        case freehand(points: [CGPoint])
        case text(position: CGPoint, string: String)
        case step(position: CGPoint, number: Int)
        case highlighter(points: [CGPoint])
        case blur(points: [CGPoint])
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

    static func brushLineWidth(for lineWidth: CGFloat) -> CGFloat {
        6 + lineWidth * 2.5
    }

    static func enclosingRect(of points: [CGPoint]) -> CGRect {
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
    }

    var boundingRect: CGRect {
        switch shape {
        case .arrow(let start, let end), .line(let start, let end):
            return CGRect(
                x: min(start.x, end.x), y: min(start.y, end.y),
                width: abs(end.x - start.x), height: abs(end.y - start.y))
        case .rectangle(let rect), .ellipse(let rect), .triangle(let rect), .star(let rect),
            .roundedRectangle(let rect), .speechBubble(let rect):
            return rect
        case .freehand(let points):
            return Annotation.enclosingRect(of: points)
        case .highlighter(let points), .blur(let points):
            let padding = Annotation.brushLineWidth(for: lineWidth) / 2
            return Annotation.enclosingRect(of: points).insetBy(dx: -padding, dy: -padding)
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
        case .line(let start, let end):
            return .line(start: start.offsetBy(delta), end: end.offsetBy(delta))
        case .rectangle(let rect):
            return .rectangle(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .ellipse(let rect):
            return .ellipse(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .triangle(let rect):
            return .triangle(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .star(let rect):
            return .star(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .roundedRectangle(let rect):
            return .roundedRectangle(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .speechBubble(let rect):
            return .speechBubble(rect: rect.offsetBy(dx: delta.x, dy: delta.y))
        case .freehand(let points):
            return .freehand(points: points.map { $0.offsetBy(delta) })
        case .text(let position, let string):
            return .text(position: position.offsetBy(delta), string: string)
        case .step(let position, let number):
            return .step(position: position.offsetBy(delta), number: number)
        case .highlighter(let points):
            return .highlighter(points: points.map { $0.offsetBy(delta) })
        case .blur(let points):
            return .blur(points: points.map { $0.offsetBy(delta) })
        }
    }
}

extension Annotation {
    static func trianglePoints(in rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY),
        ]
    }

    static func starPoints(in rect: CGRect) -> [CGPoint] {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.382
        return (0..<10).map { i in
            let angle = (CGFloat(i) * .pi / 5) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        }
    }

    static func roundedRectCornerRadius(for rect: CGRect) -> CGFloat {
        min(20, min(rect.width, rect.height) * 0.22)
    }

    static func speechBubbleBodyRect(for rect: CGRect) -> CGRect {
        let tailHeight = rect.height * 0.22
        return CGRect(
            x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
    }

    static func speechBubbleTailPoints(in rect: CGRect) -> [CGPoint] {
        let bodyRect = speechBubbleBodyRect(for: rect)
        let tailBaseX = bodyRect.minX + bodyRect.width * 0.22
        let tailWidth = bodyRect.width * 0.18
        return [
            CGPoint(x: tailBaseX, y: bodyRect.maxY),
            CGPoint(x: tailBaseX + tailWidth, y: bodyRect.maxY),
            CGPoint(x: tailBaseX, y: rect.maxY),
        ]
    }
}

extension CGPoint {
    func offsetBy(_ delta: CGPoint) -> CGPoint {
        CGPoint(x: x + delta.x, y: y + delta.y)
    }

    func scaled(by scale: CGFloat) -> CGPoint {
        CGPoint(x: x * scale, y: y * scale)
    }
}
