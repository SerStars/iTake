import AppKit

enum AnnotationFlattener {
    static func flatten(image: NSImage, annotations: [Annotation]) -> NSImage {
        guard !annotations.isEmpty else { return image }

        let size = image.size
        let result = NSImage(size: size)
        result.lockFocus()
        defer { result.unlockFocus() }

        image.draw(in: CGRect(origin: .zero, size: size))

        guard let context = NSGraphicsContext.current?.cgContext else { return result }
        for annotation in annotations {
            draw(annotation, in: context, imageSize: size, sourceImage: image)
        }

        return result
    }

    private static func flip(_ point: CGPoint, imageHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: imageHeight - point.y)
    }

    private static func flip(_ rect: CGRect, imageHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: imageHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    private static func strokeClosedPath(
        _ points: [CGPoint], in context: CGContext, imageHeight: CGFloat
    ) {
        guard let first = points.first else { return }
        context.move(to: flip(first, imageHeight: imageHeight))
        for point in points.dropFirst() {
            context.addLine(to: flip(point, imageHeight: imageHeight))
        }
        context.closePath()
        context.strokePath()
    }

    private static func draw(
        _ annotation: Annotation, in context: CGContext, imageSize: CGSize, sourceImage: NSImage
    ) {
        let h = imageSize.height
        let nsColor = NSColor(annotation.color)
        context.setStrokeColor(nsColor.cgColor)
        context.setFillColor(nsColor.cgColor)
        context.setLineWidth(annotation.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch annotation.shape {
        case .arrow(let start, let end):
            let p1 = flip(start, imageHeight: h)
            let p2 = flip(end, imageHeight: h)
            context.move(to: p1)
            context.addLine(to: p2)
            context.strokePath()

            let angle = atan2(p2.y - p1.y, p2.x - p1.x)
            let headLength = max(10, annotation.lineWidth * 3)
            let headAngle: CGFloat = .pi / 7
            context.move(to: p2)
            context.addLine(
                to: CGPoint(
                    x: p2.x - headLength * cos(angle - headAngle),
                    y: p2.y - headLength * sin(angle - headAngle)))
            context.move(to: p2)
            context.addLine(
                to: CGPoint(
                    x: p2.x - headLength * cos(angle + headAngle),
                    y: p2.y - headLength * sin(angle + headAngle)))
            context.strokePath()

        case .line(let start, let end):
            context.move(to: flip(start, imageHeight: h))
            context.addLine(to: flip(end, imageHeight: h))
            context.strokePath()

        case .rectangle(let rect):
            context.stroke(flip(rect, imageHeight: h), width: annotation.lineWidth)

        case .ellipse(let rect):
            context.strokeEllipse(in: flip(rect, imageHeight: h))

        case .triangle(let rect):
            strokeClosedPath(Annotation.trianglePoints(in: rect), in: context, imageHeight: h)

        case .star(let rect):
            strokeClosedPath(Annotation.starPoints(in: rect), in: context, imageHeight: h)

        case .roundedRectangle(let rect):
            let cornerRadius = Annotation.roundedRectCornerRadius(for: rect)
            context.addPath(
                CGPath(
                    roundedRect: flip(rect, imageHeight: h), cornerWidth: cornerRadius,
                    cornerHeight: cornerRadius, transform: nil))
            context.strokePath()

        case .speechBubble(let rect):
            let bodyRect = Annotation.speechBubbleBodyRect(for: rect)
            let cornerRadius = Annotation.roundedRectCornerRadius(for: bodyRect)
            context.addPath(
                CGPath(
                    roundedRect: flip(bodyRect, imageHeight: h), cornerWidth: cornerRadius,
                    cornerHeight: cornerRadius, transform: nil))
            context.strokePath()
            strokeClosedPath(
                Annotation.speechBubbleTailPoints(in: rect), in: context, imageHeight: h)

        case .freehand(let points):
            guard points.count > 1 else { return }
            context.move(to: flip(points[0], imageHeight: h))
            for point in points.dropFirst() {
                context.addLine(to: flip(point, imageHeight: h))
            }
            context.strokePath()

        case .text(let position, let string):
            let fontSize = Annotation.textFontSize(for: annotation.lineWidth)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: nsColor,
            ]
            let attributed = NSAttributedString(string: string, attributes: attributes)
            NSGraphicsContext.saveGraphicsState()
            attributed.draw(
                at: CGPoint(x: position.x, y: h - position.y - attributed.size().height))
            NSGraphicsContext.restoreGraphicsState()

        case .step(let position, let number):
            let diameter = Annotation.stepDiameter(for: annotation.lineWidth)
            let center = flip(position, imageHeight: h)
            let circleRect = CGRect(
                x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter,
                height: diameter)
            context.fillEllipse(in: circleRect)

            let numberAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: diameter * 0.5, weight: .bold),
                .foregroundColor: NSColor.white,
            ]
            let numberString = NSAttributedString(string: "\(number)", attributes: numberAttributes)
            let textSize = numberString.size()
            NSGraphicsContext.saveGraphicsState()
            numberString.draw(
                at: CGPoint(x: center.x - textSize.width / 2, y: center.y - textSize.height / 2))
            NSGraphicsContext.restoreGraphicsState()

        case .highlighter(let points):
            guard points.count > 1 else { return }
            context.setAlpha(0.4)
            context.setLineWidth(Annotation.brushLineWidth(for: annotation.lineWidth))
            context.move(to: flip(points[0], imageHeight: h))
            for point in points.dropFirst() {
                context.addLine(to: flip(point, imageHeight: h))
            }
            context.strokePath()
            context.setAlpha(1)

        case .blur(let points):
            guard points.count > 1 else { return }
            let padding = Annotation.brushLineWidth(for: annotation.lineWidth) / 2
            let modelRect = Annotation.enclosingRect(of: points).insetBy(
                dx: -padding, dy: -padding)
            guard
                let blurred = AnnotationImageEffects.blurredImage(
                    from: sourceImage, rect: modelRect)
            else { return }

            context.saveGState()
            let flippedPoints = points.map { flip($0, imageHeight: h) }
            context.move(to: flippedPoints[0])
            for point in flippedPoints.dropFirst() {
                context.addLine(to: point)
            }
            context.setLineWidth(Annotation.brushLineWidth(for: annotation.lineWidth))
            context.replacePathWithStrokedPath()
            context.clip()
            blurred.draw(in: flip(modelRect, imageHeight: h))
            context.restoreGState()
        }
    }
}
