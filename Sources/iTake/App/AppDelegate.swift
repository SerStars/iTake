import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        _ = ScreenCaptureService.ensurePermission()
    }

    /// Fired when a .itup file triggered in Finder.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.pathExtension.lowercased() == "itup" {
            UploaderFileActions.importFile(at: url, promptConfirmation: true)
        }
    }
}
