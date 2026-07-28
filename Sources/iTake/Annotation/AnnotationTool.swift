import Foundation

enum AnnotationTool: String, CaseIterable, Identifiable {
    case arrow
    case line
    case rectangle
    case ellipse
    case triangle
    case star
    case roundedRectangle
    case speechBubble
    case freehand
    case eraser
    case text
    case step
    case highlighter
    case blur

    var id: String { rawValue }

    var label: String {
        switch self {
        case .arrow: return "Arrow"
        case .line: return "Line"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .triangle: return "Triangle"
        case .star: return "Star"
        case .roundedRectangle: return "Rounded Rectangle"
        case .speechBubble: return "Speech Bubble"
        case .freehand: return "Pen"
        case .eraser: return "Eraser"
        case .text: return "Text"
        case .step: return "Step"
        case .highlighter: return "Highlighter"
        case .blur: return "Blur"
        }
    }

    var systemImage: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .triangle: return "triangle"
        case .star: return "star"
        case .roundedRectangle: return "app"
        case .speechBubble: return "bubble.left"
        case .freehand: return "pencil.tip"
        case .eraser: return "eraser"
        case .text: return "textformat"
        case .step: return "number.circle.fill"
        case .highlighter: return "highlighter"
        case .blur: return "eye.slash"
        }
    }
}
