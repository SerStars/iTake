import AppKit
import SwiftUI

@MainActor
enum AboutPanelController {
    private static var window: NSWindow?

    static func show() {
        NSApp.activate(ignoringOtherApps: true)

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: AboutView())
        let panel = NSWindow(contentViewController: hosting)
        panel.styleMask = [.titled, .closable]
        panel.title = "About iTake"
        panel.isReleasedWhenClosed = false
        panel.center()
        window = panel
        panel.makeKeyAndOrderFront(nil)
    }
}
