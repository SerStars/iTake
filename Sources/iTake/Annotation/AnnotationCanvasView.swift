import AppKit
import SwiftUI

struct AnnotationCanvasView: View {
    let image: NSImage
    let annotations: [Annotation]
    let selectedTool: AnnotationTool
    let selectedColor: Color
    let lineWidth: CGFloat
    @Binding var zoomLevel: CGFloat
    @Binding var selectedAnnotationID: UUID?
    let editingAnnotation: Annotation?
    let onAnnotationAdded: (Annotation) -> Void
    let onAnnotationMoved: (UUID, CGPoint) -> Void
    let onAnnotationEdited: (UUID, Annotation.Shape, Color, CGFloat) -> Void
    let onAnnotationDeleted: (UUID) -> Void
    let onEraseGestureBegan: () -> Void
    let onAnnotationErased: (UUID) -> Void
    let onPathAnnotationErased: (UUID, [Annotation.Shape]) -> Void
    let onTextEditRequested: (Annotation) -> Void
    let onEditCancelled: () -> Void

    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var freehandPoints: [CGPoint] = []
    @State private var pendingTextPosition: CGPoint?
    @State private var pendingTextString = ""
    @State private var pendingStepPosition: CGPoint?
    @State private var pendingStepNumberText = ""
    @FocusState private var isStepFieldFocused: Bool
    @FocusState private var isCanvasFocused: Bool
    @State private var draggingAnnotationID: UUID?
    @State private var dragLastPoint: CGPoint = .zero
    @State private var wasAlreadySelected = false
    @State private var isErasing = false
    @State private var eraserCursorPoint: CGPoint?
    @State private var magnifyStartZoom: CGFloat?

    private static let minShapeSize: CGFloat = 4
    private static let hitTestPadding: CGFloat = 6
    private static let zoomRange: ClosedRange<CGFloat> = 0.25...4
    private static let margin: CGFloat = 28

