import AppKit

@MainActor
final class UploadCoordinator {
    static let shared = UploadCoordinator()

    private init() {}

    /// Called after a screenshot/recording finishes saving.
    func handleCaptureCompletion(fileURL: URL) {
        guard UploadSettings.uploadAutomatically else { return }
        guard let destination = UploadDestinationStore.shared.active else {
            DebugLog.log("upload requested but no active upload destination configured")
            return
        }
        let deleteAfterUpload = !CaptureOutputSettings.saveToDisk
        Task {
            await upload(fileURL: fileURL, to: destination)
            if deleteAfterUpload {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    /// Explicit "Upload File..." menu action, uploads regardless of the on capture setting.
    func uploadFile(at fileURL: URL) {
        guard let destination = UploadDestinationStore.shared.active else {
            StatusOverlayController.shared.show(
                title: "No Uploader Selected", systemImage: "xmark.circle")
            return
        }
        Task { await upload(fileURL: fileURL, to: destination) }
    }

    private func upload(fileURL: URL, to destination: UploadDestination) async {
        // Only surface the progress overlay if the upload is still running after 2 seconds
        let progressDelayTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            UploadProgressOverlayController.shared.show()
        }

        defer {
            progressDelayTask.cancel()
            UploadProgressOverlayController.shared.hide()
        }

        do {
            let result = try await UploaderService.upload(fileURL: fileURL, to: destination) {
                fraction in
                Task { @MainActor in
                    UploadProgressOverlayController.shared.update(progress: fraction)
                }
            }

            guard let resultURL = result.fileURL else {
                DebugLog.log("upload succeeded but response URL template didn't resolve")
                StatusOverlayController.shared.show(
                    title: "Upload Failed", systemImage: "xmark.circle")
                return
            }

            CaptureHistoryStore.shared.attachUploadedURL(resultURL, forFileAt: fileURL)

            if UploadSettings.autoCopyUploadedURL {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(resultURL.absoluteString, forType: .string)
            }

            StatusOverlayController.shared.show(
                title: "Link Copied", systemImage: "link.circle.fill")
        } catch {
            DebugLog.log("upload failed: \(error)")
            StatusOverlayController.shared.show(title: "Upload Failed", systemImage: "xmark.circle")
        }
    }
}
