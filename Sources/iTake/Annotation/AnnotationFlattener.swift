import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

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

        case .rectangle(let rect):
            context.stroke(flip(rect, imageHeight: h), width: annotation.lineWidth)

        case .ellipse(let rect):
            context.strokeEllipse(in: flip(rect, imageHeight: h))

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
            attributed.draw(at: CGPoint(x: position.x, y: h - position.y - attributed.size().height))
            NSGraphicsContext.restoreGraphicsState()

        case .step(let position, let number):
            let diameter = Annotation.stepDiameter(for: annotation.lineWidth)
            let center = flip(position, imageHeight: h)
            let circleRect = CGRect(
                x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
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

        case .highlighter(let rect):
            context.setAlpha(0.4)
            context.fill(flip(rect, imageHeight: h))
            context.setAlpha(1)

        case .blur(let rect):
            if let blurred = blurredImage(from: sourceImage, rect: rect) {
                blurred.draw(in: flip(rect, imageHeight: h))
            }
        }
    }

    private static func blurredImage(from image: NSImage, rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let ciImage = CIImage(cgImage: cgImage)

        // CIImage's coordinate space is bottom-left-origin; rect is top-left-origin, so flip
        // before cropping.
        let flippedRect = CGRect(
            x: rect.minX, y: CGFloat(cgImage.height) - rect.maxY, width: rect.width, height: rect.height
        ).intersection(ciImage.extent)
        guard !flippedRect.isEmpty else { return nil }

        let radius = max(8, min(rect.width, rect.height) / 6)

        let padded = flippedRect.insetBy(dx: -radius * 2, dy: -radius * 2).intersection(ciImage.extent)
        let croppedForBlur = ciImage.cropped(to: padded)

        let filter = CIFilter.gaussianBlur()
        filter.inputImage = croppedForBlur
        filter.radius = Float(radius)

        guard let output = filter.outputImage else { return nil }
        let ciContext = CIContext()
        guard let outputCGImage = ciContext.createCGImage(output, from: flippedRect) else { return nil }
        return NSImage(cgImage: outputCGImage, size: rect.size)
    }
}