    private var eraserRadius: CGFloat {
        max(8, lineWidth * 2.5)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = magnifyStartZoom ?? zoomLevel
                magnifyStartZoom = start
                zoomLevel = min(
                    Self.zoomRange.upperBound,
                    max(Self.zoomRange.lowerBound, start * value.magnification))
            }
            .onEnded { _ in
                magnifyStartZoom = nil
            }
    }

    var body: some View {
        GeometryReader { geo in
            let availableSize = CGSize(
                width: max(geo.size.width - Self.margin * 2, 1),
                height: max(geo.size.height - Self.margin * 2, 1))
            let fitScale = min(
                availableSize.width / image.size.width, availableSize.height / image.size.height)
            let scale = fitScale * zoomLevel
            let displaySize = CGSize(
                width: image.size.width * scale, height: image.size.height * scale)

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    Canvas { context, _ in
                        context.draw(
                            Image(nsImage: image), in: CGRect(origin: .zero, size: displaySize))
                        for annotation in annotations {
                            if annotation.id == editingAnnotation?.id { continue }
                            draw(annotation, in: context, scale: scale)
                            if annotation.id == selectedAnnotationID {
                                drawSelectionBox(for: annotation, in: context, scale: scale)
                            }
                        }
                        if let preview = previewAnnotation() {
                            draw(preview, in: context, scale: scale)
                        }
                        if selectedTool == .eraser, let eraserCursorPoint {
                            drawEraserCursor(at: eraserCursorPoint, in: context, scale: scale)
                        }
                    }
                    .frame(width: displaySize.width, height: displaySize.height)
                    .contentShape(Rectangle())
                    .focusable()
                    .focusEffectDisabled()
                    .focused($isCanvasFocused)
                    .onDeleteCommand {
                        if let selectedAnnotationID {
                            onAnnotationDeleted(selectedAnnotationID)
                            self.selectedAnnotationID = nil
                        }
                    }
                    .gesture(drawGesture(scale: scale))

                    if let pendingTextPosition {
                        ZStack(alignment: .topLeading) {
                            if pendingTextString.isEmpty {
                                Text("Type here…")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.32))
                                    .padding(.leading, 10)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                            AnnotationTextEditor(
                                text: $pendingTextString,
                                font: .systemFont(
                                    ofSize: Annotation.textFontSize(for: lineWidth),
                                    weight: .semibold),
                                color: NSColor(selectedColor),
                                onCommit: commitText,
                                onCancel: cancelTextEditing
                            )
                        }
                        .frame(width: 240, height: 64)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.regularMaterial))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8).stroke(
                                Color.primary.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                        .offset(x: pendingTextPosition.x * scale, y: pendingTextPosition.y * scale)
                    }

                    if let pendingStepPosition {
                        TextField("#", text: $pendingStepNumberText)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14, weight: .bold))
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.regularMaterial))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(
                                    Color.primary.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                            .frame(width: 44)
                            .position(
                                x: pendingStepPosition.x * scale, y: pendingStepPosition.y * scale
                            )
                            .focused($isStepFieldFocused)
                            .onAppear { isStepFieldFocused = true }
                            .onSubmit { commitStep() }
                            .onExitCommand { self.pendingStepPosition = nil }
                    }
                }
                .frame(
                    width: max(displaySize.width + Self.margin * 2, geo.size.width),
                    height: max(displaySize.height + Self.margin * 2, geo.size.height)
                )
            }
            .simultaneousGesture(magnifyGesture)
            .onAppear { syncEditingState() }
            .onChange(of: editingAnnotation?.id) { _, _ in syncEditingState() }
        }
    }

    private func syncEditingState() {
        guard let editingAnnotation, case .text(let position, let string) = editingAnnotation.shape
        else { return }
        pendingTextPosition = position
        pendingTextString = string
    }

    private func drawGesture(scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let point = CGPoint(x: value.location.x / scale, y: value.location.y / scale)

                if selectedTool == .eraser {
                    isCanvasFocused = true
                    if !isErasing {
                        isErasing = true
                        onEraseGestureBegan()
                    }
                    eraserCursorPoint = point
                    applyErase(at: point)
                    return
                }

                if dragStart == nil, draggingAnnotationID == nil, freehandPoints.isEmpty {
                    isCanvasFocused = true
                    if let hit = annotation(at: point) {
                        wasAlreadySelected = selectedAnnotationID == hit.id
                        draggingAnnotationID = hit.id
                        selectedAnnotationID = hit.id
                        dragLastPoint = point
                        return
                    }
                }

                if let draggingAnnotationID {
                    let delta = CGPoint(x: point.x - dragLastPoint.x, y: point.y - dragLastPoint.y)
                    onAnnotationMoved(draggingAnnotationID, delta)
                    dragLastPoint = point
                    return
                }

                if selectedTool == .freehand || selectedTool == .highlighter
                    || selectedTool == .blur
                {
                    if dragStart == nil {
                        dragStart = point
                        freehandPoints = [point]
                    } else {
                        freehandPoints.append(point)
                    }
                } else {
                    if dragStart == nil { dragStart = point }
                    dragCurrent = point
                }
            }
            .onEnded { value in
                defer {
                    dragStart = nil
                    dragCurrent = nil
                    freehandPoints = []
                    isErasing = false
                    eraserCursorPoint = nil
                }

                if selectedTool == .eraser { return }

                if let draggingAnnotationID {
                    let moved = hypot(value.translation.width, value.translation.height) > 3
                    if !moved, wasAlreadySelected,
                        let annotation = annotations.first(where: { $0.id == draggingAnnotationID }
                        ),
                        case .text = annotation.shape
                    {
                        onTextEditRequested(annotation)
                    }
                    self.draggingAnnotationID = nil
                    return
                }

                selectedAnnotationID = nil
                let endPoint = CGPoint(x: value.location.x / scale, y: value.location.y / scale)
                commit(endPoint: endPoint)
            }
    }

    private func annotation(at point: CGPoint) -> Annotation? {
        for annotation in annotations.reversed() {
            let padding = Self.hitTestPadding + annotation.lineWidth / 2
            switch annotation.shape {
            case .arrow(let start, let end), .line(let start, let end):
                if distanceToSegment(point, start, end) <= padding { return annotation }
            case .freehand(let points):
                guard points.count > 1 else { continue }
                for i in 0..<(points.count - 1) {
                    if distanceToSegment(point, points[i], points[i + 1]) <= padding {
                        return annotation
                    }
                }
            case .highlighter(let points), .blur(let points):
                guard points.count > 1 else { continue }
                let brushPadding =
                    Self.hitTestPadding + Annotation.brushLineWidth(for: annotation.lineWidth) / 2
                for i in 0..<(points.count - 1) {
                    if distanceToSegment(point, points[i], points[i + 1]) <= brushPadding {
                        return annotation
                    }
                }
            default:
                if annotation.boundingRect.insetBy(
                    dx: -Self.hitTestPadding, dy: -Self.hitTestPadding
                )
                .contains(point) {
                    return annotation
                }
            }
        }
        return nil
    }

    private func distanceToSegment(_ point: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return distance(point, a) }
        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared))
        let projection = CGPoint(x: a.x + t * dx, y: a.y + t * dy)
        return distance(point, projection)
    }

    private func commit(endPoint: CGPoint) {
        switch selectedTool {
        case .text:
            pendingTextPosition = endPoint
            pendingTextString = ""

        case .step:
            pendingStepPosition = endPoint
            pendingStepNumberText = "\(nextStepNumber)"

        case .freehand, .highlighter, .blur:
            guard freehandPoints.count > 1 else { return }
            onAnnotationAdded(
                Annotation(
                    shape: pathAnnotationShape(for: selectedTool, points: freehandPoints),
                    color: selectedColor, lineWidth: lineWidth))

        case .eraser:
            return

        case .arrow, .line:
            guard let start = dragStart, distance(start, endPoint) > Self.minShapeSize else {
                return
            }
            let shape: Annotation.Shape =
                selectedTool == .arrow
                ? .arrow(start: start, end: endPoint) : .line(start: start, end: endPoint)
            onAnnotationAdded(Annotation(shape: shape, color: selectedColor, lineWidth: lineWidth))

        case .rectangle, .ellipse, .triangle, .star, .roundedRectangle, .speechBubble:
            guard let start = dragStart else { return }
            let rect = rect(from: start, to: endPoint)
            guard rect.width > Self.minShapeSize, rect.height > Self.minShapeSize else { return }
            guard let shape = rectAnnotationShape(for: selectedTool, rect: rect) else { return }
            onAnnotationAdded(Annotation(shape: shape, color: selectedColor, lineWidth: lineWidth))
        }
    }

    private func rectAnnotationShape(for tool: AnnotationTool, rect: CGRect) -> Annotation.Shape? {
        switch tool {
        case .rectangle: return .rectangle(rect: rect)
        case .ellipse: return .ellipse(rect: rect)
        case .triangle: return .triangle(rect: rect)
        case .star: return .star(rect: rect)
        case .roundedRectangle: return .roundedRectangle(rect: rect)
        case .speechBubble: return .speechBubble(rect: rect)
        default: return nil
        }
    }

    private func pathAnnotationShape(for tool: AnnotationTool, points: [CGPoint])
        -> Annotation.Shape
    {
        switch tool {
        case .highlighter: return .highlighter(points: points)
        case .blur: return .blur(points: points)
        default: return .freehand(points: points)
        }
    }

    private func pathAnnotationShape(matching shape: Annotation.Shape, points: [CGPoint])
        -> Annotation.Shape
    {
        switch shape {
        case .highlighter: return .highlighter(points: points)
        case .blur: return .blur(points: points)
        default: return .freehand(points: points)
        }
    }

    private func applyErase(at point: CGPoint) {
        let radius = eraserRadius
        for annotation in annotations {
            switch annotation.shape {
            case .freehand(let points), .highlighter(let points), .blur(let points):
                guard points.contains(where: { distance($0, point) <= radius }) else { continue }
                let runs = splitPoints(points, erasingAt: point, radius: radius)
                let newShapes = runs.map {
                    pathAnnotationShape(matching: annotation.shape, points: $0)
                }
                onPathAnnotationErased(annotation.id, newShapes)
            default:
                if eraserHits(annotation, at: point, radius: radius) {
                    onAnnotationErased(annotation.id)
                }
            }
        }
    }

    private func eraserHits(_ annotation: Annotation, at point: CGPoint, radius: CGFloat) -> Bool {
        switch annotation.shape {
        case .arrow(let start, let end), .line(let start, let end):
            return distanceToSegment(point, start, end) <= radius + annotation.lineWidth / 2
        default:
            return annotation.boundingRect.insetBy(dx: -radius, dy: -radius).contains(point)
        }
    }

    private func splitPoints(_ points: [CGPoint], erasingAt center: CGPoint, radius: CGFloat)
        -> [[CGPoint]]
    {
        var runs: [[CGPoint]] = []
        var current: [CGPoint] = []
        for point in points {
            if distance(point, center) <= radius {
                if current.count > 1 { runs.append(current) }
                current = []
            } else {
                current.append(point)
            }
        }
        if current.count > 1 { runs.append(current) }
        return runs
    }

    private func commitText() {
        guard let position = pendingTextPosition else { return }
        let trimmed = pendingTextString.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editingAnnotation {
            if !trimmed.isEmpty {
                onAnnotationEdited(
                    editingAnnotation.id, .text(position: position, string: trimmed), selectedColor,
                    lineWidth)
            } else {
                onEditCancelled()
            }
        } else if !trimmed.isEmpty {
            onAnnotationAdded(
                Annotation(
                    shape: .text(position: position, string: trimmed), color: selectedColor,
                    lineWidth: lineWidth))
        }

        pendingTextPosition = nil
        pendingTextString = ""
    }

    private func cancelTextEditing() {
        let hadEditingAnnotation = editingAnnotation != nil
        pendingTextPosition = nil
        pendingTextString = ""
        if hadEditingAnnotation {
            onEditCancelled()
        }
    }

    private var nextStepNumber: Int {
        annotations.filter {
            if case .step = $0.shape { return true }
            return false
        }.count + 1
    }

    private func commitStep() {
        guard let position = pendingStepPosition else { return }
        let trimmed = pendingStepNumberText.trimmingCharacters(in: .whitespaces)
        let number = Int(trimmed) ?? nextStepNumber
        onAnnotationAdded(
            Annotation(
                shape: .step(position: position, number: number), color: selectedColor,
                lineWidth: lineWidth))
        pendingStepPosition = nil
        pendingStepNumberText = ""
    }

    private func previewAnnotation() -> Annotation? {
        guard let start = dragStart else { return nil }
        switch selectedTool {
        case .freehand, .highlighter, .blur:
            guard freehandPoints.count > 1 else { return nil }
            return Annotation(
                shape: pathAnnotationShape(for: selectedTool, points: freehandPoints),
                color: selectedColor, lineWidth: lineWidth)
        case .text, .step, .eraser:
            return nil
        case .arrow, .line:
            guard let current = dragCurrent else { return nil }
            let shape: Annotation.Shape =
                selectedTool == .arrow
                ? .arrow(start: start, end: current) : .line(start: start, end: current)
            return Annotation(shape: shape, color: selectedColor, lineWidth: lineWidth)
        case .rectangle, .ellipse, .triangle, .star, .roundedRectangle, .speechBubble:
            guard let current = dragCurrent else { return nil }
            guard
                let shape = rectAnnotationShape(
                    for: selectedTool, rect: rect(from: start, to: current))
            else { return nil }
            return Annotation(shape: shape, color: selectedColor, lineWidth: lineWidth)
        }
    }

    private func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y),
            width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }

    private func draw(_ annotation: Annotation, in context: GraphicsContext, scale: CGFloat) {
        let strokeStyle = StrokeStyle(
            lineWidth: annotation.lineWidth * scale, lineCap: .round, lineJoin: .round)

        switch annotation.shape {
        case .arrow(let start, let end):
            let p1 = CGPoint(x: start.x * scale, y: start.y * scale)
            let p2 = CGPoint(x: end.x * scale, y: end.y * scale)
            var path = Path()
            path.move(to: p1)
            path.addLine(to: p2)
            let angle = atan2(p2.y - p1.y, p2.x - p1.x)
            let headLength = max(10, annotation.lineWidth * scale * 3)
            let headAngle: CGFloat = .pi / 7
            path.move(to: p2)
            path.addLine(
                to: CGPoint(
                    x: p2.x - headLength * cos(angle - headAngle),
                    y: p2.y - headLength * sin(angle - headAngle)))
            path.move(to: p2)
            path.addLine(
                to: CGPoint(
                    x: p2.x - headLength * cos(angle + headAngle),
                    y: p2.y - headLength * sin(angle + headAngle)))
            context.stroke(path, with: .color(annotation.color), style: strokeStyle)

        case .line(let start, let end):
            var path = Path()
            path.move(to: CGPoint(x: start.x * scale, y: start.y * scale))
            path.addLine(to: CGPoint(x: end.x * scale, y: end.y * scale))
            context.stroke(path, with: .color(annotation.color), style: strokeStyle)

        case .rectangle(let rect):
            context.stroke(
                Path(scaledRect(rect, scale: scale)), with: .color(annotation.color),
                style: strokeStyle)

        case .ellipse(let rect):
            context.stroke(
                Path(ellipseIn: scaledRect(rect, scale: scale)), with: .color(annotation.color),
                style: strokeStyle)

        case .triangle(let rect):
            var path = Path()
            path.addLines(Annotation.trianglePoints(in: rect).map { $0.scaled(by: scale) })
            path.closeSubpath()
            context.stroke(path, with: .color(annotation.color), style: strokeStyle)

        case .star(let rect):
            var path = Path()
            path.addLines(Annotation.starPoints(in: rect).map { $0.scaled(by: scale) })
            path.closeSubpath()
            context.stroke(path, with: .color(annotation.color), style: strokeStyle)

        case .roundedRectangle(let rect):
            let cornerRadius = Annotation.roundedRectCornerRadius(for: rect) * scale
            context.stroke(
                Path(roundedRect: scaledRect(rect, scale: scale), cornerRadius: cornerRadius),
                with: .color(annotation.color), style: strokeStyle)

        case .speechBubble(let rect):
            let bodyRect = Annotation.speechBubbleBodyRect(for: rect)
            let cornerRadius = Annotation.roundedRectCornerRadius(for: bodyRect) * scale
            context.stroke(
                Path(roundedRect: scaledRect(bodyRect, scale: scale), cornerRadius: cornerRadius),
                with: .color(annotation.color), style: strokeStyle)
            var tailPath = Path()
            tailPath.addLines(
                Annotation.speechBubbleTailPoints(in: rect).map { $0.scaled(by: scale) })
            tailPath.closeSubpath()
            context.stroke(tailPath, with: .color(annotation.color), style: strokeStyle)

        case .freehand(let points):
            guard points.count > 1 else { return }
            var path = Path()
            path.move(to: CGPoint(x: points[0].x * scale, y: points[0].y * scale))
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * scale, y: point.y * scale))
            }
            context.stroke(path, with: .color(annotation.color), style: strokeStyle)

        case .text(let position, let string):
            let fontSize = Annotation.textFontSize(for: annotation.lineWidth)
            let resolved = context.resolve(
                Text(string).font(.system(size: fontSize * scale, weight: .semibold))
                    .foregroundColor(annotation.color))
            context.draw(
                resolved, at: CGPoint(x: position.x * scale, y: position.y * scale),
                anchor: .topLeading)

        case .step(let position, let number):
            let diameter = Annotation.stepDiameter(for: annotation.lineWidth) * scale
            let center = CGPoint(x: position.x * scale, y: position.y * scale)
            let circleRect = CGRect(
                x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter,
                height: diameter)
            context.fill(Path(ellipseIn: circleRect), with: .color(annotation.color))
            let resolved = context.resolve(
                Text(String(number)).font(.system(size: diameter * 0.5, weight: .bold))
                    .foregroundColor(.white))
            context.draw(resolved, at: center, anchor: .center)

        case .highlighter(let points):
            guard points.count > 1 else { return }
            var path = Path()
            path.move(to: points[0].scaled(by: scale))
            for point in points.dropFirst() {
                path.addLine(to: point.scaled(by: scale))
            }
            let brushWidth = Annotation.brushLineWidth(for: annotation.lineWidth) * scale
            context.stroke(
                path, with: .color(annotation.color.opacity(0.4)),
                style: StrokeStyle(lineWidth: brushWidth, lineCap: .round, lineJoin: .round))

        case .blur(let points):
            guard points.count > 1 else { return }
            let padding = Annotation.brushLineWidth(for: annotation.lineWidth) / 2
            let modelRect = Annotation.enclosingRect(of: points).insetBy(dx: -padding, dy: -padding)
            guard let blurred = AnnotationImageEffects.blurredImage(from: image, rect: modelRect)
            else { return }

            var strokePath = Path()
            strokePath.move(to: points[0].scaled(by: scale))
            for point in points.dropFirst() {
                strokePath.addLine(to: point.scaled(by: scale))
            }
            let brushWidth = Annotation.brushLineWidth(for: annotation.lineWidth) * scale
            let thickPath = strokePath.strokedPath(
                StrokeStyle(lineWidth: brushWidth, lineCap: .round, lineJoin: .round))

            context.drawLayer { layerContext in
                layerContext.clip(to: thickPath)
                layerContext.draw(Image(nsImage: blurred), in: scaledRect(modelRect, scale: scale))
            }
        }
    }

    private func drawSelectionBox(
        for annotation: Annotation, in context: GraphicsContext, scale: CGFloat
    ) {
        let scaledRect = scaledRect(annotation.boundingRect, scale: scale).insetBy(dx: -6, dy: -6)
        context.stroke(
            Path(roundedRect: scaledRect, cornerRadius: 3),
            with: .color(.accentColor),
            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
    }

    private func drawEraserCursor(at point: CGPoint, in context: GraphicsContext, scale: CGFloat) {
        let radius = eraserRadius * scale
        let center = point.scaled(by: scale)
        let circleRect = CGRect(
            x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(
            Path(ellipseIn: circleRect), with: .color(.accentColor),
            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
    }

    private func scaledRect(_ rect: CGRect, scale: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale,
            height: rect.height * scale)
    }
}
