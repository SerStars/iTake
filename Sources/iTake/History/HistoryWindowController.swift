import AppKit
import SwiftUI

@MainActor
enum HistoryWindowController {
    private static var window: NSWindow?

    static func show() {
        NSApp.activate(ignoringOtherApps: true)

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: HistoryWindowView())
        let newWindow = NSWindow(contentViewController: hosting)
        newWindow.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        newWindow.title = "Recent Captures"
        newWindow.isReleasedWhenClosed = false
        newWindow.setContentSize(NSSize(width: 520, height: 420))
        newWindow.center()
        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
    }
}
