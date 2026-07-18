import AppKit

@MainActor
final class OCRCoordinator: ObservableObject {
    func captureText() {
        guard ScreenCaptureService.ensurePermission() else {
            DebugLog.log("Screen Recording permission not granted, aborting OCR capture")
            return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "iTake-ocr-\(UUID().uuidString).png")

        Task {
            do {
                guard
                    let savedURL = try await ScreenCaptureService.capture(
                        .interactiveArea, to: tempURL)
                else {
                    return  // user cancelled the selection
                }
                defer { try? FileManager.default.removeItem(at: savedURL) }

                guard let data = try? Data(contentsOf: savedURL),
                    let image = NSImage(data: data),
                    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                else {
                    DebugLog.log("OCR capture: could not load captured image")
                    return
                }

                let text = try OCRService.recognizeText(in: cgImage)

                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(text, forType: .string)

                StatusOverlayController.shared.show(
                    title: "Text Copied", systemImage: "checkmark.circle.fill")
            } catch OCRServiceError.noTextFound {
                StatusOverlayController.shared.show(
                    title: "No Text Found", systemImage: "xmark.circle")
            } catch {
                DebugLog.log("OCR capture failed: \(error)")
            }
        }
    }
}
