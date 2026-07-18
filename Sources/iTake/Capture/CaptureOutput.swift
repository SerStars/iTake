import AppKit
import UniformTypeIdentifiers

enum CaptureOutput {
    /// Writes to the configured save folder when "Save to Disk" is on, otherwise to a temp
    /// location.
    /// The file still needs to exist somewhere briefly for the clipboard copy,
    /// preview thumbnail, and a possible upload, even if it isn't meant to be kept.
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

    /// screencapture already wrote the PNG to disk; this copies it to the clipboard and shows
    /// the corner preview popup.
    @MainActor
    static func finalize(fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        guard let image = NSImage(data: data) else {
            throw ScreenCaptureError.encodingFailed
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: NSPasteboard.PasteboardType(UTType.png.identifier))

        CapturePreviewWindowController.shared.show(image: image, fileURL: fileURL)
        UploadCoordinator.shared.handleCaptureCompletion(fileURL: fileURL)
    }
}
