import AppKit

@MainActor
final class CaptureCoordinator: ObservableObject {
    func captureArea() {
        runCapture(.interactiveArea)
    }

    func captureWindow() {
        runCapture(.interactiveWindow)
    }

    func captureFullScreen() {
        runCapture(.fullScreen)
    }

    private func runCapture(_ mode: ScreenCaptureMode) {
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
                try CaptureOutput.finalize(fileURL: savedURL)
            } catch {
                DebugLog.log("capture failed: \(error)")
            }
        }
    }
}
