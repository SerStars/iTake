import AppKit
import SwiftUI

@MainActor
final class AnnotationEditorWindowController {
    static let shared = AnnotationEditorWindowController()

    private var window: NSWindow?

    private init() {}

    /// onFinish receives nil when cancelled
    func show(fileURL: URL, onFinish: @escaping (URL?) -> Void) {
        guard let image = NSImage(contentsOf: fileURL) else {
            onFinish(fileURL)
            return
        }

        window?.orderOut(nil)
        window = nil

        let editorView = AnnotationEditorView(
            image: image,
            onSave: { [weak self] flattenedImage in
                self?.writeAndFinish(flattenedImage, to: fileURL, onFinish: onFinish)
            },
            onCancel: { [weak self] in
                self?.close()
                try? FileManager.default.removeItem(at: fileURL)
                onFinish(nil)
            }
        )

        let hosting = NSHostingController(rootView: editorView)
        let newWindow = NSWindow(contentViewController: hosting)
        newWindow.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        newWindow.title = "Edit Screenshot"
        newWindow.isReleasedWhenClosed = false
        newWindow.setContentSize(NSSize(width: 900, height: 650))
        newWindow.center()
        window = newWindow

        NSApp.activate(ignoringOtherApps: true)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.orderFrontRegardless()
    }

    private func writeAndFinish(
        _ image: NSImage, to fileURL: URL, onFinish: @escaping (URL?) -> Void
    ) {
        if let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
            let data = bitmap.representation(using: .png, properties: [:])
        {
            try? data.write(to: fileURL)
        }
        close()
        onFinish(fileURL)
    }

    private func close() {
        window?.orderOut(nil)
        window = nil
    }
}
