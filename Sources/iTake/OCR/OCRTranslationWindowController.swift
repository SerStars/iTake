import AppKit
import SwiftUI

@MainActor
final class OCRTranslationWindowController {
    static let shared = OCRTranslationWindowController()

    private var window: NSWindow?

    private init() {}

    func show(sourceText: String) {
        window?.orderOut(nil)
        window = nil

        let view = OCRTranslationView(
            sourceText: sourceText,
            onDone: { [weak self] in self?.close() }
        )
        let hosting = NSHostingController(rootView: view)
        let newWindow = NSWindow(contentViewController: hosting)
        newWindow.styleMask = [.titled, .closable]
        newWindow.title = "Translate"
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        window = newWindow

        NSApp.activate(ignoringOtherApps: true)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.orderFrontRegardless()
    }

    private func close() {
        window?.orderOut(nil)
        window = nil
    }
}
