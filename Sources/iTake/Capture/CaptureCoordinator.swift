import AppKit

@MainActor
final class CaptureCoordinator: ObservableObject {
    func captureArea() {
        runCapture(.interactiveArea, forceEditor: false)
    }

    func captureAreaWithEditor() {
        runCapture(.interactiveArea, forceEditor: true)
    }

    func captureWindow() {
        runCapture(.interactiveWindow, forceEditor: false)
    }

    func captureFullScreen() {
        runCapture(.fullScreen, forceEditor: false)
    }

    private func runCapture(_ mode: ScreenCaptureMode, forceEditor: Bool) {
        guard ScreenCaptureService.ensurePermission() else {
            DebugLog.log("Screen Recording permission not granted, aborting capture")
            return
        }
        let url = CaptureOutput.newFileURL(label: "Screenshot")

        Task {
            do {
                guard let savedURL = try await ScreenCaptureService.capture(mode, to: url) else {
                    return
                }
                if forceEditor || AnnotationSettings.openEditorAfterCapture {
                    AnnotationEditorWindowController.shared.show(fileURL: savedURL) { finalURL in
                        guard let finalURL else { return }
                        try? CaptureOutput.finalize(fileURL: finalURL)
                    }
                } else {
                    try CaptureOutput.finalize(fileURL: savedURL)
                }
            } catch {
                DebugLog.log("capture failed: \(error)")
            }
        }
    }
}
