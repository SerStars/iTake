import AppKit
import UniformTypeIdentifiers

@MainActor
enum RecentCaptureActions {
    static func copy(_ record: CaptureRecord) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch record.kind {
        case .screenshot:
            if let data = try? Data(contentsOf: record.fileURL) {
                pasteboard.setData(
                    data, forType: NSPasteboard.PasteboardType(UTType.png.identifier))
            }
        case .recording:
            pasteboard.writeObjects([record.fileURL as NSURL])
        }
    }

    static func copyLink(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.absoluteString, forType: .string)
        StatusOverlayController.shared.show(title: "Link Copied", systemImage: "link.circle.fill")
    }

    static func hasLocalFile(_ record: CaptureRecord) -> Bool {
        FileManager.default.fileExists(atPath: record.fileURL.path)
    }

    static func delete(_ record: CaptureRecord) {
        let hadFile = hasLocalFile(record)
        let wasUploaded = record.uploadedURL != nil
        CaptureHistoryStore.shared.remove(record)
        StatusOverlayController.shared.show(
            title: hadFile ? "Deleted" : "Removed",
            subtitle: wasUploaded ? "Still available at the upload destination" : nil,
            systemImage: hadFile ? "trash" : "xmark.circle"
        )
    }
}
