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
            let succeeded = await upload(fileURL: fileURL, to: destination)
            guard deleteAfterUpload else { return }
            if succeeded {
                try? FileManager.default.removeItem(at: fileURL)
            } else {
                offerToSaveToDisk(tempFileURL: fileURL)
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

    private func offerToSaveToDisk(tempFileURL: URL) {
        let alert = NSAlert()
        alert.messageText = "Upload Failed"
        alert.informativeText =
            "The upload didn't go through. Save this capture to disk instead of losing it?"
        alert.addButton(withTitle: "Save to Disk")
        alert.addButton(withTitle: "Discard")
        NSApp.activate(ignoringOtherApps: true)

        guard alert.runModal() == .alertFirstButtonReturn else {
            try? FileManager.default.removeItem(at: tempFileURL)
            return
        }

        let destinationURL = CaptureOutputSettings.saveDirectory.appendingPathComponent(
            tempFileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: tempFileURL, to: destinationURL)
            CaptureHistoryStore.shared.updateFileURL(from: tempFileURL, to: destinationURL)
            StatusOverlayController.shared.show(
                title: "Saved to Disk", systemImage: "externaldrive.badge.checkmark")
        } catch {
            DebugLog.log("failed to save capture to disk after upload failure: \(error)")
            StatusOverlayController.shared.show(title: "Save Failed", systemImage: "xmark.circle")
        }
    }

    @discardableResult
    private func upload(fileURL: URL, to destination: UploadDestination) async -> Bool {
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
                    title: "Upload Failed",
                    subtitle: "File uploaded, but couldn't find a link in the response.",
                    systemImage: "xmark.circle")
                return false
            }

            CaptureHistoryStore.shared.attachUploadedURL(resultURL, forFileAt: fileURL)

            if UploadSettings.autoCopyUploadedURL {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(resultURL.absoluteString, forType: .string)
            }

            StatusOverlayController.shared.show(
                title: "Link Copied", systemImage: "link.circle.fill")
            return true
        } catch {
            DebugLog.log("upload failed: \(error)")
            StatusOverlayController.shared.show(title: "Upload Failed", systemImage: "xmark.circle")
            return false
        }
    }
}
