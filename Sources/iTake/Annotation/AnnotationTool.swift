import Foundation

enum AnnotationTool: String, CaseIterable, Identifiable {
    case arrow
    case rectangle
    case ellipse
    case freehand
    case text
    case step
    case highlighter
    case blur

    var id: String { rawValue }

    var label: String {
        switch self {
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .freehand: return "Pen"
        case .text: return "Text"
        case .step: return "Step"
        case .highlighter: return "Highlighter"
        case .blur: return "Blur"
        }
    }

    var systemImage: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .freehand: return "pencil.tip"
        case .text: return "textformat"
        case .step: return "number.circle.fill"
        case .highlighter: return "highlighter"
        case .blur: return "eye.slash"
        }
    }
}
