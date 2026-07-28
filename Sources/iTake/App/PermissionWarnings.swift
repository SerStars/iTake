import AppKit

@MainActor
enum PermissionWarnings {
    static func showScreenRecordingDenied() {
        StatusOverlayController.shared.show(
            title: "Screen Recording Access Needed",
            subtitle: "Click to open System Settings, then try again.",
            systemImage: "exclamationmark.triangle.fill",
            autoDismissDelay: nil,
            onTap: { openScreenRecordingSettings() }
        )
    }

    static func showKeychainWriteFailed() {
        StatusOverlayController.shared.show(
            title: "Couldn't Save to Keychain",
            subtitle: "This uploader's header values may not have been saved.",
            systemImage: "exclamationmark.triangle.fill",
            autoDismissDelay: nil
        )
    }

    static func openScreenRecordingSettings() {
        guard
            let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            )
        else { return }
        NSWorkspace.shared.open(url)
    }
}
