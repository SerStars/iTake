import AppKit
import UniformTypeIdentifiers

enum CaptureOutput {
    static func newFileURL(label: String) -> URL {
        let directory: URL
        if CaptureOutputSettings.saveToDisk {
            directory = CaptureOutputSettings.saveDirectory
        } else {
            directory = FileManager.default.temporaryDirectory
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return directory.appendingPathComponent("\(label) \(formatter.string(from: Date())).png")
    }

    @MainActor
    static func finalize(fileURL: URL, showPreview: Bool = true) async throws {
        let data = try Data(contentsOf: fileURL)
        guard let image = NSImage(data: data) else {
            throw ScreenCaptureError.encodingFailed
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: NSPasteboard.PasteboardType(UTType.png.identifier))

        if showPreview {
            CapturePreviewWindowController.shared.show(image: image, fileURL: fileURL)
        }

        await CaptureHistoryStore.shared.add(fileURL: fileURL, kind: .screenshot)
        UploadCoordinator.shared.handleCaptureCompletion(fileURL: fileURL)
    }
}
