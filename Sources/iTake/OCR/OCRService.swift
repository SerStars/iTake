import Vision

enum OCRServiceError: Error {
    case noTextFound
}

enum OCRService {
    static func recognizeText(in image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        // Vision doesn't guarantee reading order, so approximate top-to-bottom, left-to-right
        // using each observation's normalized bounding box (origin bottom-left).
        let sorted = observations.sorted { lhs, rhs in
            if abs(lhs.boundingBox.origin.y - rhs.boundingBox.origin.y) > 0.01 {
                return lhs.boundingBox.origin.y > rhs.boundingBox.origin.y
            }
            return lhs.boundingBox.origin.x < rhs.boundingBox.origin.x
        }

        let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
        guard !lines.isEmpty else { throw OCRServiceError.noTextFound }
        return lines.joined(separator: "\n")
    }
}
