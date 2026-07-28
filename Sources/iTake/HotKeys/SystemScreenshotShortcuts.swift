import Foundation

/// Disables/re-enables macOS's own built-in screenshot keyboard shortcuts so iTake's Cmd+Shift+3/4/5
/// can take over without the OS intercepting them first.
/// Symbolic hotkey IDs:
///   28  = Cmd+Shift+3       save full-screen screenshot to file
///   29  = Cmd+Ctrl+Shift+3  copy full-screen screenshot to clipboard
///   30  = Cmd+Shift+4       save selection screenshot to file
///   31  = Cmd+Ctrl+Shift+4  copy selection screenshot to clipboard
///   184 = Cmd+Shift+5       open the screenshot/recording options panel

enum SystemScreenshotShortcuts {
    private static let relevantIDs = [28, 29, 30, 31, 184]
    private nonisolated(unsafe) static let domain = "com.apple.symbolichotkeys" as CFString
    private nonisolated(unsafe) static let key = "AppleSymbolicHotKeys" as CFString

    static func setEnabled(_ enabled: Bool) {
        var hotKeys = (CFPreferencesCopyAppValue(key, domain) as? [String: Any]) ?? [:]

        for id in relevantIDs {
            var entry = (hotKeys[String(id)] as? [String: Any]) ?? [:]
            entry["enabled"] = enabled
            hotKeys[String(id)] = entry
        }

        CFPreferencesSetAppValue(key, hotKeys as CFDictionary, domain)
        CFPreferencesAppSynchronize(domain)
    }

    /// Restarting SystemUIServer makes the change take effect immediately for most people;
    /// without it, macOS sometimes only picks it up after the next login. All menu bar icons
    /// blink out and back during this, which is expected.
    static func restartSystemUIServer() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["SystemUIServer"]
        try? process.run()
    }
}
