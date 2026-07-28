import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum AnnotationImageEffects {
    private nonisolated(unsafe) static let ciContext = CIContext()

    static func blurredImage(from image: NSImage, rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let ciImage = CIImage(cgImage: cgImage)
        let flippedRect = CGRect(
            x: rect.minX, y: CGFloat(cgImage.height) - rect.maxY, width: rect.width,
            height: rect.height
        ).intersection(ciImage.extent)
        guard !flippedRect.isEmpty else { return nil }

        let radius = max(8, min(rect.width, rect.height) / 6)

        let padded = flippedRect.insetBy(dx: -radius * 2, dy: -radius * 2).intersection(
            ciImage.extent)
        let croppedForBlur = ciImage.cropped(to: padded)

        let filter = CIFilter.gaussianBlur()
        filter.inputImage = croppedForBlur
        filter.radius = Float(radius)

        guard let output = filter.outputImage else { return nil }
        guard let outputCGImage = ciContext.createCGImage(output, from: flippedRect) else {
            return nil
        }
        return NSImage(cgImage: outputCGImage, size: rect.size)
    }
}
